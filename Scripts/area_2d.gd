extends Area2D

@export var target_scene: String = "res://Scenes/tavern.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Option A: group check (recommended)
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(target_scene)

	# Option B: type check (if your player is CharacterBody2D)
	# if body is CharacterBody2D:
	#     get_tree().change_scene_to_file(target_scene)
