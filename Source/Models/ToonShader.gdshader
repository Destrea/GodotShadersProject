shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : source_color, hint_depth_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : source_color, hint_screen_texture, repeat_disable, filter_nearest;

uniform float zNear = 0.05;
uniform float zFar = 100;

uniform bool enable_outline = false;
uniform vec3 outline_color : source_color = vec3(0.0,0.0,0.0);
uniform float outline_thickness = 10.0;

uniform bool enable_color_limit = true;
uniform int color_levels : hint_range(2, 32) = 8;


//Implement script to automate hex -> rgb conversion?

uniform bool enable_color_palette = true;
uniform vec4 color1  : source_color  = vec4(1.0,0.925,0.839,1.0);			//#bfbfbf - avg = 0.749
uniform vec4 color2  : source_color  = vec4(1.0,0.831,0.639,1.0);			//#71a668 - avg = 0.501
uniform vec4 color3  : source_color  = vec4(1.0,0.667,0.369,1.0);			//#6a86b0 - avg = 0.543
uniform vec4 color4  : source_color  = vec4(0.816,0.506,0.349,1.0);			//#76568f - avg = 0.453
uniform vec4 color5  : source_color  = vec4(0.553,0.412,0.478,1.0);			//#ab5c74 - avg = 0.496
uniform vec4 color6  : source_color  = vec4(0.329,0.306,0.408,1.0);			//#b89d6e - avg = 0.589
uniform vec4 color7  : source_color  = vec4(0.125,0.236,0.337,1.0);			//#4c5b6b - avg = 0.358
uniform vec4 color8  : source_color  = vec4(0.05,0.169,0.271,1.0);			//#2e253d - avg = 0.188

// In order, dark -> light
// 8,7,4,5,2,3,6,1
uniform bool enable_dithering = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

//This shader uses the sobel-feldman operation to create outlines for any object on the screen.
//It utilizes the depth and normal buffers to create the most accurate or complete outlines.

// We do this using two kernels Gx and Gy (1) , which are convolved (adding each element to its local neighbors)
// with the input data (2). First with the depth buffer (3), and then with the normal buffer (4), These results are
// also used with some gaussian blur (5) to reduce the "noise" of the sobel operation. These results are then handled
// in the fragment shader (6), to be output to the player's screen.


// (1)
// Gx and Gy are two "kernels" that contain horizontal (x) and vertical(y) derivative approximations.
const mat3 Gx = mat3(
				vec3(-1,-2,-1),
				vec3(0, 0, 0),
				vec3(1, 2, 1)
);
const mat3 Gy = mat3(
				vec3(-1,0,1),
				vec3(-2,0,2),
				vec3(-1,0,1)
);


float depth(sampler2D depth_texture, vec2 screen_uv, mat4 inv_proj_mat, in vec3 vertex)
{
	float depth_raw = texture(depth_texture, screen_uv)[0];
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth_raw);
	vec4 view_space = inv_proj_mat * vec4(ndc,1.0);
	view_space.z /= view_space.w;
	float linear_depth = view_space.z;



	//float depth = texture(DEPTH_TEXTURE,screen_uv).r;
	//float linear_depth = 1.0 / (depth * inv_proj_mat[2].w + inv_proj_mat[3].w) + vertex.z;
	float scaled_depth = (zFar-zNear)/(zNear + linear_depth * (zNear-zFar));

	return scaled_depth;
}


float sobel_depth(in vec2 uv, in vec2 offset, in vec3 vertex, mat4 inv_proj_mat)
{
	//used for multiplying the results of the depth calculation with
	//the Gx and Gy kernels;
	float xSobDepth = 0.0;
	float ySobDepth = 0.0;

	for (int row = 0; row < 3; row++)
	{
		for (int col = 0; col < 3; col++)
		{
			float depth = depth(DEPTH_TEXTURE, uv + offset * vec2(float(col-1),float(row-1)),inv_proj_mat,vertex);
			xSobDepth += Gx[row][col] * depth;
			ySobDepth += Gy[row][col] * depth;
		}
	}


	return sqrt(pow(xSobDepth,2.0) + pow(ySobDepth,2.0));
}

