# npc.gd
class_name NPC
extends Interactable

@export var dialogue_lines: Array[String] = []
@export var idle_animation: String = "idle"
@export var talk_animation: String = "talk"
@export var max_health: int = 100
@export var can_get_sick: bool = true

@onready var prompt_ui: Control = $InteractionPrompt

var current_dialogue_index: int = 0
var current_health: int = 100
var current_disease: Disease = null
var is_sick: bool = false
var is_cured: bool = false


func _on_ready() -> void:
	if sprite_node is AnimatedSprite2D:
		play_animation(idle_animation)
	
	current_health = max_health
	_setup_prompt()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	
	if is_sick and current_disease:
		_progress_disease(delta)


func _setup_prompt() -> void:
	if not prompt_ui:
		push_warning("NPC %s: Prompt UI not found!" % display_name)
		return
	
	prompt_ui.visible = false
	
	var label := prompt_ui.get_node_or_null("PanelContainer/Label") as Label
	if label:
		label.text = interaction_prompt
	else:
		push_warning("NPC %s: Label not found in prompt UI!" % display_name)
	
	# Connect to signals from the parent Interactable class
	if not interaction_available.is_connected(_show_prompt):
		interaction_available.connect(_show_prompt)
		interaction_unavailable.connect(_hide_prompt)


func _show_prompt() -> void:
	if prompt_ui:
		prompt_ui.visible = true


func _hide_prompt() -> void:
	if prompt_ui:
		prompt_ui.visible = false


func _on_interact(_interactor: Node) -> void:
	start_dialogue()


func start_dialogue() -> void:
	if dialogue_lines.is_empty():
		# If sick, show disease info instead
		if is_sick and current_disease:
			var info := get_disease_info()
			_show_dialogue("%s: *coughs* I have %s... (%s)" % [display_name, info["disease_name"], info["severity"]])
		else:
			_show_dialogue("%s has nothing to say." % display_name)
		return
	
	# Show dialogue in UI
	_show_dialogue_lines()


func _show_dialogue(text: String) -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.start_dialogue(display_name)
	
	# Find dialogue UI
	var dialogue_ui = _find_dialogue_ui()
	if dialogue_ui and dialogue_ui.has_method("show_dialogue"):
		dialogue_ui.show_dialogue(display_name, text)


func _show_dialogue_lines() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.start_dialogue(display_name)
	
	# Find dialogue UI
	var dialogue_ui = _find_dialogue_ui()
	if dialogue_ui and dialogue_ui.has_method("show_dialogue_lines"):
		dialogue_ui.show_dialogue_lines(display_name, dialogue_lines)


func _find_dialogue_ui() -> Control:
	# Try to find player's dialogue UI
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback: search in scene tree
		return get_tree().root.find_child("DialogueUI", true, false)
	
	var ui_layer = player.get_node_or_null("UILayer")
	if ui_layer:
		return ui_layer.get_node_or_null("DialogueUI")
	
	return null


func end_dialogue() -> void:
	if sprite_node is AnimatedSprite2D:
		play_animation(idle_animation)


# Health and death management
func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = max(0, current_health)
	
	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	current_health += amount
	current_health = min(current_health, max_health)


func die() -> void:
	# Notify GameManager
	if GameManager:
		GameManager.notify_npc_death(self , display_name)
	
	# Disable interaction
	disable_interaction()
	
	# Hide prompt
	if prompt_ui:
		prompt_ui.visible = false
	
	# Play death animation if available
	if sprite_node is AnimatedSprite2D and sprite_node.sprite_frames.has_animation("death"):
		play_animation("death")
		await sprite_node.animation_finished
	
	# Remove from scene
	queue_free()


func is_alive() -> bool:
	return current_health > 0


func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


# Disease system
func infect(disease: Disease) -> bool:
	if not can_get_sick or is_sick or is_cured:
		return false
	
	current_disease = disease
	is_sick = true
	
	# Apply visual tint
	if sprite_node and disease:
		sprite_node.modulate = disease.visual_tint
	
	# Notify GameManager
	if GameManager:
		GameManager.dialogue_started.emit(display_name + " has been infected!")
	
	print("%s has been infected with %s" % [display_name, disease.disease_name])
	return true


func _progress_disease(delta: float) -> void:
	if not current_disease:
		return
	
	current_disease.progress(delta)
	
	# Deal damage over time
	var damage: float = current_disease.damage_per_second * delta
	take_damage(int(damage))
	
	# Check if disease is fatal and critical
	if current_disease.is_fatal and current_disease.get_severity() >= 1.0:
		if is_alive():
			die()


func apply_medicine(medicine: Item) -> bool:
	if not is_sick or not current_disease:
		print("%s is not sick" % display_name)
		return false
	
	if not medicine.is_medicine:
		print("%s is not medicine" % medicine.item_name)
		return false
	
	# Check if medicine cures this disease
	if not medicine.cures_diseases.has(current_disease.disease_name):
		print("%s doesn't cure %s" % [medicine.item_name, current_disease.disease_name])
		return false
	
	# Success rate check
	if randf() > medicine.cure_success_rate:
		print("Treatment failed!")
		return false
	
	# Cure the disease
	cure_disease()
	
	# Apply healing
	if medicine.healing_amount > 0:
		heal(medicine.healing_amount)
	
	print("%s cured %s with %s!" % [display_name, current_disease.disease_name, medicine.item_name])
	return true


func cure_disease() -> void:
	if not is_sick:
		return
	
	is_sick = false
	is_cured = true
	current_disease = null
	
	# Restore normal color
	if sprite_node:
		sprite_node.modulate = Color(1, 1, 1, 1)
	
	# Notify GameManager
	if GameManager:
		GameManager.dialogue_ended.emit()
	
	print("%s has been cured!" % display_name)


func get_disease_info() -> Dictionary:
	if not is_sick or not current_disease:
		return {}
	
	return {
		"disease_name": current_disease.disease_name,
		"description": current_disease.description,
		"severity": current_disease.get_severity_name(),
		"symptoms": current_disease.symptoms,
		"time_infected": current_disease.time_infected
	}


func is_healthy() -> bool:
	return not is_sick and is_alive()
