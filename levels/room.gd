class_name Room
extends Area2D

@export var room_size = 324

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST	
}

var walls: Dictionary[Direction, StaticBody2D] = {}
var neighbours: Dictionary[Direction, Room] = {}

static func get_door_from_string(s: String) -> Dictionary[Direction, bool]:
	return {
		Direction.NORTH: s.contains("N"),
		Direction.SOUTH: s.contains("S"),
		Direction.EAST: s.contains("E"),
		Direction.WEST: s.contains("W")
	}

func unlock_door(dir: Direction):
	if walls.has(dir):
		walls[dir].collision_layer = 0
		walls[dir].hide()

func lock_door(dir: Direction):
	if walls.has(dir):
		walls[dir].collision_layer = 1 << 3

var enemies: Array[Enemy]

func on_enemy_die(enemy: Enemy):
	enemies.erase(enemy)
	enemy.deregister_death_listener(on_enemy_die)
	if enemies.size() == 0:
		room_clear()
		Progress.clear_a_room(self)

func get_opposite(dir: Direction):
	match dir:
		Direction.NORTH:
			return Direction.SOUTH
		Direction.SOUTH:
			return Direction.NORTH
		Direction.EAST:
			return Direction.WEST
		Direction.WEST:
			return Direction.EAST

func room_clear():
	for direction in Direction.values():
		unlock_door(direction)
	for dir in neighbours.keys():
		neighbours[dir].unlock_door(get_opposite(dir))
		# neighbours[dir].activate(false)

func _ready():
	collision_layer = 1 << 4
	
	if has_node("wall_n"): walls[Direction.NORTH] = $wall_n
	if has_node("wall_s"): walls[Direction.SOUTH] = $wall_s
	if has_node("wall_e"): walls[Direction.EAST] = $wall_e
	if has_node("wall_w"): walls[Direction.WEST] = $wall_w
	
	for dir in Direction.keys():
		lock_door(Direction[dir])

	$Sprite2D.z_index = -100

func setup():
	for direction in Direction.values():
		if not neighbours.has(direction):
			unlock_door(direction)

var activated = false
func activate(no_enemies: bool):
	if activated:
		return
	if not no_enemies:
		Progress.enter_new_room()
	activated = true
	# Gather the enemies
	var enemies_node = get_node_or_null("Enemies")
	var target_parent = get_tree().get_first_node_in_group("Main")
	if enemies_node != null:
		for enemy in enemies_node.get_children():
			if (enemy is Enemy):
				if no_enemies:
					enemy.queue_free()
					continue
				enemies.append(enemy)
				enemy.register_death_listener(on_enemy_die)
				var pos = enemy.global_position
				enemies_node.remove_child(enemy)
				target_parent.call_deferred("add_child", enemy)
				enemy.set_deferred("global_position", pos)
				enemy.activate()
				enemy.register_death_listener(target_parent.on_enemy_die)
	
	var decorations_node = get_node_or_null("Decorations")
	if decorations_node != null:
		for decoration in decorations_node.get_children():
			var pos = decoration.global_position
			decorations_node.remove_child(decoration)
			target_parent.call_deferred("add_child", decoration)
			decoration.set_deferred("global_position", pos)
	
	if no_enemies:
		room_clear()
