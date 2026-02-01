extends NPC # Already set by Godot

@export var wander_radius: float = 100.0
@export var wander_speed: float = 30.0

var home_position: Vector2
var wander_target: Vector2
var is_wandering: bool = true


func _ready() -> void:
	super._ready() # Calls NPC's _ready() which calls Interactable's _ready()
	home_position = global_position
	
#	_pick_new_wander_target()


#func _physics_process(delta: float) -> void:
	#if is_wandering:
	#	_process_wandering(delta)


func _process_wandering(delta: float) -> void:
	var to_target := wander_target - global_position
	
	# Use squared distance to avoid sqrt calculation
	if to_target.length_squared() < 25: # 5 * 5
		_pick_new_wander_target()
		return
	
	var direction := to_target.normalized()
	global_position += direction * wander_speed * delta
	
	if direction.x != 0:
		flip_sprite_h(direction.x < 0)


func _pick_new_wander_target() -> void:
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	wander_target = home_position + random_offset


func _on_interact(interactor: Node) -> void:
	is_wandering = false
	super._on_interact(interactor) # Calls NPC's interaction (shows dialogue)
	
	await get_tree().create_timer(3.0).timeout
	is_wandering = true
