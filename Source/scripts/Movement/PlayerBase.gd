extends PlayerInputs
class_name Player

#Node variables
@onready var pl_collider = $"Collision Shape"
@onready var pl_mesh = $"Collision Shape/Capsule Mesh"
@onready var pl_head = $Head
@onready var pl_camera = $"Head/FPS Camera"
@onready var pl_anim = $AnimationPlayer
@onready var pl_headbonk = $ShapeCast3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
