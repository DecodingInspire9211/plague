# shop_item.gd
class_name ShopItem
extends Resource

@export var item: Item
@export var price: int = 10
@export var stock: int = -1 # -1 means infinite stock
@export var is_available: bool = true


func can_purchase(quantity: int = 1) -> bool:
	if not is_available:
		return false
	if stock == -1:
		return true
	return stock >= quantity


func purchase(quantity: int = 1) -> bool:
	if not can_purchase(quantity):
		return false
	
	if stock > 0:
		stock -= quantity
	
	return true


func restock(amount: int) -> void:
	if stock >= 0:
		stock += amount
