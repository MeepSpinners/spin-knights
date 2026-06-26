extends Control

@onready var sound_slider = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/HSlider
@onready var master_bus_index = AudioServer.get_bus_index("Master")
@onready var close_button = $PanelContainer/MarginContainer/Close

func _ready():
	sound_slider.value = Settings.volume
	sound_slider.value_changed.connect(on_sound_slider_move)
	close_button.pressed.connect(on_close)

func on_close():
	toggle()

var is_open = false

func toggle():
	if is_open:
		close()
	else:
		if get_tree().paused:
			return
		open()

func open():
	if is_open:
		return
	show()
	get_tree().paused = true
	is_open = true

func close():
	if not is_open:
		return
	hide()
	get_tree().paused = false
	is_open = false

func on_sound_slider_move(val):
	Settings.volume = val
	
	if val == 0:
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		
		var db_value = linear_to_db(val)
		AudioServer.set_bus_volume_db(master_bus_index, db_value)

func _input(event: InputEvent):
	if event.is_action_pressed("options"):
		toggle()
