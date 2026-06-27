extends Area2D

@export var boss_room_location = Vector2(10000.0, 10000.0)

func _ready():
	body_entered.connect(on_player_entered)
	$Area2D.body_entered.connect(on_player_nearby)

func on_player_entered(body: Variant):
	if body is Player:
		body.teleport(boss_room_location)
		Progress.enter_boss_room()

func on_player_nearby(body: Variant):
	if body is Player:
		Progress.near_to_portal()
		
