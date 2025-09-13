extends Control

@onready var player = $"/root/World/Player"

@onready var debug_label = $"User Interface/DEBUG_Label"
@onready var spells_menu = $"User Interface/Spells Menu"


var spells_open : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var fps = Engine.get_frames_per_second()
	var speed = player._speed
	var crouch = player._is_crouching
	
	debug_label.text = "FPS: " + str(fps) + "\nSpeed: " + str(speed) + "\nCrouch: " + str(crouch)
	#text = ("i_dirx: " + str(i_dirx) + "\ni_diry: " + str(i_diry) + "\n\ndirx: " + str(dirx) + "\ndiry: " + str(diry) + "\ndirz: " + str(dirz))
	spells_menu.set_visible(spells_open)
	
	
