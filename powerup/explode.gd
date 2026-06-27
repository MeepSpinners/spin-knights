extends "res://powerup/power_up.gd"

func get_type():
	return 2

func apply(player: Player):
	player.add_explosion_damage_powerup()
