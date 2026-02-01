extends Control

@onready var slot_container: HBoxContainer = $Panel/MarginContainer/HBoxContainer

var inventory: Inventory = null
var slot_ui_scene = preload("res://Scripts/inventory/inventory_slot_ui.tscn")
var hotbar_slots: Array = []
var hotbar_size: int = 5

const HOTBAR_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_hotbar_slots()


func _create_hotbar_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	hotbar_slots.clear()

	hotbar_slots.resize(hotbar_size)
	for i in hotbar_size:
		var slot_ui := slot_ui_scene.instantiate()
		slot_container.add_child(slot_ui)
		hotbar_slots[i] = slot_ui

		slot_ui.custom_minimum_size = Vector2(36, 36)
		slot_ui.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func set_inventory(inv: Inventory) -> void:
	inventory = inv
	
	if hotbar_slots.is_empty() and slot_container:
		_create_hotbar_slots()
	
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
		_on_inventory_changed()


func _on_inventory_changed() -> void:
	# Update hotbar slots to show first 5 inventory slots
	if not inventory:
		return
	
	var slots := inventory.get_all_slots()
	for i in hotbar_size:
		if i < slots.size():
			var slot_data = slots[i]
			if hotbar_slots[i]:
				hotbar_slots[i].set_slot_data(slot_data, i)


func _input(event: InputEvent) -> void:
	if not inventory:
		return
	
	# Check for hotbar key presses (1-5)
	if event is InputEventKey and event.pressed and not event.echo:
		for i in HOTBAR_KEYS.size():
			if event.keycode == HOTBAR_KEYS[i]:
				_use_hotbar_slot(i)
				get_viewport().set_input_as_handled()
				break


func _use_hotbar_slot(hotbar_idx: int) -> void:
	if hotbar_idx < 0 or hotbar_idx >= hotbar_size:
		return
	
	# Use item directly from inventory at this slot index
	if inventory:
		inventory.use_item(hotbar_idx)
		_flash_slot(hotbar_idx)


func _flash_slot(hotbar_idx: int) -> void:
	if hotbar_idx < 0 or hotbar_idx >= hotbar_slots.size():
		return
	
	var slot = hotbar_slots[hotbar_idx]
	if not slot:
		return
	
	# Quick flash animation
	var tween := create_tween()
	tween.tween_property(slot, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	tween.tween_property(slot, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
