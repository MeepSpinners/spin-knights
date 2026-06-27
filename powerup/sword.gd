extends "res://powerup/power_up.gd"

func get_type():
	return 1

func apply(player: Player):
	player.add_damage_powerup()
