shader_type spatial;
render_mode blend_mix, cull_front, unshaded;


uniform float size : hint_range(1.0,1.5) = 1.05;
uniform vec4 color : source_color = vec4(0.0,0.0,0.0,1.0);

void vertex() {
	VERTEX *= size;
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
