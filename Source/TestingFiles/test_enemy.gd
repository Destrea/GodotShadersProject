extends Node3D


@onready var healthBar = $SubViewport/HealthBar3D
@onready var enemyBase = $"."

var health = 100.0;

func takeDamage(damage):
	if health < damage:
		damage = health
	health -= damage;
	if health <= 0:
		die()

func die():
	enemyBase.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	healthBar.value = health;
