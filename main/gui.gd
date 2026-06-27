extends CanvasLayer

@onready var dialogue_ui = $DialogueUI
@onready var player_ui = $PlayerGUI
@onready var options_menu = $OptionsMenu
@onready var roulette = $Roulette
@onready var main: Main

func _ready():
	main = get_tree().get_first_node_in_group("Main")

func open_roulette(room):
	roulette.activate()
	var powerup = await roulette.spin_complete
	PowerupSpawner.spawn_powerup(powerup, room.global_position)
	
func start_dialogue(dc: DialogueChainData):
	dialogue_ui.visible = true
	dialogue_ui.display_dialogue_chain(dc)
	get_tree().paused = true
	await dialogue_ui.on_dialogue_chain_end
	get_tree().paused = false
	dialogue_ui.visible = false
