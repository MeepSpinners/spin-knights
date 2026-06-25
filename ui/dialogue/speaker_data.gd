class_name SpeakerData
extends Resource

@export var display_name: String = "Speaker"
@export var sprite: Texture2D

func is_equal(other: Variant) -> bool:
	if self == other:
		return true
	if not other is SpeakerData:
		return false
	if other.display_name == display_name:
		return true
	return false
