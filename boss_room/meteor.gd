extends Area2D

@onready var explosion = $Explosion
@onready var shadow = $Shadow

@export var damage = 1.0
@export var recoil_amount = 50.0

@export var enemy_scene: PackedScene

@onready var explosion_scene = preload("res://explosion/explosion.tscn")
@onready var audio = $AudioStreamPlayer

var main: Main
func _ready():
	main = get_tree().get_first_node_in_group("Main")

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(explosion, "offset:y", -13.5, 5.0)
	
	shadow.scale = Vector2.ZERO
	tween.parallel().tween_property(shadow, "scale", Vector2(5.0, 5.0), 5.0)
	await tween.finished
	var e = explosion_scene.instantiate()
	if main:
		main.add_child(e)
	else:
		get_parent().add_child(e)
	e.start(global_position - Vector2(0, 13.5), 27.0)
	explosion.hide()
	shadow.hide()
	
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body is Player:
			body.take_damage(damage, self, recoil_amount)
	
	var enemy = enemy_scene.instantiate()
	if main:
		main.add_child(enemy)
	enemy.global_position = global_position
	enemy.activate()
	audio.play()
	shadow.hide()
	explosion.hide()
