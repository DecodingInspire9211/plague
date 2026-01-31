# npc.gd
class_name NPC
extends Interactable

@export var dialogue_lines: Array[String] = []
@export var idle_animation: String = "idle"
@export var talk_animation: String = "talk"

@onready var prompt_ui: Control = $InteractionPrompt

var current_dialogue_index: int = 0


func _on_ready() -> void:
	print("NPC _on_ready called for: %s" % display_name)
	
	if sprite_node is AnimatedSprite2D:
		play_animation(idle_animation)
	
	# Setup the prompt
	_setup_prompt()


func _setup_prompt() -> void:
	print("Setting up prompt for: %s" % display_name)
	
	if prompt_ui:
		print("Prompt UI found!")
		prompt_ui.visible = false
		
		# Update the label text
		var label = prompt_ui.get_node_or_null("PanelContainer/Label")
		if label:
			print("Label found, setting text to: %s" % interaction_prompt)
			label.text = interaction_prompt
		else:
			print("WARNING: Label not found!")
	else:
		print("WARNING: Prompt UI not found!")
	
	# Connect to signals from the parent Interactable class
	interaction_available.connect(_show_prompt)
	interaction_unavailable.connect(_hide_prompt)
	print("Signals connected!")


func _show_prompt() -> void:
	print("SHOW PROMPT called for: %s" % display_name)
	if prompt_ui:
		prompt_ui.visible = true
		print("Prompt is now visible!")
	else:
		print("ERROR: prompt_ui is null!")


func _hide_prompt() -> void:
	print("HIDE PROMPT called for: %s" % display_name)
	if prompt_ui:
		prompt_ui.visible = false


func _on_interact(interactor: Node) -> void:
	start_dialogue()


func start_dialogue() -> void:
	if dialogue_lines.is_empty():
		print("%s has nothing to say." % display_name)
		return
	
	if sprite_node is AnimatedSprite2D:
		play_animation(talk_animation)
	
	print("%s: %s" % [display_name, dialogue_lines[current_dialogue_index]])
	current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()


func end_dialogue() -> void:
	if sprite_node is AnimatedSprite2D:
		play_animation(idle_animation)
