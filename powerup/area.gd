extends "res://powerup/power_up.gd"

func get_type():
	return 6

func apply(player: Player):
	player.add_area_powerup()
