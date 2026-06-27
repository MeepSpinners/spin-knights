extends "res://powerup/power_up.gd"

func get_type():
	return 3

func apply(player: Player):
	player.add_thorns_powerup()
