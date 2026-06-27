extends Node

@onready var powerups = [
	preload("res://powerup/health.tscn"),
	preload("res://powerup/sword.tscn"),
	preload("res://powerup/explode.tscn"),
	preload("res://powerup/cactus.tscn"),
	preload("res://powerup/angry.tscn"),
	preload("res://powerup/spin.tscn"),
	preload("res://powerup/area.tscn"),
	preload("res://powerup/speed.tscn")
]

var main: Main

func _ready():
	main = get_tree().get_first_node_in_group("Main")

func spawn_powerup(type: int, position: Vector2):
	var instance = powerups[type].instantiate()
	main.add_child(instance)
	instance.global_position = position
