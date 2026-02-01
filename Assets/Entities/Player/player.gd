# player.gd
extends CharacterBody2D

const WALK := 100.0
const RUN := 200.0
var SPEED := WALK

@export var interaction_range := 50.0

@onready var interaction_raycast: RayCast2D = $InteractionRaycast
@onready var inventory_ui = $UILayer/InventoryUI
@onready var hotbar_ui = $UILayer/HotbarUI
@onready var dialogue_ui = $UILayer/DialogueUI
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound

var inventory: Inventory = null  # Will be set from GameManager
var last_direction := Vector2.DOWN
var current_interactable: Interactable = null
var is_walking := false


func _ready():
	SPEED = WALK
	setup_raycast()
	call_deferred("_setup_ui")
	call_deferred("_apply_spawn_position")


func _apply_spawn_position() -> void:
	var root = get_tree().root
	if root.has_meta("player_spawn_position"):
		var pos = root.get_meta("player_spawn_position")
		if pos != null:
			global_position = pos
			root.remove_meta("player_spawn_position")


func _setup_ui() -> void:
	# Get inventory from GameManager
	if GameManager:
		inventory = GameManager.get_player_inventory()

	# Setup UI with the persistent inventory
	if inventory:
		inventory_ui.set_inventory(inventory)
		hotbar_ui.set_inventory(inventory)

	add_to_group("player")


func _physics_process(_delta: float) -> void:
	process_sprint()
	process_input()
	move_and_slide()
	update_raycast_direction()
	check_for_interactable()
	update_walk_sound()


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
		current_interactable.interact(self )


func update_walk_sound() -> void:
	var moving := velocity.length_squared() > 0
	
	if moving and not is_walking:
		if walk_sound and not walk_sound.playing:
			walk_sound.play()
		is_walking = true
	elif not moving and is_walking:
		if walk_sound:
			walk_sound.stop()
		is_walking = false
	
	# Adjust pitch based on speed
	if walk_sound and is_walking:
		walk_sound.pitch_scale = 1.5 if SPEED == RUN else 1.0

func get_inventory() -> Inventory:
	return inventory
