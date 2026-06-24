class_name Explosion
extends AnimatedSprite2D

func start(position: Vector2, radius: float):
	self.visible = true
	global_position = position
	var size = radius / 16
	self.scale = Vector2(size, size)
	self.play()
	await self.animation_finished
	queue_free()
