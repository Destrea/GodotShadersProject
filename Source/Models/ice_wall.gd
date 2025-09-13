extends Node3D

@onready var wallBase = $".."
var health = 100.0;

func takeDamage(damage):
	if health < damage:
		damage = health
	health -= damage;
	if health <= 0:
		die()

func die():
	wallBase.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
