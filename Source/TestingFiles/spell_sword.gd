extends Node3D

@onready var sword_hitbox = $Sword/Hitbox
@onready var Muzzle = $Grimoire/Muzzle
@onready var Aimcast = $Grimoire/Aimcast
@onready var Camcast = $"../../CameraCast"
var damage = 10.0
var time_passed := 0.0

var spellWaiting : String = "" : set = set_spellWaiting		# Use this to store two forms of data, the key being the spell name waiting, such as "fire" or "ice", and the value being true or false, for whether its been cast or not.

var iceWall = load("res://Models/Ice_wall.tscn")
var ice_cd = 10.0 	# 10 second cooldown
var iceLastCast := 0.0
var iceBool = true : set = set_iceBool
var iceInstance;

var Fireball = load("res://Projectiles/fireball.tscn")
var fire_cd = 3.0 	# 3 second cooldown
var fireLastCast := 0.0
var fireBool = true : set = set_fireBool
var instance

var targetingStarted = false : set = set_targetingStarted
@export var targetSphere = false : set = set_targetSphere
var targetObj = load("res://aoe_marker.tscn")
var targetInst

var aoeType : Mesh : set = set_aoeType		# Defaults to "sphere", but can also be "wall"
var sphereMesh : Mesh = load("res://MiscAssets/SphericalAOE.tres")
var wallMesh : Mesh = load("res://MiscAssets/IceWallAOE.tres")
var aoeID

@onready var world = get_node("/root/World")
@onready var PlayerScript = get_node("/root/World/Player")
#@onready var PlayerScript = $"../../../..".get_script()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerScript.on_spell_cast.connect(spell_cast)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_passed += delta
	checkFireCD()
	checkIceCD()
	if spellWaiting != "":
		aoeDisplay()

func checkFireCD():
	if fireBool == false:
		if time_passed >= (fireLastCast + fire_cd):
			set_fireBool(true)
			print("fire Ball ready " + str(time_passed) + " " + str(fireBool))

func checkIceCD():
	if iceBool == false:
		if time_passed >= (iceLastCast + ice_cd):
			set_iceBool(true)
			print("Ice Wall ready " + str(time_passed) + " " + str(iceBool))

func aoeDisplay():
	if targetSphere == true:
		print("aoeDisplay Entered")
		create_aoe(aoeType)

func spell_cast(slot:int) -> void:
	if slot == 1:
		if fireBool == true:
			set_spellWaiting("fire")
			set_aoeType(sphereMesh)
			set_targetSphere(true)
		else:
			print("Fire Ball on Cooldown")
	elif slot == 2:
		if iceBool == true:
			set_spellWaiting("ice")
			set_aoeType(wallMesh)
			set_targetSphere(true)
			print("Set SpellWaiting")
			#ice_wall()
		else:
			print("Ice Wall On Cooldown")
	elif slot == 3:
		set_targetSphere(true)
		print(targetSphere)
	elif slot == 4:
		print("spell_4_signal")

func set_spellWaiting(val:String)->void:
	spellWaiting = val
	if val != "":
		PlayerScript.set_spellWaiting(true)
	else:
		PlayerScript.set_spellWaiting(false)

func set_iceBool(val:bool) -> void:
	iceBool = val

func set_fireBool(val:bool) -> void:
	fireBool = val

func set_targetSphere(val:bool) -> void:
	targetSphere = val

func set_targetingStarted(val:bool) -> void:
	targetingStarted = val

func set_aoeType(val:Mesh)->void:
	aoeType = val

func create_aoe(type : Mesh):
	if targetingStarted == false:
		targetInst = targetObj.instantiate()
		targetInst.mesh = type
		var collider
		world.add_child(targetInst)
		set_targetingStarted(true)
		aoeID = targetInst.get_instance_id()
	Camcast.set_target_position(Vector3(0,0,-150))
	Camcast.force_raycast_update()
	if(Camcast.is_colliding()):
		var aimPos = Camcast.get_collision_point()
		if type == wallMesh:
			aimPos.y += 0.75
		targetInst.transform.origin = aimPos

func resolve_spell():
	if spellWaiting == "fire":
		fire_ball()
		set_spellWaiting("")
		set_targetingStarted(false)
		print("Resolved Spell -------")
	elif spellWaiting == "ice":
		ice_wall()
		set_spellWaiting("")
		set_targetingStarted(false)
		print("Resolved Spell -------")
	elif spellWaiting == "bolt":
		pass
	elif spellWaiting == "air":
		pass


func ice_wall():
	iceBool = false
	iceLastCast = time_passed
	print("lastCast = " + str(iceLastCast))
	iceInstance = iceWall.instantiate()
	var collider
	Camcast.set_target_position(Vector3(0,0,-150))
	Camcast.force_raycast_update()
	
	if(Camcast.is_colliding()):
		world.add_child(iceInstance)
		var aimPos = Camcast.get_collision_point()
		aimPos.y += 0.75
		iceInstance.transform.origin = aimPos
	
	set_targetSphere(false)
	targetInst.queue_free()

func fire_ball():
	fireBool = false
	fireLastCast = time_passed
	print("lastCast = " + str(iceLastCast))
	instance = Fireball.instantiate()
	instance.position = Aimcast.global_position
	instance.transform.basis = Aimcast.global_transform.basis
	world.add_child(instance)
	
	set_targetSphere(false)
	targetInst.queue_free()



func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy") || body.is_in_group("breakables"):
		body.takeDamage(damage * (PlayerScript.swingNum));
		print(body.name + " " + str(body.health))
