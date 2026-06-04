extends PooledNode3D
class_name Cuttable

var speed: float
var beat: float
# the time the note lives
var real_time:float
var move_dir:Vector3 = transform.basis.z
# used to release the cube once both of it's cut pieces have died off
# Note: serves no purpose for bombs
var _piece_death_count := 0

# overridden by bombs and cubes
@warning_ignore("unused_parameter")
func set_collision_disabled(value: bool) -> void:
	return

# overriden by bombs and cubes
@warning_ignore("unused_parameter")
func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController,area:Area3D) -> void:
	return

# this too
func on_miss() -> void:
	return

func _on_cut_piece_died():
	_piece_death_count += 1
	if _piece_death_count >= 2:
		release()

func _physics_process(delta: float) -> void:
	if Scoreboard.paused or not is_visible_in_tree() or not Map.current_info: return
	real_time -=delta
	# enable collisions when cuttable gets close enough to player
	if global_transform.origin.z > -3.0:
		set_collision_disabled(false)
	
	# remove children that go to far
	if real_time <= 0:
		on_miss()
