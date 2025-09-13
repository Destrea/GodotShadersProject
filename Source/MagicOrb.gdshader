shader_type spatial;
render_mode blend_mix;

uniform vec4 base_color_shadow : source_color = vec4(0.0,0.0,0.0,1.0);
uniform vec4 base_color_highlight : source_color = vec4(0.40,0.0,0.96,1.0);
uniform float base_color_blend : hint_range(0.1,2.0,0.05) = 1.15;
uniform float color_modulate_freq : hint_range(0.1,10.0,0.1) = 1.0;
varying float blend_scale;


uniform float noise_displacement : hint_range(0.1,1,0.01) = 0.47;
uniform float noise_scale : hint_range(1,20,0.1) = 15.0;
uniform float noise_time_scale : hint_range(0.1,10,0.1) = 0.3;
uniform float pulse_time_scale : hint_range(0.1,10,0.1) = 1.1;


uniform float metallic_scale : hint_range(0.0,20.0,0.1) = 20.0;
uniform float roughness_scale : hint_range(0.0,20.0,0.1) = 1.0;
uniform float emission_intensity : hint_range(0.0, 15.0, 0.1) = 2.4;
uniform float highlight_intensity : hint_range(0.1, 10.0, 0.1) = 1.0;

varying vec3 normal_norm;			//normalized NORMAL
varying vec3 vertex_local;			//local vertex location
varying float vertex_d;				//vertex depth/distance


//rotation test vars
uniform float xx : hint_range(0.0,360.0,0.1) = 0.0;
uniform float y : hint_range(0.0,360.0,0.1) = 0.0;
uniform float z;


// These three functions are for use as part of a "generic 1,2,3 noise" function
vec4 mod289(vec4 x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 perm(vec4 x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}

float noise(vec3 p)
{
	vec3 a = floor(p);
	vec3 d = p - a;
	d = d * d * (3.0 - 2.0 * d);

	vec4 b = a.xxyy + vec4(0.0,1.0,0.0,1.0);
	vec4 k1 = perm(b.xyxy);
	vec4 k2 = perm(k1.xyxy + b.zzww);

	vec4  c = k2 + a.zzzz;
	vec4 k3 = perm(c);
	vec4 k4 = perm(c+1.0);

	vec4 o1 = fract(k3 * (1.0 / 41.0));
	vec4 o2 = fract(k4 * (1.0 / 41.0));

	vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
	vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

	return o4.y * d.y + o4.x * (1.0 - d.y);
}


vec3 wave(float time){

	float w1 = 0.134 * cos(2.874 * time) + 0.536 * sin(3.574 * time);
	float w2 = 0.446 * sin(2.567 * time) + 0.357 * cos(3.367 * time) + 5.746 * time;
	float w3 = 0.364 * cos(2.745 * time) + 0.256 * sin(3.645 * time);
	return vec3(w1,w2,w3);
}


//These three are used in vertex() for rotating the mesh on the three different axes, X, Y and Z respectively
mat3 rotateX(float theta){
	float cosa = cos(theta);
	float sina = sin(theta);
	mat3 rotate_x = mat3(
		vec3(1.0,0.0,0.0),
		vec3(0.0,cosa,-sina),
		vec3(0.0,sina,cosa)
	);
	return rotate_x;
}

mat3 rotateY(float theta){
	float cosa = cos(theta);
	float sina = sin(theta);
	mat3 rotate_y = mat3(
		vec3(cosa,0.0,sina),
		vec3(0.0,1.0,0.0),
		vec3(-sina,0.0,cosa)
	);
	return rotate_y;
}

mat3 rotateZ(float theta){
	float cosa = cos(theta);
	float sina = sin(theta);
	mat3 rotate_z = mat3(
		vec3(cosa,-sina,0.0),
		vec3(sina,cosa,0.0),
		vec3(0.0,0.0,1.0)
	);
	return rotate_z;
}

void vertex() {
	// uses the 1,2,3 noise functions above and the "wave" fuunction to create the distorted "spiky" effect on the sphere
	normal_norm = normalize(NORMAL); //Lol
	VERTEX += noise_displacement * noise(VERTEX * noise_scale + wave(noise_time_scale * TIME)) * normal_norm;

	//"breathing" vertex wave modularity:This utilizes a log function to create a sort of "floor" for the sin wave's changing values, ensuring that the object
	//doesn't reduce in size past its floor.
	VERTEX *= noise_displacement * (0.8 * log(3.16 + sin(pulse_time_scale * TIME)) + 2.0);


	// Determines the distance from the vertex's location to the center of the sphere, for use in the color-changing effect
	// done within the fragment shader.
	vertex_local = VERTEX;
	vertex_d = distance(vertex_local, vec3(0.0));


	//rotation effect moves at changing speeds in all 3 directions, at different times.
	//This is done after the noise effects, so that the noise acts independently, before the rotation modifies the vertex

	float rotx = pow(sin((pulse_time_scale / 4.0) * TIME),2.0);								//formula is sin( (pulse_time_scale / 4) * TIME) ^ 2, raising it to the power of 2 gurantees it is always positive.
	float roty = pow(1.5 * cos((pulse_time_scale / 4.0) * TIME),2.0);						//Similar to the previous, but uses cos, so that its y rotation is orthogonal to the x and z axes. the amplitude of cos is also increased by 1.5, before also being squared
	float rotz = pow(0.75 * sin((pulse_time_scale / 2.0) * TIME),2.0);						// Matches the formula for rotx, but with sin's amplitude being multipled by 0.75, and pulse_time_scale is divided by 2 instead of 4.

	mat3 rotation_matrix = rotateX(rotx) * rotateY(roty) * rotateZ(rotx);					//Creates new positional data in the form of a mat3, using the x, y and z positions formed using the rotate functions above, and passsing rotx,roty, and rotz into each for "theta"
	vec3 rotated_vertex = rotation_matrix * VERTEX;											//The product of this rotation matrix is then used with the vertex and the normal to change the rotation of each vertex, each frame.
	vec3 rotated_normals = rotation_matrix * NORMAL;

	//These modified vertex and normal are then given to the respective buffers for rendering.
	VERTEX = rotated_vertex;
	NORMAL = rotated_normals;


}

void fragment() {
	// Called for every pixel the material is visible on.
	METALLIC = metallic_scale;
	//ROUGHNESS = roughness_scale;
	blend_scale = 0.25 * (pow(sin((pulse_time_scale / 2.0) * TIME),2.0)) + 0.8;
	float base_color_modified = base_color_blend * blend_scale;
	ALBEDO = base_color_shadow.rgb + (base_color_highlight.rgb * smoothstep(base_color_modified - base_color_modified * 0.25, base_color_modified + base_color_modified * 0.25, vertex_d));


	ALBEDO *= pow(vertex_d,highlight_intensity);

	EMISSION = emission_intensity * ALBEDO;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
