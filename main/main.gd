class_name Main
extends Node
@export var mob_types: Array[PackedScene] = []
@export var num_mobs = 20



@export var powerup_drop_chance = 1

@export var spawn_radius = 100

var score

@onready var dialogue_ui: DialogueUI = $CanvasLayer/DialogueUI

@export var dialogue_chain: DialogueChainData

@onready var level_generator: LevelGenerator = $LevelGenerator
@onready var gui = $CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dialogue_ui.visible = false
	level_generator.generate()
	# await level_generator.generation_done
	
	$player.start($Marker2D.position)
	#await get_tree().physics_frame
	#await get_tree().physics_frame
	await NavigationServer2D.map_changed
	
	#for i in 10:
		#if (get_random_point_in_map() == Vector2.ZERO):
			#await get_tree().physics_frame
		#else:
			#print(i)
			#break
			
	#for i in num_mobs:
		#var enemy = mob_types.pick_random().instantiate()
		#add_child(enemy)
		#enemy.start(get_random_point_in_map())
		#enemy.register_death_listener(on_enemy_die)
	
	
	gui.start_dialogue(dialogue_chain)

func get_random_point_in_map():
	var angle = randf() * 2 * PI
	var radius = sqrt(randf()) * spawn_radius
	var point = Vector2.from_angle(angle) * radius
	var map_rid: RID = $Office.get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(map_rid, point)
	
func on_enemy_die(enemy):
	spawn_powerup.call_deferred(enemy.global_position)
	Progress.killed_an_enemy()

func spawn_powerup(pos: Vector2):
	if randf() > powerup_drop_chance:
		return
	var powerup = 1 if randf() < 0.5 else 0
	PowerupSpawner.spawn_powerup(powerup, pos)
