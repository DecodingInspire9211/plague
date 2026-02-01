# disease.gd
class_name Disease
extends Resource

@export var disease_name: String = "Unknown Disease"
@export_multiline var description: String = "A mysterious ailment."
@export var damage_per_second: float = 1.0
@export var progression_time: float = 60.0 # Time to reach critical state
@export var is_fatal: bool = true
@export var visual_tint: Color = Color(0.8, 1, 0.8) # Slight green tint

# Symptoms shown to player
@export var symptoms: Array[String] = []

var time_infected: float = 0.0


func get_severity() -> float:
	# Returns 0.0 (mild) to 1.0 (critical)
	return clampf(time_infected / progression_time, 0.0, 1.0)


func get_severity_name() -> String:
	var severity := get_severity()
	if severity < 0.25:
		return "Mild"
	elif severity < 0.5:
		return "Moderate"
	elif severity < 0.75:
		return "Severe"
	else:
		return "Critical"


func progress(delta: float) -> void:
	time_infected += delta
