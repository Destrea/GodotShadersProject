shader_type spatial;

uniform float height_scale = 0.2;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 tex_position;


//Updating this to be opalescent would be REALLY cool!


float wave(vec2 position){
	position += texture(noise,position/10.0).x * 2.0 - 1.0;
	vec2 wv = 1.0 - abs(sin(position));
	return pow(1.0 - pow(wv.x * wv.y,0.65),4.0);
}

float height(vec2 position, float time) {
	float d = wave((position+ time) * 0.4) * 0.3;
	d += wave((position - time) * 0.3) * 0.3;
	d += wave((position + time) * 0.5) * 0.2;
	d += wave((position - time) * 0.6) * 0.2;
	return d;
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
	VERTEX.y = k;
	NORMAL = normalize(vec3(k-height(pos + vec2(0.1,0.0),TIME),0.1,k-height(pos + vec2(0.0,0.1),TIME)));

}

void fragment() {
	// Called for every pixel the material is visible on.
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	NORMAL_MAP = texture(normalmap,tex_position).xyz;
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01;
	ALBEDO = vec3(0.1,0.3,0.5);
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
