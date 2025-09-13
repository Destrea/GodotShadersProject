extends Node3D

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var aoe = $AOE
const DAMAGE = 50.0;
const SPEED = 10.0;
var initBody : Node3D
@onready var fireballBase = $"."
@onready var world = $"."
var bodyList : Array = []

var explosion_vfx = preload("res://Projectiles/explosion_vfx.tscn")
@onready var vfxObj = explosion_vfx.instantiate()
func _ready() -> void:
	world.add_child(vfxObj)
	vfxObj.hide()

func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	if ray.is_colliding():
		var body = ray.get_collider()
		initBody = body
		aoe_blast()
		if body.is_in_group("enemy"):
			body.takeDamage(DAMAGE)
			print(str(body.name) + " direct hit, Health = " + str(body.health))
			ray.enabled = false
			mesh.hide()
		else:
			queue_free()
			print(body.name + " Destroyed the fireball")
	await get_tree().create_timer(1.0).timeout


func _on_timer_timeout():
	queue_free()

func aoe_blast():
	bodyList.erase(initBody)
	vfxObj.set_visible(true)
	vfxObj.playVFX()
	for each in bodyList:
		each.takeDamage(0.5 * DAMAGE)
		print(str(each.name) + " aoe hit, Health = " + str(each.health))
	print(bodyList)
	await get_tree().create_timer(0.6).timeout

func _on_aoe_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		bodyList.append(body)
	
