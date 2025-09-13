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

uniform vec4 color1 : source_color = vec4(0.286, 0.22, 0.733, 1.0);  // Core of the flame
uniform vec4 color2 : source_color = vec4(0.98, 0.38, 0.34, 1.0);
uniform vec4 color3 : source_color = vec4(0.98, 0.95, 0.53, 1.0);
uniform vec4 color4 : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float height_scale = 0.2;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 tex_position;


//Updating this to be opalescent would be REALLY cool!


float wave(vec2 position){
	position += texture(noise,position/10.0).x * 2.0 - 1.0;
	vec2 wv = 1.0 - (abs(sin(position) ));
	return pow(1.0 - pow(wv.x * wv.y,0.65),4.0);
}

float height(vec2 position, float time) {
	float d = wave((position+ time) * 0.4) * 0.3;
	d += wave((position - time) * 0.3) * 0.3;
	d += wave((position + time) * 0.5) * 0.2;
	d += wave((position - time) * 0.6) * 0.2;
	return d ;
}

void vertex() {
	// Called for every vertex the material is visible on.Now, access the noise texture using the texture() function. texture() takes a texture as the first argument and a vec2 for the position on the texture as the second argument. We use the x and z channels of VERTEX to determine where on the texture to look up. Note that the PlaneMesh coordinates are within the [-1,1] range (for a size of 2), while the texture coordinates are within [0,1], so to normalize we divide by the size of the PlaneMesh by 2.0 and add 0.5. texture() returns a vec4 of the r, g, b, a channels at the position. Since the noise texture is grayscale, all of the values are the same, so we can use any one of the channels as the height. In this case we'll use the r, or x channel.


	//VERTEX.y += cos(VERTEX.x * 4.0) * sin(VERTEX.z * 4.0);

	// xyzw is the same as "rgba" in GLSL, so I'm using the GLSL stuff instead, since it's more universal
	//float height = texture(noise,VERTEX.rb / 2.0 + 0.5).r;
	//tex_position = VERTEX.xz / 2.0 + 5.0;
	//float height = texture(noise, tex_position).x;
	//VERTEX.y += height * height_scale;

	vec2 pos = VERTEX.xz;
	float k = height(pos, TIME);
	VERTEX.y = k * height_scale * 2.0;
	NORMAL = normalize(vec3(k-height(pos + vec2(0.1,0.0),TIME),0.1,k-height(pos + vec2(0.0,0.1),TIME)));

}

void fragment() {
	float time = TIME * time_scale;				//Scaling TIME by our time scalar

	float normal_facing = dot(NORMAL,VIEW);		//viewing angle and normal dot product

	float noise_val = texture(noise_tex, vec2(UV.x * horizontal_frequency + spin * (time / 2.0), (UV.y * vertical_frequency) + time)).r;		//Calculating the noise value using the noise texture, spin, time and frequencies
	normal_facing += (noise_val -0.5 + size) * 0.3;		//Adds our noise to the normal val result from earlier
	float band = normal_facing * 3.0 * core_size;
	vec4 flame_color = vec4(0.0);
	if (band <= 1.5)
	{
		ALPHA = 1.0;
	}
	else if (band <= 2.0)
	{
		flame_color = mix(color1, color2, -0.01 / (band-2.01));
	}
	else if (band <= 2.5)
	{
		flame_color = color2;
		flame_color = mix(color2, color3, -0.01 / (band-2.51));
	}
	else if (band <= 2.9)
	{
		flame_color = color3;
		flame_color = mix(color3, color4, -0.01 / (band-2.91));
	}
	else if (band >= 0.0)
	{
		flame_color = color4;
	}

	ALBEDO = flame_brightness * (vec3(1.0) - (flame_color.rgb * -color_intensity)) * flame_color.rgb;


}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
