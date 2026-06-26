extends Node

const SAVE_PATH = "user:://settings.cfg"

var volume: float = 1.0

func _ready():
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.save(SAVE_PATH)

func save_settings():
	var config = ConfigFile.new()

	var error = config.load(SAVE_PATH)
	if error != OK:
		return
	
	volume = config.get_value("settings", "volume", 1.0)
