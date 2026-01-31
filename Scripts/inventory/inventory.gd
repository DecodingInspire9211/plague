# res://scripts/inventory/inventory.gd
class_name Inventory
extends Node

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)
signal inventory_changed

@export var max_slots: int = 20

var items: Array[InventorySlot] = []


func _ready() -> void:
	# Initialize empty slots
	for i in range(max_slots):
		items.append(InventorySlot.new())


# Add item to inventory
func add_item(item: Item, quantity: int = 1) -> bool:
	if item == null:
		return false
	
	# If stackable, try to add to existing stack first
	if item.is_stackable:
		for slot in items:
			if slot.item == item and slot.quantity < item.max_stack_size:
				var space_left = item.max_stack_size - slot.quantity
				var amount_to_add = min(quantity, space_left)
				slot.quantity += amount_to_add
				quantity -= amount_to_add
				
				item_added.emit(item, amount_to_add)
				inventory_changed.emit()
				
				if quantity <= 0:
					return true
	
	# Add to empty slot
	while quantity > 0:
		var empty_slot = _get_empty_slot()
		if empty_slot == null:
			print("Inventory full!")
			return false
		
		empty_slot.item = item
		var amount_to_add = min(quantity, item.max_stack_size)
		empty_slot.quantity = amount_to_add
		quantity -= amount_to_add
		
		item_added.emit(item, amount_to_add)
		inventory_changed.emit()
	
	return true


# Remove item from inventory
func remove_item(item: Item, quantity: int = 1) -> bool:
	var remaining = quantity
	
	for slot in items:
		if slot.item == item:
			if slot.quantity >= remaining:
				slot.quantity -= remaining
				if slot.quantity == 0:
					slot.clear()
				
				item_removed.emit(item, remaining)
				inventory_changed.emit()
				return true
			else:
				remaining -= slot.quantity
				slot.clear()
	
	if remaining < quantity:
		item_removed.emit(item, quantity - remaining)
		inventory_changed.emit()
	
	return remaining == 0


# Use item at specific slot
func use_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= items.size():
		return
	
	var slot = items[slot_index]
	if slot.item == null:
		return
	
	# Call the item's use method
	var should_consume = slot.item.use(get_parent())  # Assumes inventory is child of player
	
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
	var total = 0
	for slot in items:
		if slot.item == item:
			total += slot.quantity
			if total >= quantity:
				return true
	return false


# Get total count of an item
func get_item_count(item: Item) -> int:
	var total = 0
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
