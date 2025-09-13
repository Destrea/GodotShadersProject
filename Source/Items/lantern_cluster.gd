extends Node3D

@onready var lantern = $Lantern;
@onready var lantern2 = $Lantern2;
@onready var lantern3 = $Lantern3;
@onready var lantern4 = $Lantern4;

func _ready() -> void:
	lantern.setOffset()
	lantern2.setOffset()
	lantern3.setOffset()
	lantern4.setOffset()
	
