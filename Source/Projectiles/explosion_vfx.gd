extends Node3D

@onready var smokeFX = $Smoke
@onready var flameFX = $Flame

func _ready() -> void:
	smokeFX.one_shot = true
	flameFX.one_shot = true

func playVFX():
	smokeFX.restart()
	flameFX.restart()
	await get_tree().create_timer(0.6).timeout

func _on_timer_timeout():
	queue_free()
