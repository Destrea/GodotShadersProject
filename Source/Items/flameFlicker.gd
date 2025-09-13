extends SpotLight3D


@export var noise : NoiseTexture3D
var time_passed := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	
	var sample_noise = noise.noise.get_noise_1d(time_passed)
	sample_noise = abs(sample_noise)
	light_energy = 5 + (sample_noise * 100) / 2
	pass
