# player.gd
extends CharacterBody2D

const WALK := 100.0
const RUN := 200.0
var SPEED := WALK

@export var interaction_range := 50.0

@onready var interaction_raycast: RayCast2D = $InteractionRaycast
@onready var inventory: Inventory = $Inventory
@onready var inventory_ui = $UILayer/InventoryUI

var last_direction := Vector2.DOWN
var current_interactable: Interactable = null

func _ready():
	SPEED = WALK
	setup_raycast()
	
	# Connect UI to inventory
	inventory_ui.set_inventory(inventory)
	
	test_inventory()

func test_inventory():
	# Load the items we created
	var health_potion = load("res://Data/test.tres")
	
	# Add items to inventory
	inventory.add_item(health_potion, 5)
	
	print("Inventory test:")
	print("- Health Potions: %d" % inventory.get_item_count(health_potion))


func _physics_process(delta):
	process_sprint()
	process_input()
	move_and_slide()
	update_raycast_direction()
	check_for_interactable()


func _unhandled_input(event):
	if event.is_action_pressed("player_interact"):
		attempt_interaction()


func process_sprint():
	if Input.is_action_pressed("player_run"):
		SPEED = RUN
	else:
		SPEED = WALK


func process_input():
	var input_direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	velocity = input_direction * SPEED
	
	if input_direction.length() > 0:
		last_direction = input_direction.normalized()


func setup_raycast():
	if interaction_raycast:
		interaction_raycast.enabled = true
		interaction_raycast.target_position = last_direction * interaction_range


func update_raycast_direction():
	if interaction_raycast:
		interaction_raycast.target_position = last_direction * interaction_range


func check_for_interactable():
	if not interaction_raycast:
		return
	
	interaction_raycast.force_raycast_update()
	
	var new_interactable: Interactable = null
	
	if interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		
		print("Raycast hit: %s" % collider.name)  # DEBUG
		
		if collider is Interactable:
			new_interactable = collider
			print("Collider is Interactable!")  # DEBUG
		elif collider.has_meta("interactable"):
			new_interactable = collider.get_meta("interactable")
			print("Collider has interactable meta!")  # DEBUG
		elif collider.get_parent() is Interactable:
			new_interactable = collider.get_parent()
			print("Collider's parent is Interactable!")  # DEBUG
	
	# Update when facing different interactable
	if new_interactable != current_interactable:
		print("Interactable changed!")  # DEBUG
		
		# Hide old prompt
		if current_interactable:
			print("Hiding old prompt")  # DEBUG
			current_interactable.interaction_unavailable.emit()
		
		# Show new prompt
		current_interactable = new_interactable
		if current_interactable:
			print("Showing new prompt for: %s" % current_interactable.display_name)  # DEBUG
			current_interactable.interaction_available.emit()


func attempt_interaction():
	if current_interactable and current_interactable.is_interactable:
		current_interactable.interact(self)
		print("Interacting with: %s" % current_interactable.display_name)
