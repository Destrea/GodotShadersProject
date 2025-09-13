shader_type spatial;
render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


uniform float zNear = 0.05;
uniform float zFar = 100;

uniform vec3 outline_color : source_color = vec3(0.0,0.0,0.0);
uniform float outline_thickness = 1.5;

uniform float noise_frequency : hint_range(0.1,20.0,0.1)=10.0;
uniform float noise_offset_intensity : hint_range(0.001,0.2,0.001) = 0.002;

//Used for the Sobel filter calculations
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



//properly positions the quad to be in view of the camera always
void vertex()
{
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}

// Uses the depth buffer to retrieve and properly scale the depth texture for use
float depth(sampler2D depth_texture, vec2 screen_uv, mat4 inv_proj_matrix)
{
	float depth_raw = texture(depth_texture, screen_uv)[0];
	vec3 ndc = vec3(screen_uv * 2.0 -1.0, depth_raw);
	vec4 view_space = inv_proj_matrix * vec4(ndc,1.0);
	view_space.xyz /= view_space.w;
	float linear_depth = view_space.z;
	float scaled_depth = (zFar-zNear)/(zNear + linear_depth * (zNear-zFar));
	return scaled_depth;
}

// Computes edge detection using the depth texture and a sobel filter operating on x and y.
float sobel_depth(in vec2 uv, in vec2 offset, mat4 inv_proj_matrix)
{
	//pretty inefficient, but I can optimize it once its working.
	//It effectively checks each pixel in a 3x3 "kernel" and saves the result of each pixel and its neighbors
	//This is the "averaging" portion of the sobel process, using the depth texture as the source image
	float d00 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1,-1), inv_proj_matrix);
	float d01 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1, 0), inv_proj_matrix);
	float d02 = depth(DEPTH_TEXTURE, uv + offset * vec2(-1, 1), inv_proj_matrix);

	float d10 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0,-1), inv_proj_matrix);
	float d11 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0, 0), inv_proj_matrix);
	float d12 = depth(DEPTH_TEXTURE, uv + offset * vec2( 0, 1), inv_proj_matrix);

	float d20 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1,-1), inv_proj_matrix);
	float d21 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1, 0), inv_proj_matrix);
	float d22 = depth(DEPTH_TEXTURE, uv + offset * vec2( 1, 1), inv_proj_matrix);

	//Then we use the Gx and Gy differentiation kernels with the averaging steps above
	// and combine them using sqrt(Gx^2 + Gy^2) to get the gradient magnitude, which
	// is effectively the end result of the sobel operation.

	float xSobelDepth = Gx[0][0] * d00 + Gx[1][0] * d10 + Gx[2][0] * d20 +
						Gx[0][1] * d01 + Gx[1][1] * d11 + Gx[2][1] * d21 +
						Gx[0][2] * d02 + Gx[1][2] * d12 + Gx[2][2] * d22;

	float ySobelDepth = Gy[0][0] * d00 + Gy[1][0] * d10 + Gy[2][0] * d20 +
						Gy[0][1] * d01 + Gy[1][1] * d11 + Gy[2][1] * d21 +
						Gy[0][2] * d02 + Gy[1][2] * d12 + Gy[2][2] * d22;

	return sqrt(pow(xSobelDepth,2.0) + pow(ySobelDepth,2.0));
}

//calculates the relative luminance using the "weighted vector", Which is a shade of green
//that can be used to re-create the way light is percieved by humans.
//In this case we're going to use it for creating our normal map
float luminance(vec3 color)
{
	//Weighted vector for luminance calculations
	const vec3 weight = vec3(0.2125, 0.7154, 0.0721);
	return dot(weight,color);	//Return the dot product of weight and color to recieve back the luminance
}

//Applying the sobel operation to the normal map
float sobel_normal(in vec2 uv, in vec2 offset)
{
	//Once again, could be optimized, but I'm getting it all working first.
	//Does a similar operation to in sobel_depth() creating the "averages", this time using luminance
	float n00 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1,-1)).rgb);
	float n01 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1, 0)).rgb);
	float n02 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2(-1, 1)).rgb);

	float n10 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0,-1)).rgb);
	float n11 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0, 0)).rgb);
	float n12 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 0, 1)).rgb);

	float n20 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1,-1)).rgb);
	float n21 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1, 0)).rgb);
	float n22 = luminance(texture(NORMAL_TEXTURE, uv + offset * vec2( 1, 1)).rgb);

	float xSobelNormal = Gx[0][0] * n00 + Gx[1][0] * n10 + Gx[2][0] * n20 +
						Gx[0][1] * n01 + Gx[1][1] * n11 + Gx[2][1] * n21 +
						Gx[0][2] * n02 + Gx[1][2] * n12 + Gx[2][2] * n22;

	float ySobelNormal = Gy[0][0] * n00 + Gy[1][0] * n10 + Gy[2][0] * n20 +
						Gy[0][1] * n01 + Gy[1][1] * n11 + Gy[2][1] * n21 +
						Gy[0][2] * n02 + Gy[1][2] * n12 + Gy[2][2] * n22;

	return sqrt(pow(xSobelNormal,2.0) + pow(ySobelNormal, 2.0));

}


//Used to generate noise for some squiggly outlines
float hash(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}



void fragment() {
	vec2 offset = outline_thickness/VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;

	//Uses hash for squiggly outline displacement
	//vec2 displ = vec2((hash(FRAGCOORD.xy) * sin(FRAGCOORD.y * wiggle_frequency)),(hash(FRAGCOORD.xy) * cos(FRAGCOORD.x * wiggle_frequency))) * wiggle_amplitude / VIEWPORT_SIZE;

	float depth = depth(DEPTH_TEXTURE, uv, INV_PROJECTION_MATRIX);

	//Ignore cross-hatch shading on background and skybox

	//Grabs the luminance of each pixel color, for use with comparisons to find where shading should be added
	vec3 pixelColor = texture(SCREEN_TEXTURE,uv).rgb;
	float pixelLuma = luminance(pixelColor);
	float modVal = 11.0;



	//edge detection calc using the depth buffer
	float edgeDepth = sobel_depth(uv, offset, INV_PROJECTION_MATRIX);

	//edge detection using the normal buffer
	float edgeNormal = sobel_normal(uv, offset);

	//mix both edge detection results
	float outline = smoothstep(0.0,1.0,25.0 * edgeDepth + edgeNormal);

	//Mix color and edges results
	ALBEDO = mix(pixelColor, outline_color, outline);
}
