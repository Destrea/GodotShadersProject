extends CharacterBody3D
class_name PlayerInputs

@export var stats: Resource
var playerCamera : Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	push_warning("You shouldnt be able to see this! (Initializing PlayerInputs.gd)")

#Handles inputs for mouse capture
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		InputMouse(event)
	
	# makes mouse visible
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Re-Captures mouse when clicked
	if event.is_action_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Resets player velocity and restarts current scene
	if event.is_action_pressed("restart"):
		stats.vel = Vector3(0,0,0)
		get_tree().reload_current_scene()

func InputMouse(event):			# Mouse Handling
	pass
