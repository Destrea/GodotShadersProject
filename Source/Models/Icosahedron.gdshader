shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 metal_color : source_color;
uniform float shine = 2.0;
uniform float roughness = 0.5;

uniform float time_scale : hint_range(0.0, 1.0, 0.1) = 0.1;

uniform float x : hint_range(0.0,360.0,0.1) = 0.0;
uniform float y : hint_range(0.0,360.0,0.1) = 0.0;
uniform float z;

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


// Called for every pixel the material is visible on.
void vertex() {


	float roty =  sin(time_scale * TIME);
	mat3 rotation_matrix = rotateX(x) * rotateY(roty) * rotateZ(z);
	//Creates new positional data in the form of a mat3, using the x, y and z positions formed using the rotate functions above, and passsing rotx,roty, and rotz into each for "theta"
	vec3 rotated_vertex = rotation_matrix * VERTEX;
	vec3 rotated_normals = rotation_matrix * NORMAL;

	// Called for every vertex the material is visible on.
	VERTEX = rotated_vertex;
	NORMAL = rotated_normals;
}

void fragment() {

	//Add a noise texture of some kind to add "sparkle" and "roughness" patches to the obj

	SPECULAR = 0.5;
	METALLIC = shine;
	ROUGHNESS = roughness;
	ALBEDO = metal_color.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
