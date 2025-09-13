extends MeshInstance3D

@onready var offset : float = 0.0;
@onready var Trail : MeshInstance3D = $Trail
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	offset = (randi() % 3) + ((randi() % 11) / 10.0);

func setOffset():
	print(offset)
	self.set_instance_shader_parameter("bobOffset", offset)
	Trail.set_instance_shader_parameter("bobOffset", offset)
