extends Node
@export var mob_types: Array[PackedScene] = []
@export var num_mobs = 20
@export var powerup_scene: PackedScene
@export var powerup_drop_chance = 1

@export var spawn_radius = 100

var score

@onready var dialogue_ui: DialogueUI = $CanvasLayer/DialogueUI

@export var dialogue_chain: DialogueChainData

@onready var level_generator: LevelGenerator = $LevelGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_generator.generate()
	await level_generator.generation_done
	
	$player.start($Marker2D.position)
	dialogue_ui.visible = false
	#await get_tree().physics_frame
	#await get_tree().physics_frame
	await NavigationServer2D.map_changed
	
	#for i in 10:
		#if (get_random_point_in_map() == Vector2.ZERO):
			#await get_tree().physics_frame
		#else:
			#print(i)
			#break
			
	for i in num_mobs:
		var enemy = mob_types.pick_random().instantiate()
		add_child(enemy)
		enemy.start(get_random_point_in_map())
		enemy.register_death_listener(on_enemy_die)
	
	
	start_dialogue(dialogue_chain)

func start_dialogue(dc: DialogueChainData):
	dialogue_ui.visible = true
	dialogue_ui.display_dialogue_chain(dc)
	get_tree().paused = true
	await dialogue_ui.on_dialogue_chain_end
	get_tree().paused = false
	dialogue_ui.visible = false
	
func get_random_point_in_map():
	var angle = randf() * 2 * PI
	var radius = sqrt(randf()) * spawn_radius
	var point = Vector2.from_angle(angle) * radius
	var map_rid: RID = $Office.get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(map_rid, point)
	
func on_enemy_die(enemy):
	spawn_powerup.call_deferred(enemy.global_position)

func spawn_powerup(pos: Vector2):
	if powerup_scene == null:
		return
	if randf() > powerup_drop_chance:
		return
	var power = powerup_scene.instantiate()
	power.type = power.Type.DAMAGE if randf() < 0.5 else power.Type.HEALTH
	add_child(power)
	power.global_position = pos
