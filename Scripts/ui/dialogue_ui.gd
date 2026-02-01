extends Control

signal choice_made(index: int)

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var choices_box: Control = $Panel/MarginContainer/VBoxContainer/ChoicesBox
@onready var option_a: Button = $Panel/MarginContainer/VBoxContainer/ChoicesBox/OptionA
@onready var option_b: Button = $Panel/MarginContainer/VBoxContainer/ChoicesBox/OptionB

var current_npc_name: String = ""
var dialogue_queue: Array[String] = []
var current_dialogue_index: int = 0

var awaiting_choice: bool = false


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Hook up the two buttons once
	if not option_a.pressed.is_connected(_on_option_a_pressed):
		option_a.pressed.connect(_on_option_a_pressed)
	if not option_b.pressed.is_connected(_on_option_b_pressed):
		option_b.pressed.connect(_on_option_b_pressed)

	_clear_choices()


# ---- Normal dialogue ----
func show_dialogue(npc_name: String, text: String) -> void:
	_clear_choices()
	awaiting_choice = false

	current_npc_name = npc_name
	dialogue_queue = [text]
	current_dialogue_index = 0

	name_label.text = npc_name
	dialogue_label.text = text
	show()


func show_dialogue_lines(npc_name: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return

	_clear_choices()
	awaiting_choice = false

	current_npc_name = npc_name
	dialogue_queue = lines.duplicate()
	current_dialogue_index = 0

	_display_current_line()
	show()


# ---- Choice dialogue (2 options) ----
func show_choice(npc_name: String, text: String, choices: Array[String]) -> void:
	# This UI supports 2 choices (OptionA / OptionB)
	_clear_choices()

	awaiting_choice = true
	current_npc_name = npc_name
	dialogue_queue = [text]
	current_dialogue_index = 0
	_display_current_line()
	show()

	choices_box.show()

	# Set button text (fallbacks if someone passes weird data)
	if choices.size() >= 1:
		option_a.text = choices[0]
	else:
		option_a.text = "Option A"

	if choices.size() >= 2:
		option_b.text = choices[1]
	else:
		option_b.text = "Option B"

	# Ensure both are visible (you can hide option_b if you ever want 1 choice)
	option_a.show()
	option_b.show()

	# Optional: keyboard/controller focus
	option_a.grab_focus()


func _on_option_a_pressed() -> void:
	if not awaiting_choice:
		return
	awaiting_choice = false
	_clear_choices()
	choice_made.emit(0)


func _on_option_b_pressed() -> void:
	if not awaiting_choice:
		return
	awaiting_choice = false
	_clear_choices()
	choice_made.emit(1)


func _display_current_line() -> void:
	if current_dialogue_index >= dialogue_queue.size():
		hide_dialogue()
		return

	name_label.text = current_npc_name
	dialogue_label.text = dialogue_queue[current_dialogue_index]


func next_line() -> void:
	current_dialogue_index += 1
	if current_dialogue_index < dialogue_queue.size():
		_display_current_line()
	else:
		hide_dialogue()


func hide_dialogue() -> void:
	hide()
	dialogue_queue.clear()
	current_dialogue_index = 0
	_clear_choices()
	awaiting_choice = false

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("end_dialogue"):
		game_manager.end_dialogue()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# While choices are shown, do NOT advance dialogue on interact/accept
	if awaiting_choice:
		return

	if event.is_action_pressed("player_interact") or event.is_action_pressed("ui_accept"):
		if not dialogue_queue.is_empty():
			next_line()
			get_viewport().set_input_as_handled()


func _clear_choices() -> void:
	if choices_box:
		choices_box.hide()
	if option_a:
		option_a.hide()
	if option_b:
		option_b.hide()
