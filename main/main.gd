extends Node
@export var mob_scene: PackedScene
@export var num_mobs = 20
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player.start($Marker2D.position)
	
	for i in num_mobs:
		var enemy = mob_scene.instantiate()
		add_child(enemy)
		enemy.start($Marker2D2.position)
		await get_tree().create_timer(1.0, true, false, false).timeout
