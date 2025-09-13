//This shader implements a version of FXAA (Fast Approximate Anti Aliasing)
//as first described by Nvidia's Timothy Lottes in a 2009 paper linked below:
	//https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf

//This shader doesnt follow the paper's explanations 100%, and instead mixes some newer
//or different tecniques to achieve FXAA. This includes referencing and adapting a write-up
//by Simon Rodriguez linked here: https://blog.simonrodriguez.fr/articles/2016/07/implementing_fxaa.html

//Also note that Godot as an engine already supports FXAA in the rendering settings, but I wanted
//to learn how it would be implemented as a screen-space shader, so no step will be skipped.



shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

//Maximum and minimum luminance thresholds for determining where edges are.
uniform float EDGE_THRESH_MIN = 0.000312;
uniform float EDGE_THRESH_MAX = 1.0;



//Function that uses the "Luma" (L = 0.299 * R + 0.587 * G + 0.114 * B)
//as a weighted sum of the rgb components of the "image" to determine
//luminance values. The "luma" mimics the way our eyes percieve luminance.
float rgb2luma(vec3 rgb)
{
	return sqrt(dot(rgb, vec3(0.299,0.578,0.114)));
}




//If the quality value from our iteration portion is greater than 5, the
//quality scalar return increases, until we reach the 12th iteration.
//This allows us to improve performance by reducing the number of iterations
//and find the ends of an edge faster.
float quality(int val)
{
	if(val <= 5)
	{
		return 1.0;
	}
	else
	{

		switch(val){
			case 6: return 1.5;
			case 7: return 2.0;
			case 8: return 2.0;
			case 9: return 2.0;
			case 10: return 2.0;
			case 11: return 4.0;
			case 12: return 8.0;
		}
	}
	//Fallback "default" return statement
	return 1.0;
}



