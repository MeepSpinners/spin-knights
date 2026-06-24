class_name Disgusted
extends StatusEffect

func _init(p_duration: float):
	super._init(preload("res://status_effects/disgusted.tres"), p_duration)

func apply(enemy: Enemy):
	enemy.active_tags.append("always_flee")

func clear(enemy: Enemy):
	enemy.active_tags.erase("always_flee")
	enemy.choose_behaviour()
