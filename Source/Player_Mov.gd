extends CharacterBody3D

@onready var body = self
@onready var head = $Head

var _rot:Vector2

@export_range(0.1,1.0) var sens = 0.1

#Player variables
@export var friction = 10.0
@export var moveSpeed = 5.0
@export var groundAccel = 7.0
@export var groundDeaccel = 5.0
@export var airAccel = 2.0
@export var jumpSpeed = 4.0
@export var debug = true

var wishDir = Vector3.ZERO
var playerVel = Vector3.ZERO

var wishJump = false
var autoJump = true

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var cam_accel:float = 40


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _unhandled_input(event):
	wish_jump_logic(event)
	setDir()

func _input(event):
	if event is InputEventMouseMotion:
		_rot.y = clamp(_rot.y,-85.0,85.0)
		_rot += -event.relative * sens
		
		body.rotation_degrees = Vector3(0,_rot.x,0)
		head.rotation_degrees = Vector3(_rot.y,0,0)

func _process(delta):
	pass

#Used for calculating wishDir
#IMPORTANT----------------------------------------------
func setDir():
	var moveKeyInput = Vector2.ZERO
	moveKeyInput = Input.get_vector("Strafe_Left","Strafe_Right","Walk_Backward","Walk_Forward")
	wishDir = Vector3(moveKeyInput.x,0,-moveKeyInput.y).rotated(Vector3.UP,body.rotation.y).normalized()

func _physics_process(delta):
	queue_jump()
	
	if is_on_floor():
		ground_move()
	else:
		air_move()
	
	#overrides velocity with playerVel
	velocity = playerVel
	
	move_and_slide()
	
	#Add debug code here:
	if debug:
		get_node("Player UI/CanvasLayer/DEBUG_Label").text = "SPEED\n" + str(velocity.length())
		
	
func apply_friction(enabled:bool):
	if !enabled:
		return
	
	var pVecCopy = playerVel
	var drop = 0
	pVecCopy.y = 0
	body.rotation_degrees = Vector3(0,_rot.x,0)
	var lastSpeed = pVecCopy.length()
	var control:float
	var newSpeed:float
	
	if (is_on_floor()):
		if lastSpeed < groundDeaccel:
			control = groundAccel
		else:
			control = lastSpeed
		
		drop = control * friction * get_physics_process_delta_time()
	
	newSpeed = lastSpeed - drop
	if newSpeed < 0:
		newSpeed = 0
	if lastSpeed > 0:
		newSpeed /= lastSpeed
	
	playerVel.x *= newSpeed
	playerVel.y *= newSpeed
	
func wish_jump_logic(event:InputEvent):
	if event.is_action_pressed("Jump") and !wishJump:
		wishJump = true
	if event.is_action_released("Jump"):
		wishJump = false
		
func queue_jump():
	if autoJump:
		wishJump = Input.is_action_pressed("Jump")

func ground_move():
	apply_friction(true)
	accelerate(wishDir,wishSpeed(),groundAccel)
	
	if wishJump:
		wishJump = false
		playerVel.y = jumpSpeed

func air_move():
	accelerate(wishDir,wishSpeed(),airAccel)
	playerVel.y += -gravity * get_physics_process_delta_time()

func wishSpeed():
	return wishDir.length_squared() * moveSpeed

func accelerate(wd, wishSpeed, accel):
	var current_speed = playerVel.dot(wd)
	var add_speed = wishSpeed - current_speed
	var accelSpeed:float = 0.0
	
	if add_speed <= 0:
		return
		
	accelSpeed = accel * get_physics_process_delta_time() * wishSpeed()
	
	if accelSpeed > accel:
		accelSpeed = add_speed
		
	playerVel.x += accelSpeed * wishDir.x
	playerVel.z += accelSpeed * wishDir.z
