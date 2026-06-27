extends "res://powerup/power_up.gd"

func get_type():
	return 7

func apply(player: Player):
	player.add_speed_powerup()
