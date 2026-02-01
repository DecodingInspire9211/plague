# interactable.gd
class_name Interactable
extends Node2D

## Emitted when the object is interacted with
signal interacted(interactor: Node)
## Emitted when the object becomes interactable (player in range, etc.)
signal interaction_available
## Emitted when the object is no longer interactable
signal interaction_unavailable

@export var display_name: String = "Interactable"
@export var is_interactable: bool = true
@export var interaction_prompt: String = "Interact"

## Reference to the sprite node (AnimatedSprite2D or Sprite2D)
var sprite_node: Node = null


func _ready() -> void:
	_setup_sprite()
	_setup_collision()
	_on_ready()


## Virtual method to be overridden by child classes
func _on_ready() -> void:
	pass


## Sets up the sprite node - handles both AnimatedSprite2D and Sprite2D
func _setup_sprite() -> void:
	sprite_node = get_node_or_null("AnimatedSprite2D")
	if sprite_node:
		return
	
	sprite_node = get_node_or_null("Sprite2D")
	if sprite_node:
		return
	
	# Search children only if not found by name
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			sprite_node = child
			return


func _setup_collision() -> void:
	var collision_body := get_node_or_null("HitBox")
	if collision_body:
		collision_body.set_meta("interactable", self )


## Main interaction method - override this in child classes
func interact(interactor: Node) -> void:
	if not is_interactable:
		return
	
	interacted.emit(interactor)
	_on_interact(interactor)


## Virtual method to be overridden by child classes for custom interaction logic
func _on_interact(interactor: Node) -> void:
	print("%s interacted with by %s" % [display_name, interactor.name])


## Enable interaction
func enable_interaction() -> void:
	is_interactable = true
	interaction_available.emit()


## Disable interaction
func disable_interaction() -> void:
	is_interactable = false
	interaction_unavailable.emit()


## Helper method to play animation if using AnimatedSprite2D
func play_animation(animation_name: String) -> void:
	if sprite_node is AnimatedSprite2D:
		sprite_node.play(animation_name)
	else:
		push_warning("Cannot play animation - sprite is not AnimatedSprite2D")


## Helper method to stop animation if using AnimatedSprite2D
func stop_animation() -> void:
	if sprite_node is AnimatedSprite2D:
		sprite_node.stop()


## Helper method to set sprite texture (works for both types)
func set_sprite_texture(texture: Texture2D) -> void:
	if sprite_node is Sprite2D:
		sprite_node.texture = texture
	else:
		push_warning("Cannot set texture - sprite is not Sprite2D")


## Helper method to flip sprite horizontally
func flip_sprite_h(flip: bool) -> void:
	if sprite_node:
		sprite_node.flip_h = flip


## Helper method to flip sprite vertically
func flip_sprite_v(flip: bool) -> void:
	if sprite_node:
		sprite_node.flip_v = flip
