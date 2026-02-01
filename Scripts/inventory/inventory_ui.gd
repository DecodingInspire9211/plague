# res://scripts/ui/inventory_ui.gd
extends Control

@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ItemGrid

var inventory: Inventory = null
var slot_ui_scene = preload("res://Scripts/inventory/inventory_slot_ui.tscn")
var slot_uis: Array = []
var dragged_slot_index: int = -1
var _is_dragging: bool = false

# Tooltip and drag preview (create these nodes if needed)
var tooltip: PanelContainer = null
var drag_preview: TextureRect = null


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.hide()
		tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	drag_preview = get_node_or_null("DragPreview")
	if not drag_preview:
		drag_preview = TextureRect.new()
		drag_preview.name = "DragPreview"
		add_child(drag_preview)
	
	drag_preview.hide()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.custom_minimum_size = Vector2(32, 32)
	drag_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.z_index = 100


func _process(_delta: float) -> void:
	if _is_dragging and drag_preview and drag_preview.visible:
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2


func set_inventory(inv: Inventory) -> void:
	inventory = inv
	
	# Connect to inventory signals
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Create slot UIs
	_create_slot_uis()
	
	# Initial update
	_on_inventory_changed()


func _create_slot_uis() -> void:
	# Clear existing slots
	for child in item_grid.get_children():
		child.queue_free()
	slot_uis.clear()
	
	# Pre-allocate array size
	slot_uis.resize(inventory.max_slots)
	
	# Create a slot UI for each inventory slot
	for i in inventory.max_slots:
		var slot_ui := slot_ui_scene.instantiate()
		item_grid.add_child(slot_ui)
		slot_uis[i] = slot_ui


func _on_inventory_changed() -> void:
	# Update all slot UIs (batched)
	var slots := inventory.get_all_slots()
	var slot_count: int = min(slots.size(), slot_uis.size())
	for i in slot_count:
		if slot_uis[i]:
			slot_uis[i].set_slot_data(slots[i], i)


func use_item_at_slot(slot_index: int) -> void:
	if inventory:
		inventory.use_item(slot_index)


func start_drag(slot_index: int) -> void:
	if not inventory:
		return
	
	var item := inventory.get_item_at(slot_index)
	if not item:
		return
	
	_is_dragging = true
	dragged_slot_index = slot_index
	
	if drag_preview:
		drag_preview.texture = item.item_icon
		drag_preview.modulate = Color(1, 1, 1, 0.8)
		drag_preview.size = Vector2(32, 32)
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2
		drag_preview.show()


func is_dragging() -> bool:
	return _is_dragging


func end_drag(drop_slot_index: int) -> void:
	if not _is_dragging or dragged_slot_index == -1:
		return
	
	if drag_preview:
		drag_preview.hide()
	
	if dragged_slot_index != drop_slot_index:
		# Swap or stack items
		if inventory.has_method("swap_slots"):
			inventory.swap_slots(dragged_slot_index, drop_slot_index)
	
	_is_dragging = false
	dragged_slot_index = -1


func update_drag_preview(global_pos: Vector2) -> void:
	if drag_preview and _is_dragging:
		drag_preview.global_position = global_pos - drag_preview.size / 2


func show_tooltip(item: Item, slot_position: Vector2) -> void:
	if not tooltip or not item:
		return
	
	var tooltip_title := tooltip.get_node_or_null("MarginContainer/VBoxContainer/Title") as Label
	var tooltip_desc := tooltip.get_node_or_null("MarginContainer/VBoxContainer/Description") as Label
	
	if tooltip_title:
		tooltip_title.text = item.item_name
	
	if tooltip_desc:
		tooltip_desc.text = item.item_desc
	
	# Position tooltip near slot
	tooltip.global_position = slot_position + Vector2(80, 0)
	tooltip.show()


func hide_tooltip() -> void:
	if tooltip:
		tooltip.hide()


func split_stack(slot_index: int) -> void:
	if not inventory or not inventory.has_method("split_stack"):
		return
	
	inventory.split_stack(slot_index)


func drop_item_from_slot(slot_index: int, quantity: int) -> void:
	if not inventory:
		return
	
	var item := inventory.get_item_at(slot_index)
	if item:
		inventory.remove_item(item, quantity)
		print("Dropped %d x %s" % [quantity, item.item_name])


func toggle_visibility() -> void:
	visible = not visible


func _input(event: InputEvent) -> void:
	# Handle global mouse release for drag and drop
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _is_dragging:
			# Find which slot we're over
			var mouse_pos := get_global_mouse_position()
			var drop_slot := _get_slot_at_position(mouse_pos)
			if drop_slot != -1:
				end_drag(drop_slot)
			else:
				# Cancel drag if released outside inventory
				cancel_drag()
	
	# Toggle inventory with 'I' key or Tab
	if event.is_action_pressed("ui_cancel"): # ESC key
		if visible:
			hide()
	
	# Add a custom action for opening inventory
	if event.is_action_pressed("player_inv"): # You'll need to create this
		toggle_visibility()


func _get_slot_at_position(global_pos: Vector2) -> int:
	# Early return if not visible or no slots
	if not visible or slot_uis.is_empty():
		return -1
	
	for i in range(slot_uis.size()):
		if slot_uis[i] and slot_uis[i].get_global_rect().has_point(global_pos):
			return i
	return -1


func cancel_drag() -> void:
	_is_dragging = false
	dragged_slot_index = -1
	if drag_preview:
		drag_preview.hide()
