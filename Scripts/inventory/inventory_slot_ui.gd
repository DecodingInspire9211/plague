# res://scripts/ui/inventory_slot_ui.gd
extends PanelContainer

@onready var item_icon: TextureRect = $MarginContainer/VBoxContainer/ItemIcon
@onready var quantity_label: Label = $MarginContainer/VBoxContainer/QuantityLabel

var slot_index: int = -1
var slot_data: InventorySlot = null


func set_slot_data(data: InventorySlot, index: int) -> void:
	slot_data = data
	slot_index = index
	update_display()


func update_display() -> void:
	if slot_data == null or slot_data.is_empty():
		# Empty slot
		item_icon.texture = null
		quantity_label.text = ""
		modulate = Color(1, 1, 1, 0.3)  # Dim empty slots
	else:
		item_icon.texture = slot_data.item.item_icon
		
		# Show quantity if stackable and more than 1
		if slot_data.item.is_stackable and slot_data.quantity > 1:
			quantity_label.text = str(slot_data.quantity)
		else:
			quantity_label.text = ""
		
		modulate = Color(1, 1, 1, 1)  # Full brightness


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_slot_clicked()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_slot_right_clicked()


func _on_slot_clicked() -> void:
	if slot_data and not slot_data.is_empty():
		print("Clicked slot %d: %s" % [slot_index, slot_data.item.item_name])
		# Here you can add drag/drop or item selection logic


func _on_slot_right_clicked() -> void:
	if slot_data and not slot_data.is_empty():
		print("Right-clicked slot %d: Using %s" % [slot_index, slot_data.item.item_name])
		# Get the inventory and use the item
		var inventory_ui = get_parent().get_parent().get_parent().get_parent()
		if inventory_ui and inventory_ui.has_method("use_item_at_slot"):
			inventory_ui.use_item_at_slot(slot_index)
