extends Node3D

@onready var generator = $".."
@onready var dunMesh = $"../DunMesh"
@onready var gridMap = $"../GridMap"
@onready var spawn : Node3D = $"../Spawn"
var playerController : PackedScene = preload("res://Player_Controller.tscn")
var lantern_scene : PackedScene = preload("res://Items/lantern.tscn")
var lantern_cluster : PackedScene = preload("res://Items/lantern_cluster.tscn")
@onready var Lanterns = $"../Lanterns"

func _ready() -> void:
	generator.generate()
	dunMesh.create_dungeon()
	gridMap.hide()
	var i = 0
	var spawn_pos : Vector3 = generator.room_positions[1]
	spawn_pos.y += 1
	print(spawn_pos)
	await get_tree().create_timer(2).timeout
	for room_pos in generator.room_positions:
		var newLantern = lantern_cluster.instantiate()
		room_pos.y = 2.0
		newLantern.set_position(room_pos)
		newLantern.name = "lantern" + str(i)
		print(room_pos)
		print(newLantern.name)
		newLantern.set_scale(Vector3(0.5,0.5,0.5))
		Lanterns.add_child.call_deferred(newLantern)
	var player = playerController.instantiate()
	generator.add_child.call_deferred(player)
	player.set_position(spawn_pos)
	player.set_scale(Vector3(0.5,0.5,0.5))
