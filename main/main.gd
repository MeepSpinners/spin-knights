extends Node
@export var mob_scene: PackedScene
@export var num_mobs = 20
@export var powerup_scene: PackedScene
@export var powerup_drop_chance = 1
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$player.start($Marker2D.position)
	
	for i in num_mobs:
		var enemy = mob_scene.instantiate()
		add_child(enemy)
		enemy.start($Marker2D2.position)
		enemy.register_death_listener(on_enemy_die)
		await get_tree().create_timer(1.0, true, false, false).timeout
		
func on_enemy_die(enemy):
	spawn_powerup.call_deferred(enemy.global_position)

func spawn_powerup(pos: Vector2):
	if powerup_scene == null:
		return
	if randf() > powerup_drop_chance:
		return
	var power = powerup_scene.instantiate()
	power.type = power.Type.DAMAGE if randf() < 0.5 else power.Type.HEALTH
	add_child(power)
	power.global_position = pos
