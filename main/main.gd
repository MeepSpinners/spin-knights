class_name Main
extends Node
@export var mob_types: Array[PackedScene] = []
@export var num_mobs = 20

@export var powerup_drop_chance = 0.5

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
	
	$player.start($Marker2D.position)
	await NavigationServer2D.map_changed
	
	Progress.on_start()

func reset_on_player_death():
	PlayerStats.reset()
	Progress.progress = 0
	Progress.rooms_cleared = 0
	get_tree().change_scene_to_file.call_deferred("res://menu/main_menu.tscn")

func reset_new_game():
	Progress.rooms_cleared = 0
	get_tree().change_scene_to_file.call_deferred("res://main/main.tscn")

func on_enemy_die(enemy):
	spawn_powerup.call_deferred(enemy.global_position)
	Progress.killed_an_enemy()

func spawn_powerup(pos: Vector2):
	if randf() > powerup_drop_chance:
		return
	#var powerup = 1 if randf() < 0.5 else 0
	PowerupSpawner.spawn_powerup(8, pos)

@onready var portal = preload("res://portal/portal.tscn")
func open_portal(pos: Vector2):
	var p = portal.instantiate()
	add_child(p)
	p.global_position = pos
