extends CharacterBody3D

class_name PlayerCon


# movement variables
const SPEED_DEFAULT = 5.0
const SPEED_CROUCHING = 3.0
const SPEED_SPRINTING = 7.0
@export_range(5,10,0.1) var crouch_speed : float = 7.0
@export var _speed : float

const JUMP_VELOCITY = 6.0
var jumpCounter : int = 0

const SENSITIVITY = 0.0008

@export var toggle_sprint_mode : bool = true
@export var toggle_crouch_mode : bool = true
@export var _is_crouching : bool = false
@export var _is_sprinting : bool = false
var slideSpeedMult : float = 2.0
var slideSpeedVal : float = 1.0
# Physics Variables
var gravity = 9.8
var gravMult = 1.40


# Object variables
@onready var head = $Head
@onready var camera = $"Head/FPS Camera"
@onready var animPlayer = $AnimationPlayer
@onready var crouch_shapecast : Node3D = $ShapeCast3D

# Weapon obj variables
#============================================================================
# Sword variables
var swingNum : int = 1;
var canSwing : bool = true;
var queueSwing : bool = false;
@onready var spell_sword: Node3D = $"Head/FPS Camera/Weapons/SpellSword"
@onready var player_UI : Control = $"Player UI"
signal on_spell_cast(slot: int)

@export var spellWaiting : bool = false	: set = set_spellWaiting

# Reference for movement system update: https://github.com/EricXu1728/Godot4SourceEngineMovement and https://www.youtube.com/watch?v=v3zT3Z5apaM
#		Also: https://github.com/EricXu1728/Godot4SourceEngineMovement/blob/main/Scripts/playerMovementScripts/Crouched.gd
#	And Lastly, the Quake 3 C source code: https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L324

# Adrianb write up on bunnyhopping: https://adrianb.io/2015/02/14/bunnyhop.html


var pp = true;
@onready var ppNode = $"Head/FPS Camera/Toon Effect"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SettingsSingleton.global_settings.on_camera_fov_updated.connect(update_camera_fov)
	update_camera_fov(SettingsSingleton.global_settings.get_camera_fov())
	crouch_shapecast.add_exception($".")			#adds the player to the crouch shapecast as an ignore, so that it doesnt interfere with crouching
	_speed = SPEED_DEFAULT							#sets the movement speed to the default speed value


func set_spellWaiting(val : bool)->void:
	spellWaiting = val

func update_camera_fov(fov:int) -> void:
	camera.fov = fov

func _input(event):
	if event.is_action_pressed("RMB"):
		player_UI.spells_open = true
	if event.is_action_released("RMB"):
		player_UI.spells_open = false
	
	if spellWaiting == false:
		if event.is_action_pressed("Num1") && player_UI.spells_open == true:
			#Cast Spell 1
			on_spell_cast.emit(1)
		if event.is_action_pressed("Num2") && player_UI.spells_open == true:
			#Cast Spell 2
			on_spell_cast.emit(2)
		if event.is_action_pressed("Num3") && player_UI.spells_open == true:
			#Cast Spell 3
			on_spell_cast.emit(3)
		if event.is_action_pressed("Num4") && player_UI.spells_open == true:
			#Cast Spell 4
			on_spell_cast.emit(4)
	
	
	if spellWaiting == false:
		if event.is_action_pressed("Click") && canSwing == true:
			swingSword(swingNum)
		elif event.is_action_pressed("Click") && canSwing == false:
			queueSwing = true
	elif spellWaiting == true:
		if event.is_action_pressed("Click"):
			spell_sword.resolve_spell()
	
	# Crouching control handling
	if event.is_action_pressed("Crouch"):
		toggle_crouch()
	if event.is_action_pressed("Crouch") and _is_crouching == false and is_on_floor() and toggle_crouch_mode == false:		#Hold to crouch functionality
		crouching(true)
	if event.is_action_released("Crouch") and toggle_crouch_mode == false:		# un-crouches when crouch is released, when in "crouch hold" mode
		if crouch_shapecast.is_colliding() == false:
			crouching(false)
		elif crouch_shapecast.is_colliding() == true:
			uncrouch_check()
	
	# Springint control Handling
	if event.is_action_pressed("Sprint"):
		toggle_sprint()
	if event.is_action_pressed("Sprint") and _is_sprinting == false and is_on_floor() and toggle_sprint_mode == false:
		sprinting(true)
	if event.is_action_released("Sprint") and toggle_sprint_mode == false:
		sprinting(false)
		

	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)			#Rotates *around* the y axis, relative to the x position changed on the mouse
		camera.rotate_x(-event.relative.y * SENSITIVITY)		#Rotates *around* the x axis, relative to the y position changed on the mouse
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))	# clamps player camera vertical rotation to +-75deg vertical

