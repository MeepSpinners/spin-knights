extends Control

@onready var start_button = $VBoxContainer/Start
@onready var options_button = $VBoxContainer/Options
@onready var quit_button = $VBoxContainer/Quit
@onready var credits_button = $VBoxContainer/Credits

func _ready():
	start_button.pressed.connect(on_start)
	options_button.pressed.connect(on_options)
	credits_button.pressed.connect(_on_credits)
	if OS.has_feature("web"):
		quit_button.hide()
	quit_button.pressed.connect(on_quit)
func on_start():
	get_tree().change_scene_to_file("res://main/main.tscn")
@onready var options_menu = $OptionsMenu
func on_options():
	options_menu.toggle()
func on_quit():
	get_tree().quit()
func _on_credits():
	get_tree().change_scene_to_file("res://menu/credits.tscn")
