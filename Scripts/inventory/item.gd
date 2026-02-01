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
		# Try to apply medicine to the current interactable NPC
		var target_npc: NPC = null

		# Check if the user (player) has a current_interactable
		if user.has("current_interactable") and user.current_interactable:
			if user.current_interactable is NPC:
				target_npc = user.current_interactable

		if target_npc:
			var success = target_npc.apply_medicine(self)
			return success  # Consume the item if successfully applied
		else:
			print("No NPC to apply medicine to!")
			return false

	return false
