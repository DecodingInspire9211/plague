extends Control

@onready var gold_label: Label = $Panel/MarginContainer/HBoxContainer/GoldLabel
@onready var coin_icon: Label = $Panel/MarginContainer/HBoxContainer/CoinIcon

var game_manager: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Cache GameManager reference
	game_manager = get_node_or_null("/root/GameManager")

	if not game_manager:
		push_error("GoldDisplay: GameManager not found!")
		return

	if not gold_label:
		push_error("GoldDisplay: gold_label is null!")
		return

	# Connect to gold changed signal
	if game_manager.has_signal("gold_changed"):
		game_manager.gold_changed.connect(_on_gold_changed)

	# Initial update
	_update_gold_display(game_manager.get_gold())

	# Add subtle animation to coin icon
	_animate_coin_icon()


func _on_gold_changed(new_amount: int) -> void:
	_update_gold_display(new_amount)
	_animate_coin_icon()


func _update_gold_display(amount: int) -> void:
	if not gold_label:
		return

	# Format number with commas for thousands
	var formatted_amount := _format_number(amount)
	gold_label.text = "%s Guilders" % formatted_amount


func _format_number(num: int) -> String:
	var str_num := str(num)
	var result := ""
	var count := 0

	# Add commas every 3 digits from right to left
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1

	return result


func _animate_coin_icon() -> void:
	if not coin_icon:
		return

	# Create a subtle pulse animation
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# Pulse scale
	coin_icon.scale = Vector2(1.3, 1.3)
	tween.tween_property(coin_icon, "scale", Vector2(1.0, 1.0), 0.5)

