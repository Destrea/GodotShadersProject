shader_type spatial;
render_mode diffuse_toon, specular_toon;


uniform sampler2D object_texture : source_color;
uniform vec4 color_modifier : source_color;

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


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 texture_color = texture(object_texture, UV);
	float greyscale;
	vec3 hsv = rgb2hsv(texture_color.rgb);
	greyscale = hsv.z;
	ALBEDO = vec3(greyscale * color_modifier.rgb);// * color_modifier.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
