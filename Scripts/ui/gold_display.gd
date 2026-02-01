extends Control

@onready var gold_label: Label = $Panel/MarginContainer/GoldLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Debug checks
	if not gold_label:
		print("GoldDisplay: ERROR - gold_label is null!")
		return
		
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		print("GoldDisplay: GameManager found, gold = %d" % game_manager.get_gold())
	else:
		print("GoldDisplay: ERROR - GameManager not found!")
		
	_update_gold_display()


func _process(_delta: float) -> void:
	_update_gold_display()


func _update_gold_display() -> void:
	if not gold_label:
		return
		
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		gold_label.text = "%d Guilders" % game_manager.get_gold()
	else:
		gold_label.text = "0 Guilders"
