extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var quantity_label: Label = $MarginContainer/VBoxContainer/QuantityLabel

var slot_index: int = -1
var slot_data: InventorySlot = null
var _inventory_ui: Control = null
var is_hovered: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

const HOVER_COLOR := Color(1.2, 1.2, 1.2, 1.0)
const NORMAL_COLOR := Color(1, 1, 1, 1)
const EMPTY_COLOR := Color(1, 1, 1, 0.3)
const DRAG_COLOR := Color(0.8, 0.8, 0.8, 0.7)


func _ready() -> void:
	var margin_container := get_node_or_null("MarginContainer")
	if margin_container:
		margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var vbox := margin_container.get_node_or_null("VBoxContainer")
		if vbox:
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if item_icon:
		item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if quantity_label:
		quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_slot_data(data: InventorySlot, index: int) -> void:
	slot_data = data
	slot_index = index
	update_display()


func update_display() -> void:
	if not slot_data or slot_data.is_empty():
		if item_icon and item_icon.texture != null:
			item_icon.texture = null
		if quantity_label and quantity_label.text != "":
			quantity_label.text = ""
		if not is_hovered and modulate != EMPTY_COLOR:
			modulate = EMPTY_COLOR
		return
	
	var icon := slot_data.item.item_icon
	if item_icon.texture != icon:
		item_icon.texture = icon
	
	var new_text := str(slot_data.quantity) if (slot_data.item.is_stackable and slot_data.quantity > 1) else ""
	if quantity_label.text != new_text:
		quantity_label.text = new_text
	
	if is_dragging:
		modulate = DRAG_COLOR
	elif is_hovered:
		modulate = HOVER_COLOR
	else:
		modulate = NORMAL_COLOR


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_slot_left_click_pressed(event)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				_on_slot_shift_right_clicked()
			else:
				_on_slot_right_clicked()


func _on_slot_left_click_pressed(_event: InputEventMouseButton) -> void:
	if not _inventory_ui:
		_inventory_ui = _find_inventory_ui()
	
	# If inventory UI not found, just return
	if not _inventory_ui:
		return
	
	# If not already dragging, start drag on this slot
	if not _inventory_ui.is_dragging() and slot_data and not slot_data.is_empty():
		if Input.is_key_pressed(KEY_SHIFT):
			# Split stack
			_split_stack()
		else:
			# Start drag
			is_dragging = true
			if _inventory_ui.has_method("start_drag"):
				_inventory_ui.start_drag(slot_index)
			update_display()


func _on_slot_left_click_released() -> void:
	# Clear local drag state
	if is_dragging:
		is_dragging = false
		update_display()
		update_display()


func _on_drag_motion(event: InputEventMouseMotion) -> void:
	if _inventory_ui and _inventory_ui.has_method("update_drag_preview"):
		_inventory_ui.update_drag_preview(event.global_position)


func _on_slot_right_clicked() -> void:
	if not slot_data or slot_data.is_empty():
		return
	
	if not _inventory_ui:
		_inventory_ui = _find_inventory_ui()
	
	if _inventory_ui and _inventory_ui.has_method("use_item_at_slot"):
		_inventory_ui.use_item_at_slot(slot_index)


func _on_slot_shift_right_clicked() -> void:
	# Drop single item
	if not slot_data or slot_data.is_empty():
		return
	
	if not _inventory_ui:
		_inventory_ui = _find_inventory_ui()
	
	if _inventory_ui and _inventory_ui.has_method("drop_item_from_slot"):
		_inventory_ui.drop_item_from_slot(slot_index, 1)


func _split_stack() -> void:
	if not slot_data or slot_data.is_empty() or slot_data.quantity <= 1:
		return
	
	if not _inventory_ui:
		_inventory_ui = _find_inventory_ui()
	
	if _inventory_ui and _inventory_ui.has_method("split_stack"):
		_inventory_ui.split_stack(slot_index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		is_hovered = true
		update_display()
		_show_tooltip()
	elif what == NOTIFICATION_MOUSE_EXIT:
		is_hovered = false
		update_display()
		_hide_tooltip()


func _show_tooltip() -> void:
	if not slot_data or slot_data.is_empty():
		return
	
	if not _inventory_ui:
		_inventory_ui = _find_inventory_ui()
	
	if _inventory_ui and _inventory_ui.has_method("show_tooltip"):
		_inventory_ui.show_tooltip(slot_data.item, global_position)


func _hide_tooltip() -> void:
	if not _inventory_ui:
		return
	
	if _inventory_ui.has_method("hide_tooltip"):
		_inventory_ui.hide_tooltip()


# Helper function to find the inventory UI in the parent hierarchy
func _find_inventory_ui() -> Control:
	# Try direct path first (optimization)
	var parent := get_parent()
	if not parent:
		return null
	
	var grandparent := parent.get_parent()
	if grandparent and grandparent.get_parent():
		var potential_ui := grandparent.get_parent()
		if potential_ui.has_method("start_drag") and potential_ui.has_method("end_drag"):
			return potential_ui
	
	# Fallback: search up the tree
	var current := parent
	var depth := 0
	while current and depth < 10: # Limit search depth
		if current.has_method("start_drag") and current.has_method("end_drag"):
			return current
		current = current.get_parent()
		depth += 1
	
	return null
