extends Area2D

@export var playground_scene := "res://Scenes/Playground.tscn"
@export var tavern_scene := "res://Scenes/tavern.tscn"

var changing := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if changing:
		return
	if !body.is_in_group("player"):
		return

	var current_path := get_tree().current_scene.scene_file_path

	# If we're in Tavern -> go to Playground, otherwise -> go to Tavern
	var next_scene := tavern_scene
	if current_path == tavern_scene:
		next_scene = playground_scene

	changing = true
	get_tree().change_scene_to_file(next_scene)
