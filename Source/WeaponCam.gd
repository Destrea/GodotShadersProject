extends Camera3D

@onready var Main_camera : Node3D = $"../../../FPS Camera"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_transform = Main_camera.global_transform
	fov = Main_camera.fov
