# BeepCube is the standard cube that will get cut by the sabers
extends Cuttable
class_name BeepCube

# emitted when the cube gets cutted, correct_saber is true if the right saber was used
signal cutted(correct_saber: bool)

@export var mi:MeshInstance3D
@export var collision_big :CollisionShape3D
@export var collision_small :CollisionShape3D
@export var slice_particles :BeepCubeSliceParticles
@export var beep_cube_big: Area3D
@export var beep_cube_small: Area3D
@export var animation_player: AnimationPlayer

var which_saber: int
var is_dot: bool

# we store the mesh here as part of the BeepCube for easier access because we will
# reuse it when we create the cut cube pieces
var _mesh: Mesh
var _mat: ShaderMaterial
@export var min_speed := 0.5

var piece_left : CutPiece = null
var piece_right : CutPiece = null

#####################
# NOODLE EXTENTIONS #
#####################
var offset_positions_d:PointDefinition
var definite_positions_d:PointDefinition
var offset_local_rotation_d:PointDefinition
var offset_rotation_d:PointDefinition
var offset_scale_d:PointDefinition
var cube_dissolve_d:PointDefinition
var arrow_dissolve_d:PointDefinition
var tracks:Array[StringName]
var is_fake:bool
var interactible:bool
var disable_spawn_effect:bool
var position_offset:Vector3
@export var offset: Node3D
@export var track_offset: Node3D
var dissolve:float
var arrow_dissolve:float
var start_trans:Transform3D
var njs:float
var jd:float


func _ready() -> void:
	_mat = mi.material_override as ShaderMaterial
	_mesh = mi.mesh
	
	# init our cut pieces with unique copies of our own material for reference,
	# and enable "bouncy" physics behavior
	piece_left = CutPiece.new(self, _mesh, _mat.duplicate(true) as ShaderMaterial, true)
	piece_right = CutPiece.new(self, _mesh, _mat.duplicate(true) as ShaderMaterial, true)
	
	# slice_particles are within cube's tree, but want then to move in global space
	slice_particles.top_level = true

