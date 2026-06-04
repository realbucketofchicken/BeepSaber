extends Node

signal score_changed()
signal points_awarded(position: Vector3, amount: String)

var points: int
var combo: int
var multiplier: int
var right_notes: float
var wrong_notes: float
var full_combo: bool
var paused: bool

func restart() -> void:
	points = 0
	multiplier = 1
	combo = 0
	right_notes = 0.0
	wrong_notes = 0.0
	full_combo = true
	score_changed.emit()

func reset_combo() -> void:
	multiplier = 1
	combo = 0
	wrong_notes += 1.0
	full_combo = false
	score_changed.emit()

func add_points(position: Vector3, amount: int) -> void:
	combo += 1
	@warning_ignore("integer_division")
	multiplier = 1 + mini(combo / 10, 7)
	points += amount * multiplier
	# track accuracy percent
	right_notes += 1
	score_changed.emit()
	points_awarded.emit(position, str(amount))

func chain_link_cut(position: Vector3) -> void:
	add_points(position, 20)

func note_cut(position: Vector3, cut_distance_accuracy: float, travel_distance_factor: float) -> void:# point computation based on the accuracy of the swing
	var points_new := 0.0
	points_new += cut_distance_accuracy * 5.0
	points_new += travel_distance_factor * 5.0
	
	points_new = roundf(points_new)
	add_points(position, int(points_new))

func on_miss(position: Vector3) -> void:
	reset_combo()
	points_awarded.emit(position, "MISS!")

func bad_cut(position: Vector3) -> void:
	reset_combo()
	points_awarded.emit(position, "x")
