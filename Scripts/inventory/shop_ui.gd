# shop_ui.gd
extends CanvasLayer

signal item_purchased(item: Item, quantity: int, total_cost: int)
signal shop_closed

@onready var shop_title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var item_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var shop_items: Array[ShopItem] = []
var shop_name: String = "Shop"


func _ready() -> void:
	hide()
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("player_interact") or event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()


func open_shop(items: Array[ShopItem], title: String = "Shop") -> void:
	shop_items = items
	shop_name = title
	
	if shop_title:
		shop_title.text = title
	
	_refresh_shop()
	show()
	
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").current_state = get_node("/root/GameManager").GameState.IN_MENU


func _refresh_shop() -> void:
	if item_list:
		for child in item_list.get_children():
			child.queue_free()
	
	for shop_item in shop_items:
		if shop_item.is_available:
			_create_item_entry(shop_item)


func _create_item_entry(shop_item: ShopItem) -> void:
	var entry := HBoxContainer.new()
	entry.size_flags_horizontal = Control.SIZE_FILL
	entry.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	# Item icon
	if shop_item.item.item_icon:
		var icon := TextureRect.new()
		icon.texture = shop_item.item.item_icon
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		entry.add_child(icon)
	
	# Item name and description
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label := Label.new()
	name_label.text = shop_item.item.item_name
	info.add_child(name_label)
	
	var desc_label := Label.new()
	desc_label.text = shop_item.item.item_desc
	desc_label.add_theme_font_size_override("font_size", 8)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(desc_label)
	
	entry.add_child(info)
	
	# Stock display
	if shop_item.stock >= 0:
		var stock_label := Label.new()
		stock_label.text = "x%d" % shop_item.stock
		stock_label.custom_minimum_size = Vector2(40, 0)
		stock_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		entry.add_child(stock_label)

	# Price and buy button
	var price_label := Label.new()
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.text = "%d Guilders" % shop_item.price
	price_label.custom_minimum_size = Vector2(60, 0)
	price_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	entry.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(50, 0)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	buy_button.pressed.connect(_on_buy_pressed.bind(shop_item))
	entry.add_child(buy_button)
	
	item_list.add_child(entry)


func _on_buy_pressed(shop_item: ShopItem) -> void:
	if not shop_item.can_purchase(1):
		print("Item not available!")
		return
	
	# Check if player has enough gold
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.has_gold(shop_item.price):
		print("Not enough gold!")
		return
	
	# Check inventory space
	var inventory = game_manager.get_player_inventory()
	if not inventory:
		print("No inventory!")
		return
	
	# Process purchase
	if game_manager.remove_gold(shop_item.price):
		if shop_item.purchase(1):
			if inventory.add_item(shop_item.item, 1):
				print("Purchased %s for %d gold!" % [shop_item.item.item_name, shop_item.price])
				item_purchased.emit(shop_item.item, 1, shop_item.price)
				_refresh_shop()
			else:
				# Refund if inventory full
				game_manager.add_gold(shop_item.price)
				shop_item.restock(1)
				print("Inventory full!")


func _on_close_pressed() -> void:
	close_shop()


func close_shop() -> void:
	hide()
	shop_closed.emit()
	
	# Resume game
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.current_state = gm.GameState.PLAYING