// Calculates relative luminance for a pixel's color using the "weighted vector"
// which is a shade of green that approximates the way light is percieved by humans.
float luminance(vec3 color)
{
	const vec3 weight = vec3(0.2125, 0.7154, 0.0721);
	return dot(weight,color);
}

float sobel_normal(in vec2 uv, in vec2 offset)
{
	float xSobNormal = 0.0;
	float ySobNormal = 0.0;

	for (int row = 0; row < 3; row++)
	{
		for (int col = 0; col < 3; col++)
		{
			//vec2 uv = SCREEN_UV + vec2(float(col-1),float(row-1)) * SCREEN_PIXEL_SIZE;
			float lumi = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(float(col-1),float(row-1))).rgb);
			xSobNormal += Gx[row][col] * lumi;
			ySobNormal += Gy[row][col] * lumi;
		}
	}


	return sqrt(pow(xSobNormal,2.0) + pow(ySobNormal,2.0));
}

float posterize(float val, int levels)
{
	return round(val * float(levels)) / float(levels);
}


vec3 hex2rgb(vec3 color)
{

	return vec3(0.0);
}



float dither(vec2 position, float brightness)
{
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
	int index = x + y * 4;

	float dithering[16] = float[](
		0.0,0.5,0.125,0.625,
		0.75,0.25,0.875,0.375,
		0.1875,0.6875,0.0625,0.5625,
		0.9375,0.4375,1.0,0.8125
	);
	float threshold = dithering[index];
	return brightness < threshold ? 0.0 : 1.0;
}

void vertex() {
	//Positions the post-processing quad in front of the camera
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 palette[8];
		palette[0] = color1.rgb;
		palette[1] = color2.rgb;
		palette[2] = color3.rgb;
		palette[3] = color4.rgb;
		palette[4] = color5.rgb;
		palette[5] = color6.rgb;
		palette[6] = color7.rgb;
		palette[7] = color8.rgb;

	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	vec3 final_color = screen_color;

	if(enable_color_limit)
	{
		// Posterizes the fragment's color using the limit value set in "color_levels"
		final_color = vec3(posterize(final_color.r,color_levels),posterize(final_color.g,color_levels),posterize(final_color.b,color_levels));
		//hsv.z = posterize(hsv.z,color_levels);
		//final_color = hsv2rgb(hsv);


	}

	if (enable_color_palette)
	{
		vec3 difference = final_color - palette[0];
		float dist = dot(difference,difference);

		float closest_distance = dist;
		vec3 closest_color = palette[0];

		for( int i = 0; i < palette.length(); i++)
		{
			difference = final_color - palette[i];
			dist = dot(difference,difference);

			if(dist<closest_distance)
			{
				closest_distance = dist;
				closest_color = palette[i];
			}
		}
		final_color = closest_color;
	}

	if(enable_dithering)
	{
		float brightness = dot(final_color, vec3(0.3,0.59,0.11));
		brightness += dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5);
		final_color *= (1.0 + dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5));
	}
	//ALBEDO = final_color;
	if(enable_outline)
	{
		vec2 offset = outline_thickness / VIEWPORT_SIZE;
		vec2 uv = SCREEN_UV;

		float depth = depth(DEPTH_TEXTURE, uv, INV_PROJECTION_MATRIX,VERTEX);


		vec3 pixel_color = texture(SCREEN_TEXTURE, uv).rgb;

		float edge_depth = sobel_depth(uv, offset, VERTEX, INV_PROJECTION_MATRIX);

		float edge_normal = sobel_normal(uv, offset);

		float outline = smoothstep(0.0,1.0,10.0 * edge_depth + edge_normal);

		final_color = mix(final_color, outline_color, outline);
	}

	ALBEDO = final_color;

}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
}
