shader_type spatial;

render_mode unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float zNear = 0.00005;
uniform float zFar = 100;


uniform vec3 outline_color : source_color = vec3(0.0,0.0,0.0);
uniform float outline_thickness = 1.5;

float depth(sampler2D depth_texture, vec2 screen_uv, mat4 inv_proj_mat)
{
	float depth_raw = texture(depth_texture, screen_uv)[0];
	vec4 ndc = vec4(screen_uv * 2.0 - 1.0, depth_raw,1.0);
	vec4 view_space = inv_proj_mat * ndc;
	view_space.z /= view_space.w;
	float linear_depth = view_space.z;
	float scaled_depth = (zFar-zNear)/(zNear + linear_depth * (zNear-zFar));
	return scaled_depth;
}

void vertex() {
		POSITION = vec4(VERTEX.xy,1.0,1.0);
}

void fragment() {
	vec2 offset = outline_thickness/VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;

	//float depth = depth(DEPTH_TEXTURE, uv, INV_PROJECTION_MATRIX);

	vec3 pixel_color = texture(SCREEN_TEXTURE,uv).rgb;
	float depth = texture(DEPTH_TEXTURE, uv).r;
	float  linear_depth = 1.0 / (depth * INV_PROJECTION_MATRIX[2].w + INV_PROJECTION_MATRIX[3].w) + VERTEX.z;
	linear_depth = clamp(linear_depth / 3.0, 0, 1);
	ALBEDO = vec3(linear_depth);
	//ALBEDO = pixel_color;

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
