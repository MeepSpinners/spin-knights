extends Node

var progress: int = 0
var has_seen_powerup = [ false, false, false, false, false, false, false, false ]

var player: Player

func main():
	return get_tree().get_first_node_in_group("Main")
func _ready():
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
	if type > 7:
		return
	if not has_seen_powerup[type]:
		has_seen_powerup[type] = true
		main().gui.start_dialogue(powerup_dialogues[type])

func on_start():
	if progress == 0:
		progress = 1
		await main().gui.start_dialogue(preload("res://dialogue/introduction.tres"))
	else:
		await main().gui.start_dialogue(preload("res://dialogue/introduction_alt.tres"))
func on_death():
	if main:
		await main().gui.start_dialogue(preload("res://dialogue/player_death.tres"))
		main().reset_on_player_death()

func enter_new_room():
	if progress == 1:
		if main:
			main().gui.start_dialogue(preload("res://dialogue/world_explanation.tres"))
			progress = 2

func enemy_enter_range():
	if progress == 2:
		if main():
			main().gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_1.tres"))
			progress = 3

func reach_max_speed():
	if progress == 3:
		if main():
			main().gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_2.tres"))
			progress = 4
			PlayerStats.unlock_throwing = true

func killed_an_enemy():
	await get_tree().create_timer(0.5, true, false, true).timeout
	if progress == 4:
		if main():
			main().gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_3.tres"))
			progress = 5

var rooms_cleared = 0
const ROOMS_TO_BOSS = 6
func clear_a_room(room: Room):
	rooms_cleared += 1
	await get_tree().create_timer(0.5, true, false, true).timeout
	if progress == 4 or progress == 5:
		progress = 6
		if main():
			await main().gui.start_dialogue(preload("res://dialogue/fighting_tutorial_part_4.tres"))
	if rooms_cleared == ROOMS_TO_BOSS:
		if main():
			main().open_portal(room.global_position)
	elif main():
		main().gui.open_roulette(room)
	

func near_to_portal():
	if main():
		await main().gui.start_dialogue(preload("res://dialogue/near_portal.tres"))

func enter_boss_room():
	if main():
		await main().gui.start_dialogue(preload("res://dialogue/enter_boss_room.tres"))

@onready var finish_portal = preload("res://portal/finish_portal.tscn")
func cleared_boss():
	if main():
		await get_tree().create_timer(1.0, true, false, false).timeout
		await main().gui.start_dialogue(preload("res://dialogue/boss_dead.tres"))
		var portal = finish_portal.instantiate()
		main().add_child(portal)
		portal.global_position = Vector2(10000, 10000)
