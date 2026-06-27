extends Node2D

@export var dc: DialogueChainData
@onready var dialogue_ui: DialogueUI = $CanvasLayer/DialogueUI

func _ready():
	dialogue_ui.visible = true
	dialogue_ui.display_dialogue_chain(dc)
	get_tree().paused = true
	await dialogue_ui.on_dialogue_chain_end
	get_tree().paused = false
	dialogue_ui.visible = false
