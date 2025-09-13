shader_type spatial;

uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D objTex : source_color;


uniform vec4 _speclar_color : source_color = vec4(0.9,0.9,0.9,1.0);
uniform float _glossiness  = 32;

uniform float _rim_size : hint_range(0,1) = 0.771;
uniform vec4 _rim_color : source_color = vec4(1.0);
uniform float _rim_smoothness : hint_range(0.0, 0.5) = 0.01;
uniform float _rim_threshold : hint_range(0.0,1.0) = 0.1;

uniform bool rimEnable = true;
uniform bool specularEnable = true;

void vertex() {

}


void fragment() {
	ALBEDO = color.rgb;
	vec4 texture_color = texture(objTex, UV);
	ALBEDO = texture_color.rgb * color.rgb;
}

void light() {
	vec3 light = normalize(LIGHT);
	vec3 normal = normalize(NORMAL);
	vec3 ambientLight = LIGHT_COLOR;
	float NdotL = dot(NORMAL, light) * ATTENUATION;
	//NdotL = smoothstep(shadow-shadow_width, shadow+shadow_width,NdotL);

	float lightIntensity = smoothstep(0.0,0.01,NdotL);
	vec3 view = normalize(VIEW);

	vec3 halfVector = normalize(light + VIEW);
	float NdotH = dot(normal, halfVector);
	float specular_intensity = pow(NdotH * lightIntensity, _glossiness * _glossiness);
	float smoothed_spec_intensity = smoothstep(0.005,0.01,specular_intensity);
	vec4 specular = smoothed_spec_intensity * _speclar_color;

	float rimDot = 1.0 - dot(view, normal);
	float rim_int = rimDot * pow(NdotL, _rim_threshold);
	float rimIntensity = smoothstep(_rim_size - 0.01, _rim_size + 0.01, rim_int);
	vec4 rim = rimIntensity * _rim_color;

	if(specularEnable == true){
		SPECULAR_LIGHT += specular.rgb;
	}
	if(rimEnable == true)
	{
		SPECULAR_LIGHT += rim.rgb;
	}
	DIFFUSE_LIGHT += ALBEDO * (lightIntensity) * ambientLight / PI;

}