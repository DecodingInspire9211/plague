class_name InventorySlot
extends RefCounted

var item: Item = null
var quantity: int = 0


func is_empty() -> bool:
	return item == null or quantity <= 0


func clear() -> void:
	item = null
	quantity = 0


func can_add(new_item: Item, amount: int) -> bool:
	if is_empty():
		return true
	if item == new_item and item.is_stackable:
		return quantity + amount <= item.max_stack_size
	return false