func spawn(note_info: ColorNoteInfo, current_beat: float, color : Color,njs:float,jd:float) -> void:
	# re-enable our process_mode first otherwise it seems like Godot-internals
	# can behave weirdly (ex. AnimationPlayer won't always play correctly)
	process_mode = Node.PROCESS_MODE_ALWAYS
	speed = njs
	beat = note_info.beat
	time = jd/njs
	which_saber = note_info.color
	is_dot = note_info.cut_direction == 8
	var noteLineIndex = note_info.line_index
	var noteLayerIndex = note_info.line_layer
	var leftSide = false
	var flipLineIndex = noteLineIndex * -1
	var newLaneCount = 1000
	offset.position = Vector3.ZERO
	offset.scale = Vector3.ONE
	offset.rotation = Vector3.ZERO
	track_offset.position = Vector3.ZERO
	track_offset.scale = Vector3.ONE
	track_offset.rotation = Vector3.ZERO
	if noteLineIndex >= 1000 or noteLineIndex <= -1000:
		if sign(note_info.line_index) == 1:
			transform.origin.x = ((note_info.line_index / 1000.0) - 2.5)
		else:
			transform.origin.x = ((note_info.line_index / 1000.0) - 0.5)
		transform.origin.y = ((noteLayerIndex - 1000.0) / 1000.0 + 0.8)
	else:
		transform.origin.x = (note_info.line_index * 0.6) + Constants.LANE_ZERO_X
		transform.origin.y = (note_info.line_layer * 0.6 ) + Constants.LAYER_ZERO_Y

	
	if note_info.cut_direction < 9:
		rotation.z = Constants.CUBE_ROTATIONS[note_info.cut_direction] + deg_to_rad(note_info.angle_offset)
	else:
		rotation.z = deg_to_rad((note_info.cut_direction - 1000) * -1)
	
	if is_dot:
		(collision_big.shape as BoxShape3D).size.y = 0.8
	else:
		(collision_big.shape as BoxShape3D).size.y = 0.5
	
	offset_positions_d = null
	offset_local_rotation_d = null
	offset_scale_d = null
	cube_dissolve_d = null
	arrow_dissolve_d = null
	definite_positions_d = null
	offset_rotation_d = null
	dissolve = 1.0
	arrow_dissolve = 1.0
	interactible = true
	is_fake = false
	tracks = []
	is_fake = false
	interactible = true
	disable_spawn_effect = false
	for dat in note_info.custom_data:
		match dat:
			"_position":
				var pos:Array = note_info.custom_data["_position"]
				transform.origin = Vector3(pos[0]* 0.6,(pos[1]* 0.6) + Constants.LAYER_ZERO_Y,transform.origin.z)
			"_scale":
				var scales:Array = note_info.custom_data["_scale"]
				offset.scale = Vector3(scales[0],scales[1],scales[2])
				offset.scale = offset.scale.max(Vector3.ONE*0.001)
			"_cutDirection":
				rotation_degrees.z = note_info.custom_data["_cutDirection"]
			"_fake":
				is_fake = note_info.custom_data["_fake"]
			"_interactable":
				interactible = note_info.custom_data["_interactable"]
			"_disableSpawnEffect":
				if note_info.custom_data["_disableSpawnEffect"] is String:
					disable_spawn_effect = note_info.custom_data["_disableSpawnEffect"] == "true" # why
				else:
					disable_spawn_effect = note_info.custom_data["_disableSpawnEffect"]
	
			"_noteJumpMovementSpeed":
				njs = note_info.custom_data["_noteJumpMovementSpeed"]
			"_animation":
				for property in note_info.custom_data["_animation"]:
					match property:
						"_dissolve":
							var n_d = note_info.custom_data["_animation"]["_dissolve"]
							cube_dissolve_d = NoodlePoint.create_point_from_data(n_d)
						"_dissolveArrow":
							var n_d = note_info.custom_data["_animation"]["_dissolveArrow"]
							arrow_dissolve_d = NoodlePoint.create_point_from_data(n_d)
						"_scale":
							var n_d = note_info.custom_data["_animation"]["_scale"]
							offset_scale_d = NoodlePoint.create_point_from_data(n_d)
						"_position":
							var n_d = note_info.custom_data["_animation"]["_position"]
							offset_positions_d = NoodlePoint.create_point_from_data(n_d)
						"_localRotation":
							var n_d = note_info.custom_data["_animation"]["_localRotation"]
							offset_local_rotation_d = NoodlePoint.create_point_from_data(n_d)
						"_rotation":
							var n_d = note_info.custom_data["_animation"]["_rotation"]
							offset_rotation_d = NoodlePoint.create_point_from_data(n_d)
						"_definitePosition":
							var n_d = note_info.custom_data["_animation"]["_definitePosition"]
							definite_positions_d = NoodlePoint.create_point_from_data(n_d)
						_:
							push_warning("Unsupported parameter: ",property)
			"_track":
				pass
			"_color":
				pass
			_:
				push_warning("Unsupported parameter: ",dat)
	piece_left.set_color(color)
	piece_right.set_color(color)
	set_color(color)
	_mat.set_shader_parameter(&"is_dot", is_dot)
	# since cube instances get recycled, we gotta reset cubes that were chain
	# heads in a past life
	_mat.set_shader_parameter(&"is_chain_head", false)
	piece_left.set_chain_head(false)
	piece_right.set_chain_head(false)
	
	# separate cube collision layers to allow a diferent collider on right/wrong cuts.
	# opposing collision layers (ie. right note & left saber) will be placed on the
	# smalling collision shape, while similar collision layers (ie right note &
	# right saber) are placed on the larger collision shape.
	var is_left_note := note_info.color == 0
	beep_cube_big.collision_layer = 0x0
	beep_cube_big.set_collision_layer_value(CollisionLayerConstants.LeftNote_bit, is_left_note)
	beep_cube_big.set_collision_layer_value(CollisionLayerConstants.RightNote_bit, not is_left_note)
	beep_cube_small.collision_layer = 0x0
	beep_cube_small.set_collision_layer_value(CollisionLayerConstants.LeftNote_bit, true)
	beep_cube_small.set_collision_layer_value(CollisionLayerConstants.RightNote_bit, true)
	
	# play the spawn animation when this cube enters the scene
	var anim_speed := Map.current_difficulty.note_jump_movement_speed / 9.0
	animation_player.speed_scale = maxf(min_speed,anim_speed)
	if !disable_spawn_effect:
		animation_player.play(&"Spawn")
	
	slice_particles.reset()
	mi.visible = true
	move_dir = transform.basis.z
	var start_transform:Transform3D = transform
	start_transform.origin.z = -jd/2
	transform = start_transform
	#start_transform.rotated_local()
	start_trans = transform
	self.njs = njs
	self.jd = jd

func set_color(color:Color) -> void:
	_mat.set_shader_parameter(&"color", color)

