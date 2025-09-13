shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float distortion_strength : hint_range(-2.0, 2.0) = 0.5;
uniform float distortion_radius : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	if (dist < distortion_radius){
		float amount = dist / distortion_radius;
		vec2 distorted_uv = uv * (1.0 + amount * distortion_strength) + vec2(0.5);
	
		if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0){
			
			COLOR = vec4(0.0, 0.0, 0.0, 1.0); // black color
		}
		
		else{
			COLOR = texture(screen_texture, distorted_uv);
		}
	}
	else{
		COLOR = texture(screen_texture, UV);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
