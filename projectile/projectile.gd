extends Area2D

class_name Projectile

@export var lifetime = 4.0
@export var pierce = false

var velocity = Vector2.ZERO
var damage = 10.0
var recoil_amount = 3.0
var source: Node = null

func setup(pos, vel, dam, recoil, proj_source):
	global_position = pos
	velocity = vel
	damage = dam
	recoil_amount = recoil
	source = proj_source
	rotation = velocity.angle()

func _ready() -> void:
	get_tree().create_timer(lifetime, true, true, false).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, self, recoil_amount)
		if not pierce:
			queue_free()
	else:
		queue_free()
