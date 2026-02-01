class_name Item
extends Resource

@export var item_name = "Basic Item"
@export_multiline var item_desc = "This is a basic item!"
@export var item_icon: Texture2D
@export var max_stack_size = 64
@export var is_stackable = true

@export var is_medicine: bool = false
@export var cures_diseases: Array[String] = []
@export var healing_amount: int = 0
@export var cure_success_rate: float = 1.0

func use(user: Node) -> bool:
	print("%s used %s" % [user.name, item_name])
	
	if is_medicine:
		return false
	
	return false
