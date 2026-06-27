extends Area2D

func _ready():
	body_entered.connect(on_player_entered)

func on_player_entered(body: Variant):
	if body is Player:
		get_tree().get_first_node_in_group("Main").reset_new_game()
