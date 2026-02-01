extends NPC

const SHOP_UI_SCENE = preload("res://Scripts/inventory/shop_ui.tscn")

@export var shop_items: Array[ShopItem] = []
@export var shop_title: String = "Evelyn's Shop"

var shop_ui_instance: CanvasLayer = null


func _on_interact(_interactor: Node) -> void:
	# Don't show normal dialogue, open shop instead
	if not shop_items.is_empty():
		open_shop()
	else:
		super._on_interact(_interactor)


func open_shop() -> void:
	# Check if shop UI instance already exists
	if shop_ui_instance and is_instance_valid(shop_ui_instance):
		shop_ui_instance.open_shop(shop_items, shop_title)
		return
	
	# Create new shop UI instance
	shop_ui_instance = SHOP_UI_SCENE.instantiate()
	get_tree().root.add_child(shop_ui_instance)
	shop_ui_instance.open_shop(shop_items, shop_title)
	
	# Connect close signal to clean up
	if shop_ui_instance.has_signal("shop_closed"):
		shop_ui_instance.shop_closed.connect(_on_shop_closed)


func _on_shop_closed() -> void:
	# Optional: cleanup or additional logic when shop closes
	pass
