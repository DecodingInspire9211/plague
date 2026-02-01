extends Control

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var panel: Panel = $Panel

var current_npc_name: String = ""
var dialogue_queue: Array[String] = []
var current_dialogue_index: int = 0


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_dialogue(npc_name: String, text: String) -> void:
	current_npc_name = npc_name
	dialogue_queue = [text]
	current_dialogue_index = 0
	
	if name_label:
		name_label.text = npc_name
	
	if dialogue_label:
		dialogue_label.text = text
	
	show()


func show_dialogue_lines(npc_name: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	
	current_npc_name = npc_name
	dialogue_queue = lines.duplicate()
	current_dialogue_index = 0
	
	_display_current_line()
	show()


func _display_current_line() -> void:
	if current_dialogue_index >= dialogue_queue.size():
		hide_dialogue()
		return
	
	if name_label:
		name_label.text = current_npc_name
	
	if dialogue_label:
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
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("end_dialogue"):
		game_manager.end_dialogue()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("player_interact") or event.is_action_pressed("ui_accept"):
		if not dialogue_queue.is_empty():
			next_line()
			get_viewport().set_input_as_handled()
