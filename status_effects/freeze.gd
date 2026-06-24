class_name Freeze
extends StatusEffect

var original_speed: float = 1.0

func _init(p_duration: float):
	super._init(preload("res://status_effects/freeze.tres"), p_duration)

func apply(enemy: Enemy):
	super.apply(enemy)
	original_speed = enemy.ai_speed
	enemy.ai_speed = 0
	enemy.base_animation_speed = 0.2

func clear(enemy: Enemy):
	super.clear(enemy)
	enemy.ai_speed = original_speed
	enemy.base_animation_speed = 1.0

func override(other: StatusEffect, enemy: Enemy):
	if other is Freeze:
		clear(enemy)
		var time_left = duration - total_time_passed
		var other_time_left = other.duration - other.total_time_passed
		duration += min(0, other_time_left - time_left)
		apply(enemy)
