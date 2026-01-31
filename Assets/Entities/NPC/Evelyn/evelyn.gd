extends NPC

@export var items_for_sale: Array[String] = ["Potion", "Sword"]
@export var item_prices: Array[int] = [10, 50]

func _on_interact(interactor: Node) -> void:
	super._on_interact(interactor)  # Shows normal dialogue
	open_shop()

func open_shop() -> void:
	print("Shop opened! Items: %s" % str(items_for_sale))
