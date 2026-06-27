extends Node

var spin_duration_shortening = 1.0
var additional_explosion_damage = 0
var additional_explosion_range = 0.0
var damage_multiplier = 1
var thorns_damage = 0.0
var max_health = 5
var unlock_throwing = false

func add_damage_powerup():
	damage_multiplier += 0.2
func add_health_powerup():
	max_health += 1.0
func add_explosion_damage_powerup():
	additional_explosion_damage += 1.0
func add_explosion_range_powerup():
	additional_explosion_range += 1.0
func add_thorns_powerup():
	thorns_damage += 1.0
var speed_multiplier = 1.0
func add_speed_powerup():
	speed_multiplier += 0.1
func add_spin_speed_powerup():
	spin_duration_shortening *= 0.9

func reset():
	spin_duration_shortening = 1.0
	additional_explosion_damage = 0
	additional_explosion_range = 0.0
	damage_multiplier = 1
	thorns_damage = 0.0
	max_health = 5
	Progress.progress = 0
