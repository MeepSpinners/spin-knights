extends Node
@export var mob_scene: PackedScene
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player.start($Marker2D.position)
	$enemy.start($Marker2D2.position)