void fragment() {


	vec2 uv = SCREEN_UV;


	vec3 color_center = texture(SCREEN_TEXTURE, uv).rgb;		//Grabs the color of the current fragment
	float luma_center = rgb2luma(color_center);						//Calculates the Luma at the current fragment

	//Calculates the Luma of the four directional neighbors of the current fragment
	float luma_down = rgb2luma(texture(SCREEN_TEXTURE,uv +vec2(0.0,-1.0)).rgb);
	float luma_up 	= rgb2luma(texture(SCREEN_TEXTURE,uv + vec2(0.0,1.0)).rgb);
	float luma_left = rgb2luma(texture(SCREEN_TEXTURE,uv + vec2(-1.0,0.0)).rgb);
	float luma_right = rgb2luma(texture(SCREEN_TEXTURE,uv + vec2(1.0,0.0)).rgb);

	//Finding the maximum and minimum luma of those four
	float luma_min = min(luma_center,min(min(luma_down,luma_up),min(luma_left,luma_right)));
	float luma_max = max(luma_center,max(max(luma_down,luma_up),max(luma_left,luma_right)));

	float luma_range = luma_max - luma_min;	//Calculate the range between the max and min

	//Determines if the luminance falls within the min and max values
	//for applying Anti-Aliasing. This helps us avoid doing extra work in areas
	//where the resulting changes won't matter.
	if(luma_range < max(EDGE_THRESH_MIN, luma_max * EDGE_THRESH_MAX))
	{
		COLOR = vec4(color_center,1.0);
	}

	//calculate the luma for the four "corner" neighbors of the current fragment
	float luma_DL = rgb2luma(texture(SCREEN_TEXTURE,uv +vec2(-1.0,-1.0)).rgb);
	float luma_UL = rgb2luma(texture(SCREEN_TEXTURE,uv +vec2(-1.0, 1.0)).rgb);
	float luma_DR = rgb2luma(texture(SCREEN_TEXTURE,uv +vec2( 1.0,-1.0)).rgb);
	float luma_UR = rgb2luma(texture(SCREEN_TEXTURE,uv +vec2( 1.0, 1.0)).rgb);

	//combining the down+up, and left+right values for use in computing the gradients
	float luma_DU = luma_down + luma_up;
	float luma_LR = luma_left + luma_right;
	//Same computations for each of the "edges", Left, Down, Right and Up
	float luma_Lcorners = luma_DL + luma_UL;
	float luma_Dcorners = luma_DL + luma_DR;
	float luma_Rcorners = luma_DR + luma_UR;
	float luma_Ucorners = luma_UL + luma_UR;

	//gradient estimations for both the horizontal and vertical axes.
	float edge_hori = abs(-2.0 * luma_left + luma_Lcorners) + abs(-2.0 * luma_center + luma_DU) * 2.0 + abs(-2.0 * luma_right + luma_Rcorners);
	float edge_vert = abs(-2.0 * luma_up + luma_Ucorners) + abs(-2.0 * luma_center + luma_LR) * 2.0 + abs(-2.0 * luma_down + luma_Dcorners);

	bool is_horizontal = (edge_hori >= edge_vert);	//uses the previous two to determine if the edge is horizontal or not

	//selecting the lumas of the texels in the opposite directon of the edge we're working with

	float luma_1 = is_horizontal ? luma_down : luma_left;	//if is_horizontal, then luma_down, else luma_left
	float luma_2 = is_horizontal ? luma_up : luma_right;	//if is_horizontal, then luma_up, else luma_right
	//Gradient computations
	float gradient_1 = luma_1 - luma_center;
	float gradient_2 = luma_2 - luma_center;

	bool is_one_steeper = abs(gradient_1) >= abs(gradient_2);	//Determines if the first gradient is steeper than the second

	float gradient_scaled = 0.225 * max(abs(gradient_1),abs(gradient_2));	//Normalized gradient in the same direction

	float step_length = is_horizontal ? SCREEN_PIXEL_SIZE.y : SCREEN_PIXEL_SIZE.x;	//Calculating "one pixel" step length

	//Averaging the luma in the correct direction (is_one_steeper)
	float luma_average = 0.0;
	if(is_one_steeper)
	{
		step_length = -step_length;
		luma_average = 0.5 * (luma_1 + luma_center);
	}
	else
	{
		luma_average = 0.5 * (luma_2 + luma_center);
	}

	//adjusting the uv by half a "pixel" step in the same direction
	vec2 cur_uv = uv;
	if(is_horizontal)
	{
		cur_uv.y +=step_length * 0.5;
	}
	else
	{
		cur_uv.x += step_length * 0.5;
	}

	//Computing the offset off the current iteration, in the correct direction
	vec2 offset_val = is_horizontal ? vec2(SCREEN_PIXEL_SIZE.x,0.0) : vec2(0.0,SCREEN_PIXEL_SIZE.y);

	//Computing UVs on each side of the edge, using our offset value
	vec2 uv_1 = uv - offset_val;
	vec2 uv_2 = uv + offset_val;

	// Reading the luma values at each end of the UV values we calculated, and computing the range between them
	// and the average luma we calculated earlier.
	float luma_end1 = rgb2luma(texture(SCREEN_TEXTURE,uv_1).rgb);
	float luma_end2 = rgb2luma(texture(SCREEN_TEXTURE,uv_2).rgb);
	luma_end1 -= luma_average;
	luma_end2 -= luma_average;

	// If the luma values at both ends are greater than our local gradient, then we've found an edge.
	bool reached1 = abs(luma_end1) >= gradient_scaled;
	bool reached2 = abs(luma_end2) >= gradient_scaled;
	bool reached_both = reached1 && reached2;

	//If not, then we continue looking for the edge.bool
	if(reached1 == false){
		uv_1 -= offset_val;
	}
	if(reached2 == false){
		uv_2 -= offset_val;
	}

	//Continue iterating until the entirety of an edge is reached, or until the max number of iterations is reached.
	int iterations = 12;
	if( reached_both == false)
	{
		for(int i = 2; i < iterations; i++)
		{
			//Conditional to continue in the first direction
			if(reached1 == false)
			{
				luma_end1 = rgb2luma(texture(SCREEN_TEXTURE,uv_1).rgb);
				luma_end1 = luma_end1 - luma_average;
			}
			//Conditional to continue in the second direction
			if(reached1 == false)
			{
				luma_end1 = rgb2luma(texture(SCREEN_TEXTURE,uv_1).rgb);
				luma_end1 = luma_end1 - luma_average;
			}

			//Once again, if the luma values at both ends are greater than our local gradient, we've found an edge.
			bool reached1 = abs(luma_end1) >= gradient_scaled;
			bool reached2 = abs(luma_end2) >= gradient_scaled;
			bool reached_both = reached1 && reached2;

			//If an end is not reached, we continue exploring, scaling our offset by a quality value from quality()
			if(reached1 == false){
				uv_1 -= offset_val * quality(i);
			}
			if(reached2 == false){
				uv_2 -= offset_val * quality(i);
			}

			//Once we've found both, we break out of this for loop early.
			if(reached_both == true)
			{
				break;
			}

		}
	}

	//Here, we compute the distance we've traveled in both directions, and find which end is the closest.
	//Using this, we estimate the ratio of the distance to the total edge length. Using this we can figure out
	//if the current pixel is near the center of the edge, or close to one of the ends. The closer it is to
	//an end, the larger the offset is that is applied to the UV.

	// Figures out the distance towards each end of the edge.
	float dist1 = is_horizontal ? (uv.x - uv_1.x) : (uv.y - uv_1.y);
	float dist2 = is_horizontal ? (uv_2.x - uv.x) : (uv_2.y - uv.y);

	//Determines which direction is closest and sets the distance
	bool is_dir1 = dist1 < dist2;
	float dist_final = min(dist1,dist2);

	// length of the edge we're working with
	float edge_thickness = (dist1 + dist2);

	// Setting up the UV offset in the end direction that is closest
	float pixel_offset = -dist_final / edge_thickness + 0.5;

	//We also determine if the luma at the ends make sense with the luma at the current pixel
	//to ensure that we didn't step too far past our edge during our iteration.
	bool is_luma_center_smaller = luma_center < luma_average;

	// If the luma at the center is smaller than its neighbor, then the curent local luma average should be a positive number
	// Signaling that the variation is correct
	bool correct_var = ((is_dir1 ? luma_end1 : luma_end2) < 0.0) != is_luma_center_smaller;

	//If the variation is incorrect, we dont offset by anyting.
	float final_offset = correct_var ? pixel_offset : 0.0;

	// Next we can take extra steps to handle subpixel aliasing

	float lumaAverage = (1.0/12.0) * (2.0 * (luma_DU + luma_LR) + luma_Lcorners + luma_Rcorners);

	float subpixeloffset1 = clamp(abs(lumaAverage - luma_center)/luma_range,0.0,1.0);
	float subpixeloffset2 = (-2.0 * subpixeloffset1 + 3.0) * subpixeloffset1 * subpixeloffset1;

	float SUBPIXEL_QUALITY = 0.75;
	float subpixeloffsetFinal = subpixeloffset2 * subpixeloffset2 * SUBPIXEL_QUALITY;

	final_offset = max(final_offset,subpixeloffsetFinal);


	vec2 finalUV = uv;

	if(is_horizontal)
	{
		finalUV.y += final_offset * step_length;
	}
	else
	{
		finalUV.x += final_offset * step_length;
	}

	vec3 finalColor = texture(SCREEN_TEXTURE,finalUV).rgb;

	COLOR.rgb = finalColor;


}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
