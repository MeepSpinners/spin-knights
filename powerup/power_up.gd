extends Area2D

enum Type {
		DAMAGE,
		HEALTH
}

@export var type = Type.DAMAGE

func _ready() -> void:
	match type:
		Type.DAMAGE:
			$Sprite2D.modulate = Color.INDIAN_RED
		Type.HEALTH:
			$Sprite2D.modulate = Color.CHARTREUSE

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	match type:
		Type.DAMAGE:
			body.add_damage_powerup()
		Type.HEALTH:
			body.add_health_powerup()
	queue_free()
