extends CharacterBody2D

const WALK := 100.0
const RUN := 200.0

var SPEED := WALK

func _ready():
	SPEED = WALK

func _physics_process(delta):
	process_sprint()
	process_input()
	move_and_slide()

func process_sprint():
	if Input.is_action_pressed("player_run"):
		SPEED = RUN
		#print("RUNNING")
	else:
		SPEED = WALK
		#print("WALKING")
		
func process_input():
	var input_direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	velocity = input_direction * SPEED
