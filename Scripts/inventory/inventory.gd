# res://scripts/inventory/inventory.gd
class_name Inventory
extends Node

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)
signal inventory_changed

@export var max_slots: int = 20

var items: Array[InventorySlot] = []


func _ready() -> void:
	for i in range(max_slots):
		items.append(InventorySlot.new())


func add_item(item: Item, quantity: int = 1) -> bool:
	if item == null or quantity <= 0:
		return false
	
	var max_stack: int = item.max_stack_size
	var total_added := 0
	
	if item.is_stackable:
		for slot in items:
			if slot.item == item and slot.quantity < max_stack:
				var space_left := max_stack - slot.quantity
				var amount_to_add: int = min(quantity, space_left)
				slot.quantity += amount_to_add
				quantity -= amount_to_add
				total_added += amount_to_add
				
				if quantity <= 0:
					item_added.emit(item, total_added)
					inventory_changed.emit()
					return true
	
	while quantity > 0:
		var empty_slot := _get_empty_slot()
		if empty_slot == null:
			if total_added > 0:
				item_added.emit(item, total_added)
				inventory_changed.emit()
			return false
		
		empty_slot.item = item
		var amount_to_add: int = min(quantity, max_stack)
		empty_slot.quantity = amount_to_add
		quantity -= amount_to_add
		total_added += amount_to_add
	
	if total_added > 0:
		item_added.emit(item, total_added)
		inventory_changed.emit()
	
	return true


# Remove item from inventory
func remove_item(item: Item, quantity: int = 1) -> bool:
	var remaining := quantity
	var removed := 0
	
	for slot in items:
		if slot.item == item:
			var to_remove: int = min(slot.quantity, remaining)
			slot.quantity -= to_remove
			remaining -= to_remove
			removed += to_remove
			
			if slot.quantity == 0:
				slot.clear()
			
			if remaining == 0:
				break
	
	if removed > 0:
		item_removed.emit(item, removed)
		inventory_changed.emit()
	
	return remaining == 0


# Use item at specific slot
func use_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= items.size():
		return
	
	var slot = items[slot_index]
	if slot.item == null:
		return
	
	# Get player from GameManager if available, otherwise from parent
	var user: Node = null
	if has_node("/root/GameManager"):
		var game_manager := get_node("/root/GameManager")
		if game_manager.has_method("is_player_valid") and game_manager.is_player_valid():
			user = game_manager.get_player()
	if not user:
		user = get_parent()
	
	# Call the item's use method
	var should_consume = slot.item.use(user)
	
	if should_consume:
		remove_item(slot.item, 1)


# Get item at slot
func get_item_at(slot_index: int) -> Item:
	if slot_index < 0 or slot_index >= items.size():
		return null
	return items[slot_index].item


# Get quantity at slot
func get_quantity_at(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= items.size():
		return 0
	return items[slot_index].quantity


# Check if inventory has item
func has_item(item: Item, quantity: int = 1) -> bool:
	var total := 0
	for slot in items:
		if slot.item == item:
			total += slot.quantity
			if total >= quantity:
				return true
	return false


# Get total count of an item
func get_item_count(item: Item) -> int:
	var total := 0
	for slot in items:
		if slot.item == item:
			total += slot.quantity
	return total


# Get first empty slot
func _get_empty_slot() -> InventorySlot:
	for slot in items:
		if slot.is_empty():
			return slot
	return null


# Clear entire inventory
func clear() -> void:
	for slot in items:
		slot.clear()
	inventory_changed.emit()


# Get all items (for UI display)
func get_all_slots() -> Array[InventorySlot]:
	return items


# Swap items between two slots
func swap_slots(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= items.size() or to_index < 0 or to_index >= items.size():
		return
	
	var from_slot := items[from_index]
	var to_slot := items[to_index]
	
	# If both have the same stackable item, try to stack
	if not from_slot.is_empty() and not to_slot.is_empty():
		if from_slot.item == to_slot.item and from_slot.item.is_stackable:
			var max_stack: int = from_slot.item.max_stack_size
			var space_available := max_stack - to_slot.quantity
			
			if space_available > 0:
				var amount_to_transfer: int = min(from_slot.quantity, space_available)
				to_slot.quantity += amount_to_transfer
				from_slot.quantity -= amount_to_transfer
				
				if from_slot.quantity <= 0:
					from_slot.clear()
				
				inventory_changed.emit()
				return
	
	# Otherwise, swap the slots
	var temp_item := from_slot.item
	var temp_quantity := from_slot.quantity
	
	from_slot.item = to_slot.item
	from_slot.quantity = to_slot.quantity
	
	to_slot.item = temp_item
	to_slot.quantity = temp_quantity
	
	inventory_changed.emit()


# Split a stack in half
func split_stack(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= items.size():
		return
	
	var slot := items[slot_index]
	if slot.is_empty() or slot.quantity <= 1:
		return
	
	var empty_slot := _get_empty_slot()
	if not empty_slot:
		return
	
	var split_amount := roundi(slot.quantity / 2.0) # Split stack in half
	
	empty_slot.item = slot.item
	empty_slot.quantity = split_amount
	slot.quantity -= split_amount
	
	inventory_changed.emit()
