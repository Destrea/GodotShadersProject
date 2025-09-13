shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screenTexture : hint_screen_texture;

const mat2 m = mat2(vec2(0.80, 0.60), vec2(-0.60 ,0.80));

float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) *
            43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    // Four corners in 2D of a tile
    float a = random(uv_index);
    float b = random(uv_index + vec2(1.0, 0.0));
    float c = random(uv_index + vec2(0.0, 1.0));
    float d = random(uv_index + vec2(1.0, 1.0));

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix(a, b, blur.x) +
            (c - a) * blur.y * (1.0 - blur.x) +
            (d - b) * blur.x * blur.y;
}

float fbm(vec2 uv) {
    int octaves = 6;
    float amplitude = 0.5;
    float frequency = 3.0;
	float value = 0.0;

    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(frequency * uv);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

float fbm4(vec2 p)
{
	float f = 0.0;
	f+= 0.5000*noise(p); p=m*p*2.02;
	f+= 0.2500*noise(p); p=m*p*2.03;
	f+= 0.1250*noise(p); p=m*p*2.01;
	f+= 0.0625*noise(p);
	return f/0.9375;
}

vec2 fbm4_2(vec2 p)
{
	return vec2(fbm4(p),fbm4(p+vec2(7.8)));
}

void fragment() {
	vec2 fbmOut = fbm4_2(UV);
	vec4 output = texture(screenTexture, fbmOut);

	COLOR.rgb = vec3(output.xyz);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
