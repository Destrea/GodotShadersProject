shader_type spatial;

render_mode cull_disabled, unshaded;
uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : source_color, hint_screen_texture, repeat_disable, filter_nearest;

uniform bool enable_color_limit = true;
uniform int color_levels : hint_range(2, 256) = 32;

uniform bool enable_dithering = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;


vec3 colorQuantize(vec3 color, int levels)
{
	float quantizer = float(levels -1);
	return floor(color * quantizer + 0.5) / quantizer;
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
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;

	vec3 final_color = screen_color;
	float levels = 10.0;
	if(enable_color_limit)
	{
		//final_color = colorQuantize(final_color, color_levels);
		vec4 fragColor = texture(screen_texture, POINT_COORD);
		float greyscale = max(fragColor.r,max(fragColor.g,fragColor.b));

		float lower = floor(greyscale * levels) / levels;
		float lowerDiff = abs(greyscale - lower);

		float upper = ceil(greyscale * levels) / levels;
		float upperDiff = abs(upper - greyscale);

		float level = lowerDiff <= upperDiff ? lower : upper;
		float adjustment = level / greyscale;

		fragColor.rgb * adjustment;
		final_color += fragColor.rgb;
	}

	if(enable_dithering)
	{
		float brightness = dot(final_color, vec3(0.3,0.59,0.11));
		brightness += dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5);
		final_color *= (1.0 + dither_strength * (dither(FRAGCOORD.xy, brightness) -0.5));
	}
	ALBEDO = final_color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
