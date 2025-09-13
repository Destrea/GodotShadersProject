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

#Directional Vectors
var forward : Vector3
var right : Vector3
var up : Vector3

var smove:float = 5.0
var fmove:float = 5.0

var wishspeed: float
var maxspeed: float = 15.0
var currentspeed : float
var stopspeed : float = 1.5




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
	
	pass

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
		
	
func apply_friction():
	var control : float
	var drop : float
	var newspeed : float
	var pVecCopy = playerVel
	
	var speed:float = sqrt(pVecCopy[0] * pVecCopy[0] + pVecCopy[1]*pVecCopy[1] + pVecCopy[2] * pVecCopy[2]) 
	
	if speed < 1:
		pVecCopy[0] = 0
		pVecCopy[1] = 0
		return
	
	#if is_on_floor():
		#This willl be used to add friction near ledges
		
	if is_on_floor():
		control = speed if speed > stopspeed else stopspeed
		drop += control * friction * get_physics_process_delta_time()
		
	newspeed = speed - drop
	if newspeed < 0:
		newspeed = 0
	newspeed /= speed
	
	pVecCopy *= newspeed
	
	playerVel.x = pVecCopy.x
	playerVel.y = pVecCopy.y
	playerVel.z = pVecCopy.z
		
		
		
func wish_jump_logic(event:InputEvent):
	if event.is_action_pressed("Jump") and !wishJump:
		wishJump = true
	if event.is_action_released("Jump"):
		wishJump = false
		
func queue_jump():
	if autoJump:
		wishJump = Input.is_action_pressed("Jump")

func ground_move():
	apply_friction()
	accelerate(wishDir,wishSpeed(),groundAccel)
	
	if wishJump:
		wishJump = false
		playerVel.y = jumpSpeed

func air_move():
	var moveKeyInput = Vector3.ZERO
	var wishVel:Vector3
	forward.z = Input.get_axis("Walk_Backward","Walk_Forward")
	right.x = Input.get_axis("Strafe_Left","Strafe_Right")
	
	forward.y = 0
	forward.x = 0
	right.z = 0
	right.y = 0
	forward.normalized()
	right.normalized()
	
	for i in 2:
		wishVel[i] = forward[i] * fmove + right[i] * smove
	wishVel[2] = 0
	
	wishDir = wishVel
	wishspeed = wishDir.normalize()
	
	if wishspeed > maxspeed:
		var scaleVal = maxspeed/wishspeed
		wishVel *= scaleVal
		wishspeed = maxspeed
	
	if is_on_floor():
		playerVel[2] = 0
		accelerate(wishDir,wishspeed,groundAccel)
		playerVel[2] -= gravity * get_physics_process_delta_time()
		move_and_slide()
	else:
		air_accelerate(wishDir,wishspeed,airAccel)
		

func wishSpeed():
	return wishDir.length_squared() * moveSpeed

func accelerate(wishDir, wishSpeed, accel):
	currentspeed = playerVel.dot(wishDir)
	var add_speed = wishSpeed - currentspeed
	var accelSpeed:float = 0.0
	
	if add_speed <= 0:
		return
	accelSpeed = accel * get_physics_process_delta_time() * wishSpeed()
	
	if accelSpeed > accel:
		accelSpeed = add_speed
	for i in 2:
		playerVel[i] += accelSpeed * wishDir[i]

func air_accelerate(wishDir, wishSpeed,accel):
	if wishspeed > 30:
		wishspeed = 30
	var currentspeed = playerVel.dor(wishDir)
	var add_speed = wishspeed - currentspeed
	if add_speed <= 0:
		return
	var accelSpeed:float = 0.0
	accelSpeed = airAccel * wishspeed * get_physics_process_delta_time()
	
	if accelSpeed > add_speed:
		accelSpeed = add_speed
	
func flyMove():
	pass #PM_FlyMove
	
func groundMove():
	pass #PM_GroundMove
	
#Use the source movement test project to update all this, since it all works and feels really good
	
