extends "res://powerup/power_up.gd"

func get_type():
	return 4

func apply(player: Player):
	player.add_explosion_range_powerup()
