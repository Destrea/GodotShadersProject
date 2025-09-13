shader_type spatial;
render_mode cull_disabled, blend_add, unshaded;

//Time Scale
uniform float time_scale = 1.0;

//Spin motion
uniform float spin = 0.0;

//Brightness variables
uniform float flame_brightness = 0.6;
uniform float color_intensity = 0.0;

uniform float horizontal_frequency = 1.0;		//Noise frequency in horiz and vert directions
uniform float vertical_frequency = 1.0;

uniform float size = -0.3;			//Overall size scalar

uniform float core_size = 1.0;		//Size of the inner "core" of the fireball

uniform sampler2D noise_tex;		//Noise Texture

uniform vec4 color1 : source_color = vec4(0.286, 0.22, 0.733, 1.0);  //outer color Band 1
uniform vec4 color2 : source_color = vec4(0.98, 0.38, 0.34, 1.0);	//Outer Color band 2
uniform vec4 color3 : source_color = vec4(0.98, 0.95, 0.53, 1.0);	//Color Band 3float offsety;
uniform vec4 color4 : source_color = vec4(1.0, 1.0, 1.0, 1.0);		// Core of the flame

uniform bool bobMotion = false;
uniform float amplitude : hint_range(0.0,50.0) = 0.4;
uniform float bobSpeed : hint_range(0.0,10.0) = 1.0;
instance uniform float bobOffset : hint_range(0.0,2.0);



void vertex()
{
	//Creates an offsety variable using an amplitude and sin wave to create a "bob" effect on each vertex of the mesh
	float offsety;
	if (bobMotion == true)
	{

		offsety = amplitude * sin(TIME * bobSpeed + bobOffset);
		VERTEX.y += offsety;
	}


}


void fragment() {
	float time = TIME * time_scale;				//Scaling TIME by our time scalar

	float normal_facing = dot(NORMAL,VIEW);		//viewing angle and normal dot product

	float noise_val = texture(noise_tex, vec2(UV.x * horizontal_frequency + spin * (time / 2.0), (UV.y * vertical_frequency) + time)).r;		//Calculating the noise value using the noise texture, spin, time and frequencies
	normal_facing += (noise_val -0.5 + size) * 0.3;		//Adds our noise to the normal val result from earlier

	//Determines diffferent "bands" around the sphere, based on the normal_facing float determined earlier
	float band = normal_facing * 3.0 * core_size;

	vec4 flame_color = vec4(0.0);

	//The further out from the center of the object the band is, i.e. as it get closer to 0, its color and alpha changes
	if (band <= 1.5)
	{
		ALPHA = 0.0;
	}
	else if (band <= 2.0) //The outermost band is a mix between color 1 and 2
	{
		flame_color = mix(color1, color2, -0.01 / (band-2.01));
	}
	else if (band <= 2.5) //The next band inwards is a mix between colors 2 and 3
	{
		flame_color = color2;
		flame_color = mix(color2, color3, -0.01 / (band-2.51));
	}
	else if (band <= 2.9) //The 2nd to last band inwards is a mix between color 3 and 4
	{
		flame_color = color3;
		flame_color = mix(color3, color4, -0.01 / (band-2.91));
	}
	else if (band >= 0.0) //Lastly, if the vale of the band is above 2.9, and still greater than 0, it is treated as the "core" and given the white color of color 4
	{
		flame_color = color4;
	}


	//These are all added together into the final albedo, mixing with the brightness and color intensity variables to create the final product
	ALBEDO = flame_brightness * (vec3(1.0) - (flame_color.rgb * -color_intensity)) * flame_color.rgb;


}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
