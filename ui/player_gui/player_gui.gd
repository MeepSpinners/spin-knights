class_name PlayerGUI
extends Control

@onready var heart = preload("res://ui/player_gui/Heart.tscn")
@onready var heart_container = $heart_container

func update_health(num: int):
	var hearts = heart_container.get_children()
	if hearts.size() > num:
		for i in hearts.size() - num:
			heart_container.remove_child(hearts[i])
	else:
		for i in num - hearts.size():
			heart_container.add_child(heart.instantiate())
