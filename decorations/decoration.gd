@tool
extends StaticBody2D

@export var offset: float = 0.0:
	set(value):
		offset = value
		_update_sprite_offset()

@export var disabled: bool = false:
	set(value):
		disabled = value
		_update_collision_disabled()

func _ready():
	_update_sprite_offset()
	_update_collision_disabled()

func _update_sprite_offset():
	var sprite = get_node_or_null("Sprite2D")
	if sprite is Sprite2D:
		sprite.offset.y = offset

func _update_collision_disabled():
	var collision = get_node_or_null("CollisionShape2D")
	if collision is CollisionShape2D:
		collision.disabled = disabled
