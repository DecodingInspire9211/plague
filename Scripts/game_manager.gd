# game_manager.gd
# Autoload singleton for managing global game state and references
extends Node

# Signals for game-wide events
signal game_paused
signal game_resumed
signal player_died
signal npc_died(npc: Node, npc_name: String)
signal item_collected(item: Item, quantity: int)
signal dialogue_started(npc_name: String)
signal dialogue_ended
signal scene_changing(scene_path: String)
signal scene_changed

# Game state
enum GameState {
	PLAYING,
	PAUSED,
	IN_MENU,
	IN_DIALOGUE,
	LOADING
}

var current_state: GameState = GameState.PLAYING

# Core references
var player: CharacterBody2D = null
var current_scene: Node = null

# Game currency
var player_gold: int = 100 # Starting gold

# Settings
var is_paused: bool = false


func _ready() -> void:
	# Automatically find player in scene
	call_deferred("_find_player")
	current_scene = get_tree().current_scene


func _find_player() -> void:
	# Search for player node in the scene tree
	player = _find_node_by_type(get_tree().root, "CharacterBody2D", "player")
	if player:
		print("GameManager: Player found - %s" % player.name)
	else:
		push_warning("GameManager: Player not found in scene")


func _find_node_by_type(node: Node, type: String, name_hint: String = "") -> Node:
	# Check if this node matches
	if node.is_class(type) or node.get_script():
		if name_hint.is_empty() or node.name.to_lower().contains(name_hint.to_lower()):
			return node
	
	# Recursively search children
	for child in node.get_children():
		var result := _find_node_by_type(child, type, name_hint)
		if result:
			return result
	
	return null


# Game state management
func pause_game() -> void:
	if is_paused:
		return
	
	is_paused = true
	get_tree().paused = true
	current_state = GameState.PAUSED
	game_paused.emit()


func resume_game() -> void:
	if not is_paused:
		return
	
	is_paused = false
	get_tree().paused = false
	current_state = GameState.PLAYING
	game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# Scene management
func change_scene(scene_path: String) -> void:
	current_state = GameState.LOADING
	scene_changing.emit(scene_path)
	
	get_tree().call_deferred("change_scene_to_file", scene_path)
	await get_tree().tree_changed
	
	current_scene = get_tree().current_scene
	call_deferred("_find_player")
	current_state = GameState.PLAYING
	scene_changed.emit()


# Convenience methods
func get_player() -> CharacterBody2D:
	if not player:
		_find_player()
	return player


func get_player_inventory() -> Inventory:
	if player and player.has_node("Inventory"):
		return player.get_node("Inventory")
	return null


func is_player_valid() -> bool:
	return player != null and is_instance_valid(player)


# Dialogue state
func start_dialogue(npc_name: String) -> void:
	current_state = GameState.IN_DIALOGUE
	dialogue_started.emit(npc_name)


func end_dialogue() -> void:
	current_state = GameState.PLAYING
	dialogue_ended.emit()


# Item collection
func collect_item(item: Item, quantity: int) -> void:
	item_collected.emit(item, quantity)


# Currency management
func add_gold(amount: int) -> void:
	player_gold += amount
	print("Gold: %d (+%d)" % [player_gold, amount])


func remove_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		print("Gold: %d (-%d)" % [player_gold, amount])
		return true
	return false


func has_gold(amount: int) -> bool:
	return player_gold >= amount


func get_gold() -> int:
	return player_gold


# Death handling
func notify_player_death() -> void:
	player_died.emit()


func notify_npc_death(npc: Node, npc_name: String) -> void:
	npc_died.emit(npc, npc_name)
