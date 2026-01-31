class_name Item
extends Resource

@export var item_name = "Basic Item"
@export_multiline var item_desc = "This is a basic item!"
@export var item_icon: Texture2D
@export var max_stack_size = 64
@export var is_stackable = true

func use(user: Node) -> bool:
	print("%s used %s" % [user.name, item_name])
	return false
