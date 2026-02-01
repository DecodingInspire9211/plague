# player.gd
extends CharacterBody2D

const WALK := 100.0
const RUN := 200.0
var SPEED := WALK

@export var interaction_range := 50.0

@onready var interaction_raycast: RayCast2D = $InteractionRaycast
@onready var inventory: Inventory = $Inventory
@onready var inventory_ui = $UILayer/InventoryUI
@onready var hotbar_ui = $UILayer/HotbarUI
@onready var dialogue_ui = $UILayer/DialogueUI

var last_direction := Vector2.DOWN
var current_interactable: Interactable = null


func _ready():
	SPEED = WALK
	setup_raycast()
	call_deferred("_setup_ui")


func _setup_ui() -> void:
	inventory_ui.set_inventory(inventory)
	hotbar_ui.set_inventory(inventory)
	add_to_group("player")
	_add_starting_items()


func _add_starting_items() -> void:
	var plague_cure = load("res://Data/plague_cure.tres")
	if plague_cure:
		inventory.add_item(plague_cure, 3)
		print("Added Plague Cure x3 to inventory")


func _physics_process(_delta: float) -> void:
	process_sprint()
	process_input()
	move_and_slide()
	update_raycast_direction()
	check_for_interactable()


func _unhandled_input(event):
	if event.is_action_pressed("player_interact"):
		attempt_interaction()


func process_sprint() -> void:
	SPEED = RUN if Input.is_action_pressed("player_run") else WALK


func process_input() -> void:
	var input_direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	velocity = input_direction * SPEED

	if input_direction.length_squared() > 0:
		last_direction = input_direction.normalized()


func setup_raycast() -> void:
	if interaction_raycast:
		interaction_raycast.enabled = true
		interaction_raycast.target_position = last_direction * interaction_range


func update_raycast_direction() -> void:
	if interaction_raycast and velocity.length_squared() > 0:
		var new_target := last_direction * interaction_range
		if interaction_raycast.target_position != new_target:
			interaction_raycast.target_position = new_target


func check_for_interactable() -> void:
	if not interaction_raycast:
		return

	var new_interactable: Interactable = null

	if interaction_raycast.is_colliding():
		var collider := interaction_raycast.get_collider()

		if collider is Interactable:
			new_interactable = collider
		elif collider.has_meta("interactable"):
			new_interactable = collider.get_meta("interactable")
		elif collider.get_parent() is Interactable:
			new_interactable = collider.get_parent()

	# Update when facing different interactable
	if new_interactable != current_interactable:
		# Hide old prompt
		if current_interactable:
			current_interactable.interaction_unavailable.emit()

		# Show new prompt
		current_interactable = new_interactable
		if current_interactable:
			current_interactable.interaction_available.emit()


func attempt_interaction() -> void:
	if current_interactable and current_interactable.is_interactable:
		current_interactable.interact(self)


# --- Added helper for NPCs to access the player inventory safely ---
func get_inventory() -> Inventory:
	return inventory
