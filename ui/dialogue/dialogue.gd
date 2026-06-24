class_name DialogueUI
extends Control

signal on_dialogue_end(success: bool)
signal on_dialogue_chain_end(uuid: int, success: bool)

var time_between_letters = 0.02

var displaying_text = false

@onready var text_box = $bottom_container/text_container/text

class SpeakerBox:
	var text: RichTextLabel
	var sprite: TextureRect
	
	func _init(p_text: RichTextLabel, p_sprite: TextureRect):
		text = p_text
		sprite = p_sprite

var speaker_box_1: SpeakerBox
var speaker_box_2: SpeakerBox

func _ready():
	speaker_box_1 = SpeakerBox.new(
		$speaker_container/text_container/text, $speaker_sprite)
	speaker_box_2 = SpeakerBox.new(
		$speaker_container2/text_container/text, $speaker_sprite2)
	
var allowed_to_continue = false
var allowed_to_skip_finish = false
var should_skip_finish = false

func display_dialogue_chain(dialogue_chain: DialogueChainData):
	for dialogue in dialogue_chain.dialogues:
		display_dialogue(dialogue)
		var success = await on_dialogue_end
		if not success:
			on_dialogue_chain_end.emit(false)
			return
	on_dialogue_chain_end.emit(true)

func unfocus(sb: SpeakerBox):
	sb.text.visible = true
	sb.sprite.visible = true
	var col = sb.text.modulate
	sb.text.modulate = Color.from_hsv(
		col.h, col.s, 0.3, 1.0
	)
	col = sb.sprite.modulate
	sb.sprite.modulate = Color.from_hsv(
		col.h, col.s, 0.3, 1.0
	)
func focus(sb: SpeakerBox):
	sb.text.visible = true
	sb.sprite.visible = true
	var col = sb.text.modulate
	sb.text.modulate = Color.from_hsv(
		col.h, col.s, 1.0, 1.0
	)
	col = sb.sprite.modulate
	sb.sprite.modulate = Color.from_hsv(
		col.h, col.s, 1.0, 1.0
	)
func make_invisible(sb: SpeakerBox):
	sb.text.visible = false
	sb.sprite.visible = false
func update_speaker(sb: SpeakerBox, s: SpeakerData):
	sb.text.text = s.display_name
	sb.sprite.texture = s.sprite
func display_dialogue(dialogue: DialogueData):
	# cancelling mechanism
	allowed_to_continue = false
	allowed_to_skip_finish = false
	should_skip_finish = false
	
	# Just to make sure we don't hang everything
	await get_tree().process_frame
	text_box.text = dialogue.text
	text_box.visible_characters = 0
	
	if dialogue.speaker_turn == 1:
		focus(speaker_box_1)
		unfocus(speaker_box_2)
	else:
		focus(speaker_box_2)
		unfocus(speaker_box_1)
	
	if (not dialogue.speaker1):
		make_invisible(speaker_box_1)
	else:
		update_speaker(speaker_box_1, dialogue.speaker1)
	if (not dialogue.speaker2):
		make_invisible(speaker_box_2)
	else:
		update_speaker(speaker_box_2, dialogue.speaker2)
	
	for i in dialogue.text.length():
		await get_tree().create_timer(time_between_letters, true, false, true).timeout
		if should_skip_finish:
			text_box.visible_characters = text_box.text.length()
			break
		text_box.visible_characters += 1
		if (text_box.visible_characters >= dialogue.required_characters):
			allowed_to_skip_finish = true
	
	await get_tree().create_timer(0.5, true, false, true).timeout
	allowed_to_continue = true
	allowed_to_skip_finish = false
	return

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("continue"):
		if allowed_to_skip_finish:
			should_skip_finish = true
		elif allowed_to_continue:
			on_dialogue_end.emit(true)
