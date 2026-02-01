extends NPC

const SHOP_UI_SCENE = preload("res://Scripts/inventory/shop_ui.tscn")

@export var shop_items: Array[ShopItem] = []
@export var shop_title: String = "Evelyn's Shop"
@export_group("Random Inventory")
@export var randomize_items: bool = true
@export var randomize_interval: float = 60.0 # Seconds between randomization
@export var min_items_available: int = 2
@export var max_items_available: int = 3

var shop_ui_instance: CanvasLayer = null
var randomize_timer: Timer = null


func _ready() -> void:
	super._ready()
	
	# Duplicate shop items to avoid modifying the original resources
	var duplicated_items: Array[ShopItem] = []
	for item in shop_items:
		duplicated_items.append(item.duplicate())
	shop_items = duplicated_items

	if randomize_items and not shop_items.is_empty():
		# Create and configure the randomize timer
		randomize_timer = Timer.new()
		randomize_timer.wait_time = randomize_interval
		randomize_timer.autostart = true
		randomize_timer.timeout.connect(_on_randomize_timer_timeout)
		add_child(randomize_timer)

		# Randomize items immediately at start
		_randomize_available_items()


func _randomize_available_items() -> void:
	if shop_items.is_empty():
		return

	# Clamp the number of items to be available
	var num_available = clampi(
		randi_range(min_items_available, max_items_available),
		1,
		shop_items.size()
	)

	# First, make all items unavailable
	for item in shop_items:
		item.is_available = false

	# Randomly select items to be available
	var available_indices: Array[int] = []
	while available_indices.size() < num_available:
		var random_index = randi() % shop_items.size()
		if random_index not in available_indices:
			available_indices.append(random_index)
			shop_items[random_index].is_available = true

	print("Evelyn's Shop: %d items available" % num_available)

	# Refresh the shop UI if it's currently open
	if shop_ui_instance and is_instance_valid(shop_ui_instance) and shop_ui_instance.visible:
		shop_ui_instance._refresh_shop()


func _on_randomize_timer_timeout() -> void:
	_randomize_available_items()


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
