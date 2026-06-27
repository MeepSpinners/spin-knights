class_name PlayerGUI
extends Control

@onready var heart = preload("res://ui/player_gui/Heart.tscn")
@onready var heart_container = $heart_container

func update_health(health: int, max_health: int):
	var hearts = heart_container.get_children()
	for child in hearts:
		child.queue_free()
	
	for i in max_health:
		var heart = heart.instantiate()
		heart_container.add_child(heart)
		if i >= health:
			heart.modulate = Color.BLACK