func _physics_process(delta: float) -> void:
	super(delta)
	#set_color(Color.WHITE * (1.0-((time / (jd/2/njs))-0.5)))
	offset.rotation_degrees = Vector3.ZERO
	offset.position = Vector3.ZERO
	offset.scale = Vector3.ONE
	if cube_dissolve_d != null:
		dissolve = InterpolationHelper.get_animation(cube_dissolve_d,time)
	if arrow_dissolve_d != null:
		arrow_dissolve = InterpolationHelper.get_animation(arrow_dissolve_d,time)
	if offset_positions_d != null:
		offset.global_position += InterpolationHelper.get_animation(offset_positions_d,time)
	if definite_positions_d != null:
		offset.global_position = start_trans.origin + InterpolationHelper.get_animation(definite_positions_d,time)*0.6
		offset.global_position.z = InterpolationHelper.get_animation(definite_positions_d,time).z *0.6
	if offset_local_rotation_d != null:
		offset.rotation_degrees = InterpolationHelper.get_animation(offset_local_rotation_d,time)
	if offset_scale_d != null:
		offset.scale = InterpolationHelper.get_animation(offset_scale_d,time)
		offset.scale = offset.scale.max(Vector3.ONE*0.001)
	if offset_rotation_d:
		var new_rot:Vector3 = InterpolationHelper.get_animation(offset_rotation_d,time)
		var new_transform:Transform3D = Transform3D.IDENTITY
		new_transform.origin.z = -jd
		var length:float = new_transform.origin.length()
		var one:Vector3 = new_transform.origin.normalized().cross(start_trans.origin.normalized())
		var angle:float = new_transform.origin.normalized().angle_to(start_trans.origin.normalized())
		new_transform = new_transform.rotated(one,angle)
		new_transform.origin *= ((time / (jd/njs))-0.5)/2
		transform = new_transform
	
	_mat.set_shader_parameter(&"dissolve", 1.0-dissolve)
	_mat.set_shader_parameter(&"arrow_dissolve", 1.0-arrow_dissolve)


# call this when clearing the track
func clear_from_track() -> void:
	hide_cube()
	piece_left.hide_piece()
	piece_right.hide_piece()
	if ! is_released():
		release()

func hide_cube() -> void:
	mi.visible = false
	set_collision_disabled(true)
	# disable processing on this node and all children to help with performance
	process_mode = Node.PROCESS_MODE_DISABLED

func make_chain_head() -> void:
	_mat.set_shader_parameter(&"is_chain_head", true)
	piece_left.set_chain_head(true)
	piece_right.set_chain_head(true)

func on_miss() -> void:
	if !is_fake:
		Scoreboard.reset_combo()
	hide_cube()
	release()

func set_collision_disabled(value: bool) -> void:
	await get_tree().physics_frame
	collision_big.disabled = value
	collision_small.disabled = value

func cut(saber_type: int, cut_speed: Vector3, cut_plane: Plane, controller: BeepSaberController,area:Area3D) -> void:
	if !interactible:
		#print("NOT INTERACTIBLE")
		return
	# compute the angle between the cube orientation and the cut direction
	var cut_direction_xy := -Vector3(cut_speed.x, cut_speed.y, 0.0).normalized()
	var base_cut_angle_accuracy := global_transform.basis.y.dot(cut_direction_xy)
	var cut_distance := cut_plane.distance_to(global_transform.origin)
	
	if saber_type == which_saber:
		if base_cut_angle_accuracy < 0.75 && !is_dot:
			#print(collision_small.get_parent(), " ", area)
			if area == collision_small.get_parent():
				if !is_fake:
					Scoreboard.bad_cut(transform.origin)
				cutted.emit(false)
			else:
				return
		else:
			var cut_distance_accuracy := clampf((0.32 - absf(cut_distance))/0.25, 0.0, 1.0)
			var travel_distance_factor := controller.movement_aabb.position.distance_to(controller.movement_aabb.end)
			travel_distance_factor = clampf((travel_distance_factor-0.04)/0.1, 0.0, 1.0)
			# allows a bit of save margin where the beat is considered 100% correct
			if !is_fake:
				Scoreboard.note_cut(transform.origin, cut_distance_accuracy, travel_distance_factor)
			cutted.emit(true)
	else:
		if !is_fake:
			Scoreboard.bad_cut(transform.origin)
		cutted.emit(false)
	
	# reset the movement tracking volume for the next cut
	controller.reset_movement_aabb()
	
	hide_cube()
	if Settings.cube_cuts_falloff:
		_start_cut_pieces(cut_plane)
		# release() will be called by Cuttable class when it sees both pieces die
	else:
		release() # release now instead of waiting for cut pieces to die off

# cut the cube by creating two rigid bodies and using a CSGBox to create
# the cut plane
func _start_cut_pieces(cutplane: Plane) -> void:
	piece_left.global_transform = global_transform
	piece_right.global_transform = global_transform
	
	# calculate angle and position of the cut
	var cut_angle_abs := Vector2(cutplane.normal.x, cutplane.normal.y).angle()
	var cut_dist_from_center := cutplane.distance_to(global_transform.origin)
	var cut_angle_rel := cut_angle_abs - global_rotation.z
	
	_piece_death_count = 0
	piece_left.start_cut(-cut_dist_from_center, cut_angle_rel + PI)
	piece_right.start_cut(cut_dist_from_center, cut_angle_rel)
	
	# some impulse so the cube half moves
	var split_vector := cutplane.normal * 2.0
	piece_left.apply_central_impulse(-split_vector)
	piece_right.apply_central_impulse(split_vector)
	
	slice_particles.global_transform.origin = global_transform.origin
	slice_particles.rotation.z = cut_angle_abs+TAU*0.25
	slice_particles.fire()
