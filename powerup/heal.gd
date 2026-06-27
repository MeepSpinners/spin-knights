extends "res://powerup/power_up.gd"

func get_type():
	return 8

func apply(player: Player):
	player.health = min(PlayerStats.max_health, player.health + 1)
	player.change_health()
