extends Area2D

enum Type {
		DAMAGE,
		HEALTH
}

@export var type = Type.DAMAGE

var falling = true

@onready var icon = $Icon
@onready var shadow = $Shadow
@onready var collision = $CollisionShape2D
@onready var pop_sound = $AudioStreamPlayer

var initial_offset: float
var speed: Vector2 = Vector2.from_angle(randf() * 2 * PI) * 4
var deceleration: float = 1

func get_type():
	return -1

func _process(delta: float):
	global_position += speed * delta
	speed.x = move_toward(speed.x, 0.0, deceleration * delta)
	speed.y = move_toward(speed.y, 0.0, deceleration * delta)

	if not pickable:
		return
	var bodies = get_overlapping_bodies()
	if bodies.size() < 1:
		return
	var body = bodies[0]
	if not body is Player:
		return
	apply(body)
	pop_sound.play()
	hide()
	pickable = false
	await pop_sound.finished
	queue_free()

var pickable = false

func _ready() -> void:
	initial_offset = icon.offset.y
	icon.offset.y = -64.0
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(icon, "offset:y", initial_offset, 1.0)
	await tween.finished
	Progress.spawn_new_powerup(get_type())
	pickable = true

func apply(player: Player):
	pass
