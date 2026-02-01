extends NPC

@export var wander_radius: float = 100.0
@export var wander_speed: float = 30.0
@export var peasant_frames: SpriteFrames
@export var peasant_pngs: Array[Texture2D] = []
@export var idle_fps: float = 4.0

# Drag plague_cure.tres here
@export var required_medicine: Item

# OPTIONAL: if you actually want him to start sick, set these
@export var start_sick_on_ready: bool = false
@export var starting_disease: Disease

var home_position: Vector2
var wander_target: Vector2
var is_wandering: bool = true


func _ready() -> void:
	super._ready()
	home_position = global_position

	if peasant_pngs.size() > 0:
		var frames := SpriteFrames.new()
		frames.add_animation("idle")
		frames.set_animation_speed("idle", idle_fps)
		for png in peasant_pngs:
			frames.add_frame("idle", png)
		$AnimatedSprite2D.sprite_frames = frames
		$AnimatedSprite2D.play("idle")

	# If you want him to start sick, you MUST actually infect him
	if start_sick_on_ready and starting_disease:
		infect(starting_disease)


func _on_interact(interactor: Node) -> void:
	is_wandering = false

	# Get inventory from player
	var inv: Inventory = null
	if interactor and interactor.has_method("get_inventory"):
		inv = interactor.get_inventory()

	# If already cured, just thank
	if is_cured:
		_show_dialogue_lines_custom(["Thank you again!! I feel much better now."])
		await get_tree().create_timer(1.0).timeout
		is_wandering = true
		return

	# If the player has the medicine, ALWAYS offer the choice
	if inv and required_medicine and inv.has_item(required_medicine, 1):
		var dialogue_ui: Control = _find_dialogue_ui()
		if dialogue_ui and dialogue_ui.has_method("show_choice"):
			# You can vary the question depending on sick/not sick
			var prompt := "*cough* Please... do you have any medicine?" if is_sick else "You have medicine. Do you want to give it to me?"

			var opts: Array[String] = ["Give medicine", "Not right now"]
			dialogue_ui.show_choice(display_name, prompt, opts)

			var choice_index: int = await dialogue_ui.choice_made

			if choice_index == 0:
				# Player chose to give medicine
				if is_sick:
					# Try apply first, consume only if it actually applied
					var applied := apply_medicine(required_medicine)

					if applied:
						inv.remove_item(required_medicine, 1)

					# If cured:
					if applied and is_cured and (not is_sick):
						_show_dialogue_lines_custom(["*takes the medicine*", "Thank you!! I'm cured!"])
					elif applied:
						_show_dialogue_lines_custom(["*takes the medicine*", "Thank you... I hope this works..."])
					else:
						_show_dialogue_lines_custom(["This doesn't seem to help..."])
				else:
					# Not sick: don't consume
					_show_dialogue_lines_custom(["Oh! I'm not sick, but thank you for offering."])

			else:
				_show_dialogue_lines_custom(["Alright... let me know if you change your mind."])

			await get_tree().create_timer(1.0).timeout
			is_wandering = true
			return

	# If player doesn't have medicine and peasant is sick, say that
	if is_sick:
		_show_dialogue_lines_custom(["*cough* I feel awful...", "If you find medicine, please bring it to me!"])
		await get_tree().create_timer(1.0).timeout
		is_wandering = true
		return

	# Otherwise fall back to normal dialogue lines ("YUM" etc.)
	super._on_interact(interactor)

	await get_tree().create_timer(3.0).timeout
	is_wandering = true


func _show_dialogue_lines_custom(lines: Array[String]) -> void:
	var dialogue_ui = _find_dialogue_ui()
	if dialogue_ui and dialogue_ui.has_method("show_dialogue_lines"):
		dialogue_ui.show_dialogue_lines(display_name, lines)
