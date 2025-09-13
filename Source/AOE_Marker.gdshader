shader_type spatial;
render_mode unshaded, cull_disabled;


// Utilize this to Improve, so that it just shows a ring, and not a whole bubble
	//https://www.youtube.com/watch?v=SiCNFMhDZ1o

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform vec3 baseColor : source_color = vec3(1,1,1);
uniform float alpha1 = 0.019;
uniform float alpha2 = 1.0;
uniform float threshold = 0.2;
uniform float fresnel_sharpness = 0.00010;

void fragment() {
	float depth = texture(depth_texture,SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 -1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc,1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	float obj_depth = FRAGCOORD.z;
	vec3 obj_ndc = vec3(SCREEN_UV * 2.0-1.0,obj_depth);
	vec4 obj_view = INV_PROJECTION_MATRIX * vec4(obj_ndc,1.0);
	obj_view.xyz /= obj_view.w;
	float linear_obj_depth = -obj_view.z;

	float fresnel = pow(1.0 - dot(VIEW, NORMAL), fresnel_sharpness);

	if(linear_depth - linear_obj_depth < threshold)
	{
		ALBEDO = baseColor;
		//ALPHA = alpha2;
		ALPHA = mix(alpha2,alpha1,0.01);
	}

	else
	{
		ALBEDO = baseColor;
		ALPHA = alpha1 + (0.01 * fresnel);
	}

}
