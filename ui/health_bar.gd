extends Node2D

@export var size = Vector2(35,5)
@export var offset = Vector2(0, 5)
@export var bg_col = Color(0,0,0,0.6)
@export var fill_col = Color.GREEN
@export var hide_on_full = true
var ratio = 1

func _ready() -> void:
	top_level = true
	z_index = 100

func set_health(current: float, max: float):
	ratio = clampf(current / max, 0.0, 1.0)
	visible = not (hide_on_full and ratio >= 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(get_parent()):
		global_position = get_parent().global_position + offset

func _draw() -> void:
	var top_left = Vector2(-size.x * 0.5, 0.0)
	fill_col = Color.RED.lerp(Color.GREEN, ratio)
	draw_rect(Rect2(top_left, size), bg_col)
	draw_rect(Rect2(top_left, Vector2(size.x * ratio, size.y)), fill_col)
