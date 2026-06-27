extends "res://powerup/power_up.gd"

func get_type():
	return 0

func apply(player: Player):
	player.health += 1
	player.max_health += 1
	player.change_health()
