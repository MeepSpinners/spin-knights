extends "res://powerup/power_up.gd"

func get_type():
	return 5

func apply(player: Player):
	player.add_spin_speed_powerup()
