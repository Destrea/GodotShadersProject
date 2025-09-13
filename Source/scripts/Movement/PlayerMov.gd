extends CharacterBody3D

# movement variables
const SPEED_DEFAULT = 5.0
const SPEED_CROUCHING = 3.0
const SPEED_SPRINTING = 7.0
@export_range(5,10,0.1) var crouch_speed : float = 7.0
@export var _speed : float

const JUMP_VELOCITY = 6.0
var jumpCounter : int = 0

const SENSITIVITY = 0.0008


@export var toggle_crouch_mode : bool = true
@export var toggle_sprint_mode : bool = true
@export var _is_crouching : bool = false
@export var _is_sprinting : bool = false
var slideSpeedMult : float = 2.0
var slideSpeedVal : float = 1.0
# Physics Variables
var gravity = 9.8
var gravMult = 1.40

# Head Bob Variables

# Object variables
@onready var head = $Head
@onready var camera = $"Head/FPS Camera"
@onready var animPlayer = $AnimationPlayer
@onready var crouch_shapecast : Node3D = $ShapeCast3D

# Reference for movement system update: https://github.com/EricXu1728/Godot4SourceEngineMovement and https://www.youtube.com/watch?v=v3zT3Z5apaM
#		Also: https://github.com/EricXu1728/Godot4SourceEngineMovement/blob/main/Scripts/playerMovementScripts/Crouched.gd
#	And Lastly, the Quake 3 C source code: https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/pmove.c#L324

# Adrianb write up on bunnyhopping: https://adrianb.io/2015/02/14/bunnyhop.html

#Definitely re-write this to utilize a seperate "state machine" format, and individual scripts for each movement type


#New Variables for movement update

# Each value is set dependant on what feels good
class pMoveVars:
	var gravity : float	= 9.8
	var stopspeed : float = 1.0
	var maxspeed : float = 3.2
	var accelerate : float = 1.0
	var airaccelerate : float = 0.7
	var friction : float = 8.0

var moveVars = pMoveVars.new()
var MAX_AIR_SPEED : float = moveVars.airaccelerate * 3
var MAX_SPEED : float	= moveVars.maxspeed
var MAX_ACCEL : float	= moveVars.accelerate	* 3
var current_speed : float
var add_speed : float
var sub_speed : float			# Friction value applied to the speed
@export var input_dir : Vector2
@export var direction : Vector3

@export var grounded : bool
@export var wishvel : Vector3

#Friction Funtion
func add_friction(vel : Vector3, frame_time : float):
	prints("vel.x: ", vel.x, "vel.y: ", vel.y, "vel.z:",vel.z)
	var newspeed : float = 0.0
	var drop: float = 0.0
	var control: float = 0.0
	
	current_speed = 1 / sqrt((vel.x * vel.x) + (vel.y * vel.y) + (vel.z * vel.z))
	print("Current_speed = ", current_speed)
	#Add code here to increase edge friction ------------------------
	
	#Applying ground friction
	if is_on_floor() == true:
		control = moveVars.stopspeed if current_speed < moveVars.stopspeed else current_speed
		drop += control * moveVars.friction * frame_time
	
	newspeed = current_speed - drop
	if newspeed < 0:
		newspeed = 0
	newspeed /= current_speed;			#Scaling down newspeed, so that we can multiply it as a "Modifier" to the current values of vel
										# which still include the "current_speed" value. If we didnt scale down, we'd effectively be doubling the speed
	vel.x = vel.x * newspeed
	#vel.y = vel.y * newspeed
	vel.z = vel.z * newspeed
	return vel

#Acceleration Function


#Ground Velocity Function
func update_vel_ground(wishdir: Vector3, vel: Vector3, frame_time: float) -> Vector3:
	prints("Before: velground: vel.x:", vel.x, " vel.y:",vel.y, " vel.z", vel.z)
	vel = add_friction(vel, frame_time)
	prints("After: velground: vel.x:", vel.x, " vel.y:",vel.y, " vel.z", vel.z)
	current_speed = vel.dot(wishdir)
	add_speed = clamp(MAX_SPEED - current_speed, 0, MAX_ACCEL * frame_time)
	prints("Add_speed: ", add_speed)
	return (vel + add_speed * wishdir)

#Air Velocity Function
func update_vel_air(wishdir: Vector3, vel: Vector3, frame_time: float) -> Vector3:
	current_speed = vel.dot(wishdir)
	add_speed = clamp(MAX_AIR_SPEED - current_speed, 0, MAX_ACCEL * frame_time)
	
	return (vel + add_speed * wishdir)

#General Movement


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	crouch_shapecast.add_exception($".")			#adds the player to the crouch shapecast as an ignore, so that it doesnt interfere with crouching
	_speed = SPEED_DEFAULT							#sets the movement speed to the default speed value

func _input(event):
	# Random things here
	#if event.is_action_pressed("Esc"):
	#	get_tree().quit()
	
	# makes mouse visible
	if event.is_action_pressed("Esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Re-Captures mouse when clicked
	if event.is_action_pressed("Click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
		
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
	#Updates player velocity every tick
	#vel = velocity
	
	grounded = is_on_floor()
	
	# Add the gravity.
	if is_on_floor():			# if on the ground, reset the double jump counter
		jumpCounter = 0
	
	#if not is_on_floor():
		#velocity.y -= (moveVars.gravity * gravMult) * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or jumpCounter <= 1):
		velocity.y = JUMP_VELOCITY
		jumpCounter += 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("Strafe_Left", "Strafe_Right", "Walk_Forward", "Walk_Backward")
	direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()			#This is wishdir, just named differently
	if direction:
		#if is_on_floor() == true:
			#print("IsOnFloor")
			wishvel = update_vel_ground(direction, wishvel, delta)
			velocity.x = wishvel.x
			velocity.z = wishvel.z
		#elif is_on_floor() == false:
		#	pass
			#print("NotOnFloot")
			#wishvel = update_vel_air(direction, velocity, delta)
			#velocity.x = direction.x * wishvel.x
			#velocity.z = direction.z * wishvel.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	
	#if velocity.x == 0.0 && velocity.z == 0.0 && _is_sprinting == true:		#If the player stops moving while sprinting, it resets their speed to default
		#sprinting(false)


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

func _on_animation_player_animation_started(anim_name):
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching
