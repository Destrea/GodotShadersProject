shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : source_color, hint_screen_texture, repeat_disable, filter_nearest;

uniform bool enable_color_limit = true;
uniform int color_levels : hint_range(2, 32) = 8;

uniform bool enable_color_palette = true;

float posterize(float val, int levels)
{
	return round(val * float(levels)) / float(levels);
}

vec3 rgb2hsv(vec3 c)
{
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(c.bg,k.wz), vec4(c.gb,k.xy),step(c.b,c.g));
	vec4 q = mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
	
	float d = q.x - min(q.w,q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d/(q.x + e), q.x);
	//hsv.x = hue
	//hsv.y = saturation
	//hsv.z = brightness
}

vec3 hsv2rgb(vec3 c)
{
	vec4 k = vec4(1.0,2.0/3.0,1.0/3.0,3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p- k.xxx, 0.0,1.0), c.y);
	
}

void fragment() {
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 hsv = rgb2hsv(screen_color);

	vec3 final_color = screen_color;

	if(enable_color_limit)
	{
		// Dynamically limits the colors to a grayscale
		final_color = vec3(posterize(final_color.r,color_levels),posterize(final_color.g,color_levels),posterize(final_color.b,color_levels));
		//hsv.z = posterize(hsv.z,color_levels);
		//final_color = hsv2rgb(hsv);
	}

	if (enable_color_palette)
	{
		//Implement color palette here
		//final_color *= frag_hue.z;
		//final_color = hsv2rgb(final_color);
	}
	
	ALBEDO = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
