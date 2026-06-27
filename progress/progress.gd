extends Node

var progress: int = 0
var has_seen_powerup = [ false, false, false, false, false, false, false, false ]

var main: Main
var player: Player

func _ready():
	main = get_tree().get_first_node_in_group("Main")
	player = get_tree().get_first_node_in_group("Player")

@onready var powerup_dialogues = [
	preload("res://dialogue/powerup_health.tres"),
	preload("res://dialogue/powerup_sword.tres"),
	preload("res://dialogue/powerup_explode.tres"),
	preload("res://dialogue/powerup_cactus.tres"),
	preload("res://dialogue/powerup_explode_range.tres"),
	preload("res://dialogue/powerup_spin.tres"),
	preload("res://dialogue/powerup_area.tres"),
	preload("res://dialogue/powerup_speed.tres")
]

func spawn_new_powerup(type: int):
	if not has_seen_powerup[type]:
		has_seen_powerup[type] = true
		main.gui.start_dialogue(powerup_dialogues[type])

func enter_new_room():
	if progress == 0:
		main.gui.start_dialogue(preload("res://dialogue/world_explanation.tres"))
		progress = 1

func enemy_enter_range():
	if progress == 1:
		main.gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_1.tres"))
		progress = 2

func reach_max_speed():
	if progress == 2:
		main.gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_2.tres"))
		progress = 3
		player.unlocked_throwing = true

func killed_an_enemy():
	await get_tree().create_timer(0.5, true, false, true).timeout
	if progress == 3:
		main.gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_3.tres"))
		progress = 4

func clear_a_room(room: Room):
	await get_tree().create_timer(0.5, true, false, true).timeout
	if progress == 4 or progress == 3:
		progress = 5
		await main.gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_4.tres"))
	main.gui.open_roulette(room)
	
