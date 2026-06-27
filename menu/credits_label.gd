extends RichTextLabel

@onready var wait_time = 1.5
@onready var scroll_speed = 100.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if wait_time > 0:
		wait_time -= delta
	else:	
		var scrollbar = get_v_scroll_bar()
		scrollbar.value += scroll_speed * delta
	pass
