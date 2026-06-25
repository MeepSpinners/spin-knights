class_name Room
extends Area2D

@export var room_size = 256

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST	
}

@onready var walls: Dictionary[Direction, StaticBody2D] = {
	Direction.NORTH: $wall_n,
	Direction.SOUTH: $wall_s,
	Direction.EAST: $wall_e,
	Direction.WEST: $wall_w
}

@export var has_door: Dictionary[Direction, bool] = {
	Direction.NORTH: false,
	Direction.SOUTH: false,
	Direction.EAST: false,
	Direction.WEST: false
}
	
func unlock_door(dir: Direction):
	walls[dir].collision_layer = 0

func lock_door(dir: Direction):
	walls[dir].collision_layer = 1 << 5

var enemies: Array[Enemy]

func on_enemy_die(enemy: Enemy):
	enemies.erase(enemy)
	enemy.deregister_death_listener(on_enemy_die)
	if enemies.size() == 0:
		room_clear()

func room_clear():
	for direction in Direction.keys():
		unlock_door(Direction[direction])

func _ready():
	# Gather the enemies
	for enemy in $Enemies.get_children():
		if (enemy is Enemy):
			enemies.append(enemy)
			enemy.register_death_listener(on_enemy_die)
	
