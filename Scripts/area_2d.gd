extends Area2D

@export_file("*.tscn") var goal: String
@export var use_spawn_position: bool = false
@export var spawn_position: Vector2 = Vector2.ZERO

var changing := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if changing:
		return
	if !body.is_in_group("player"):
		return
	if goal.is_empty():
		push_warning("Area2D: No goal scene set!")
		return

	changing = true
	GameManager.change_scene(goal, spawn_position, use_spawn_position)
