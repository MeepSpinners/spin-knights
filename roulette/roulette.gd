extends Control

signal spin_complete(result: int)

var ready_to_spin = false

var time_spun: float

const DEFAULT_SPEED = 15.0
const SPEED_VARIANCE = 25.0
const SPIN_TIME = 5
const DECELERATION = 0.5
const CLICK_SPEED_REDUCTION = 0.2

var w = 0.0
var distance_to_peg = 22.5 / 180.0 * PI

func jitter(scale: float):
	return randf() * scale - scale / 2.0

@onready var wheel = $TextureRect
@onready var click = $AudioStreamPlayer

func activate():
	wheel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(wheel, "scale", Vector2.ONE, 0.5)
	await tween.finished
	label.show()
	ready_to_spin = true
	timer.timeout.connect(on_timer)
	timer.start()

func finish():
	time_spun = 0.0
	spin_complete.emit(
		(8 - int(wheel.rotation_degrees / 45.0)) % 8
	)
	spinned = false
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(wheel, "scale", Vector2.ZERO, 0.5)
	await tween.finished
	wheel.rotation = 0.0
	distance_to_peg = 22.5 / 180.0 * PI

func _process(delta: float):
	if w <= 0.01 and spinned:
		w = 0.0
		finish()
	if spinned:
		time_spun = time_spun + delta
	if time_spun > SPIN_TIME:
		w = max(0.0, w - (DECELERATION + jitter(0.1)) * delta)
	
	wheel.rotation += w * delta
	distance_to_peg += w * delta
	while distance_to_peg > 2 * PI / 8:
		distance_to_peg -= 2 * PI / 8
		click.play()
		w = max(0.0, w - CLICK_SPEED_REDUCTION)

var spinned = false

func spin():
	w = randf() * SPEED_VARIANCE + DEFAULT_SPEED
	ready_to_spin = false
	spinned = true
	label.visible = false
	timer.timeout.disconnect(on_timer)

func _input(event: InputEvent):
	if event.is_action_pressed("continue") and ready_to_spin:
		spin()

@onready var timer = $Timer

@onready var label = $Label

func on_timer():
	timer.start()
	if spinned:
		return
	label.visible = not label.visible
	
