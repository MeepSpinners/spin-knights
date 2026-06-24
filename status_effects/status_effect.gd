class_name StatusEffect
extends RefCounted

var data: StatusEffectData
var duration: float
var interval_time_passed: float
var total_time_passed: float

func _init(p_data: StatusEffectData, p_duration: float):
	data = p_data
	duration = p_duration

func apply(enemy: Enemy):
	pass

func clear(enemy: Enemy):
	pass

func tick(enemy: Enemy, delta: float) -> float:
	interval_time_passed += delta
	total_time_passed += delta
	while interval_time_passed > data.tick_interval:
		interval_time_passed -= data.tick_interval
		tick_effect(enemy)
	return max(1.0, total_time_passed / duration)

func has_ended():
	return total_time_passed > duration

func tick_effect(enemy: Enemy):
	pass

func override(other: StatusEffect, enemy: Enemy):
	pass
