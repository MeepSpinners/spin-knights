extends RichTextLabel

@onready var wait_time = 1.5
@onready var scroll_speed = 100.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var scrollbar = get_v_scroll_bar()
	if wait_time > 0:
		wait_time -= delta
	else:	
		
		scrollbar.value += scroll_speed * delta
	
	if scrollbar.value + scrollbar.page >= scrollbar.max_value:
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://menu/main_menu.tscn")
