extends Camera3D

@onready var PlayerScript = get_node("/root/World/Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	self.global_transform = PlayerScript.camera.global_transform