func _physics_process(delta):
	# Add the gravity.
	
	if is_on_floor():			# if on the ground, reset the double jump counter
		jumpCounter = 0
		#print("On Floor")
	
	if not is_on_floor():
		velocity.y -= (gravity * gravMult) * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or jumpCounter <= 1):
		velocity.y = JUMP_VELOCITY
		jumpCounter += 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Strafe_Left", "Strafe_Right", "Walk_Forward", "Walk_Backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _speed	* slideSpeedVal
		velocity.z = direction.z * _speed	* slideSpeedVal
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	
	if velocity.x == 0.0 && velocity.z == 0.0 && _is_sprinting == true:		#If the player stops moving while sprinting, it resets their speed to default
		sprinting(false)


# OPTIONALLY -- Disable jumping when crouched, until you implement crouch sliding.
#Also return to youtube tutorial to add "hold crouch" option.

func toggle_crouch():
	if _is_crouching == true && crouch_shapecast.is_colliding() == false:
		crouching(false)
	elif _is_crouching == false:
		crouching(true)

func uncrouch_check():								# keeps checking to see if theres something overhead, and uncrouches automatically when the area is clear
	if crouch_shapecast.is_colliding() == false:
		crouching(false)
	if crouch_shapecast.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()

func crouching(state : bool):
	match state:
		true:
			animPlayer.play("Crouch",-1,crouch_speed)
			if _is_sprinting == true:
				slideSpeedMult = lerpf(slideSpeedMult, 1.0, 0.1)			#Speed increase when sliding
			else:
				set_movement_speed("crouching")
			
		false:
			animPlayer.play("Crouch", -1, -crouch_speed, true)
			set_movement_speed("default")

func toggle_sprint():
	if _is_sprinting == true && _is_crouching == false:
		sprinting(false)
	elif _is_sprinting == false && _is_crouching == false:
		sprinting(true)

func sprinting(state : bool):
	match state:
		true:
			set_movement_speed("sprinting")
			_is_sprinting = true
		false:
			set_movement_speed("default")
			_is_sprinting = false


func set_movement_speed(state : String):
	match state:
		"default":
			_speed = SPEED_DEFAULT
		"crouching":
			_speed = SPEED_CROUCHING
		"sprinting":
			_speed = SPEED_SPRINTING


func swingSword(num : int) -> void:
	if(num >= 1 && num <= 3):
		if num == 1:
			spell_sword.sword_hitbox.monitoring = true
			animPlayer.play("sword_swing1")
		if num == 2:
			spell_sword.sword_hitbox.monitoring = true
			animPlayer.play("sword_swing2")
		if num == 3:
			spell_sword.sword_hitbox.monitoring = true
			animPlayer.play("sword_swing3")
		
		canSwing = false

func returnToIdle(num: int):
	print("Timer Started")
	await get_tree().create_timer(0.3).timeout
	print("Timer Ended")
	if (queueSwing == true):
		if (num < 3):
			swingNum += 1
		if (num >= 3):
			swingNum = 1
		return true
	else:
		return false

func _on_animation_player_animation_started(anim_name):
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "sword_swing1" || anim_name == "sword_swing2" || anim_name == "sword_swing3":
		spell_sword.sword_hitbox.monitoring = false
		print(anim_name + " | Damage = " + str(10 * (swingNum) ))
		if(await returnToIdle(swingNum) == true):
			queueSwing = false
			print("queue == true")
			swingSword(swingNum)
		else:
			swingNum = 1
			animPlayer.play("sword_idle")
			canSwing = true
		
