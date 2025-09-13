shader_type spatial;
render_mode blend_mix, cull_back, specular_disabled;

group_uniforms parallax;
uniform sampler2D texture_emission : source_color, hint_default_black, filter_nearest, repeat_enable;
uniform sampler2D emission_color : source_color, hint_default_black, filter_nearest;
uniform vec4 color : source_color = vec4(0.0);
uniform float depth_scale = 0.1;
uniform bool discard_boundaries = false;
uniform float emission_energy;
uniform vec2 uv1_scale = vec2(1.0,1.0);
uniform vec2 uv1_offset = vec2(0.0,0.0);
const float min_layers = 8.0;
const float max_layers = 128.0;
#define COLOR_TO_FLOAT(color) (color.r + color.g + color.b)/3.0;

group_uniforms refraction;
uniform bool refraction_enable = true;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b : hint_normal;
uniform float nm_strength : hint_range(0.0,1.0) = 0.5;
uniform float refraction_index : hint_range(0.0,8.0,0.001) = 0.5;
uniform float ice_transparency : hint_range(0.0,1.0,0.01) = 0.0;
uniform vec3 in_vec;
uniform vec3 out_vec;
varying vec3 world_pos;

group_uniforms misc;
uniform float alpha : hint_range(0.0,1.0,0.01) = 0.5;



float flip_float(float val)
{
	return -(val-1.0);
}

vec3 refraction(vec3 view, vec3 normal, vec3 ov, float index)
{

	return ov;
}

vec2 get_parallax_uvs(vec2 uv, vec3 view_dir, sampler2D tex)
{
	vec2 vec_p = view_dir.xy / view_dir.z * -depth_scale;

	float num_layers = mix(min_layers, max_layers, max(dot(vec3(0.0,0.0,1.0), view_dir), 0.0));
	float shift_amt = 1.0 / num_layers;
	vec2 delta_tex_coords = vec_p / num_layers;
	vec2 cur_tex_coords = uv;
	float cur_layer_depth = 0.0;
	vec4 colorVar = texture(tex,cur_tex_coords);
	float colorVarFloat = COLOR_TO_FLOAT(colorVar);
	float cur_depth = flip_float(colorVarFloat);
	while(cur_layer_depth < cur_depth) {
		cur_tex_coords -= delta_tex_coords;
		vec4 depthVar = texture(tex, cur_tex_coords);
		float depthVarFloat = COLOR_TO_FLOAT(depthVar);
		cur_depth = flip_float(depthVarFloat);
		cur_layer_depth += shift_amt;
	}
	vec2 prev_tex_coords = cur_tex_coords + delta_tex_coords;
	float after_depth = cur_depth - cur_layer_depth;
	vec4 beforeVar = texture(tex, prev_tex_coords);
	float beforeVarFloat = COLOR_TO_FLOAT(beforeVar);
	float before_depth = flip_float(beforeVarFloat) - cur_layer_depth + shift_amt;
	float weight = after_depth / (after_depth - before_depth);
	vec2 final_tex_coords = prev_tex_coords * weight + cur_tex_coords * (1.0-weight);

	return final_tex_coords;
}


varying mat4 model;
varying mat3 TBN;
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	model = transpose(inverse(MODELVIEW_MATRIX));
	//Calculates TBN, the Tangent, Binormal, Normal
	TBN = mat3(
		-(model*vec4(TANGENT,0.0)).xyz,
		(model * vec4(BINORMAL,0.0)).xyz,
		(model * vec4(NORMAL, 0.0)).xyz
	);
	world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;

}


varying vec3 view_dir;
void fragment() {
	view_dir = normalize(normalize(-VERTEX) * TBN);
	vec2 base_uv = UV;

	vec2 parallax_uv = get_parallax_uvs(base_uv, view_dir, texture_emission);
	if (discard_boundaries)
	{
		if(parallax_uv.x > 1.0 || parallax_uv.x < 0.0 || parallax_uv.y > 1.0 || parallax_uv.y < 0.0)
		{
			discard;
		}
	}


	vec3 emission_tex = texture(texture_emission, parallax_uv).rgb;
	float emission_tex_float = COLOR_TO_FLOAT(emission_tex);
	vec3 color_tex = texture(emission_color, vec2(emission_tex_float, 0.0)).rgb;
	vec3 final_tex = emission_tex * color_tex * emission_energy;
	vec3 final_color;
	if(refraction_enable == true)
	{
		vec3 normalmap = texture(normalmap_a, base_uv).rgb * nm_strength;
		normalmap+= texture(normalmap_b, base_uv).rgb * nm_strength;
		vec3 ref_normalmap = normalmap * 2.0 - nm_strength;
		vec3 ref_normal = mix(NORMAL, TANGENT * ref_normalmap + BINORMAL * ref_normalmap + NORMAL * ref_normalmap, 1.0);
		vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_index;

		vec3 refraction_texture = textureLod(screen_texture, ref_ofs, ROUGHNESS * 2.0).rgb;
		final_color = final_tex * refraction_texture;
	}
	else
	{
		final_color = final_tex;
	}
	//vec3 result = refraction(VIEW, NORMAL, out_vec, refraction_index);




	ALBEDO = final_color * color.rgb;
	ALPHA = alpha;
}
