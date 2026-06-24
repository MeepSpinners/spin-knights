class_name DialogueData
extends Resource

@export_multiline var text: String = "":
	set(value):
		text = value
		# Automatically calculate required characters if it hasn't been set manually
		if required_characters == -1:
			required_characters = text.length() / 2

@export var speaker1: SpeakerData
@export var speaker2: SpeakerData

@export_enum("Speaker 1:1", "Speaker 2:2") var speaker_turn: int = 1
@export var required_characters: int = -1
