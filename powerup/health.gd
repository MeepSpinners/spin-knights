extends "res://powerup/power_up.gd"

func get_type():
	return 0

func apply(player: Player):
	player.add_health_powerup()
