# res://scripts/ui/inventory_ui.gd
extends Control

@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ItemGrid

var inventory: Inventory = null
var slot_ui_scene = preload("res://Scripts/inventory/inventory_slot_ui.tscn")
var slot_uis: Array = []


func _ready() -> void:
	hide()  # Hidden by default


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
	
	# Create a slot UI for each inventory slot
	for i in range(inventory.max_slots):
		var slot_ui = slot_ui_scene.instantiate()
		item_grid.add_child(slot_ui)
		slot_uis.append(slot_ui)


func _on_inventory_changed() -> void:
	# Update all slot UIs
	var slots = inventory.get_all_slots()
	for i in range(slots.size()):
		if i < slot_uis.size():
			slot_uis[i].set_slot_data(slots[i], i)


func use_item_at_slot(slot_index: int) -> void:
	if inventory:
		inventory.use_item(slot_index)


func toggle_visibility() -> void:
	visible = not visible


func _input(event: InputEvent) -> void:
	# Toggle inventory with 'I' key or Tab
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if visible:
			hide()
	
	# Add a custom action for opening inventory
	if event.is_action_pressed("player_inv"):  # You'll need to create this
		toggle_visibility()
