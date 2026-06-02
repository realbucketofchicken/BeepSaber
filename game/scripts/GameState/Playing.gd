extends GameState
class_name GameStatePlaying

func _ready(game: BeepSaber_Game) -> void:
	game.main_menu._hide()
	game.settings_canvas._hide()
	game.show_MapSourceDialogs(false)
	game.endscore._hide()
	game.pause_menu._hide()
	game.highscore_canvas._hide()
	game.name_selector_canvas._hide()
	game.left_saber._show()
	game.right_saber._show()
	game.multiplier_label.visible = true
	game.point_label.visible = true
	game.percent_indicator.visible = true
	game.track.visible = true
	game.left_ui_raycast.visible = false
	game.right_ui_raycast.visible = false
	game.highscore_keyboard._hide()
	game.online_search_keyboard._hide()
	Scoreboard.paused = false

func _physics_process(game: BeepSaber_Game) -> void:
	if game.left_controller.by_just_pressed():
		game._transition_game_state(game.gamestate_paused)
	if game._audio_synced_after_restart:
		_process_map(game)
	else:
		# 0.5 seconds is a pretty concervative number to use for the audio
		# resync check. Having this duration be this long might only be an
		# issue for maps that spawn notes extremely early into the song.
		if game.song_player.get_playback_position() < 0.5:
			game._audio_synced_after_restart = true

var bomb_template := load("res://game/Bomb/Bomb.tscn") as PackedScene
var wall_template := load("res://game/Wall/Wall.tscn") as PackedScene
var arc_template := load("res://game/Arc/Arc.tscn") as PackedScene
const BEATS_AHEAD := 4.0

var track_map:Dictionary[StringName,Array]
var tracks:Array[AnimateTrackInfo]

func calcHjd(offset: float,bpm:float,njs:float) -> float:
	var maxHalfJump := 17.999;
	var num:float = 60 / bpm;
	var hjd:float = 4;
	while (njs * num * hjd > maxHalfJump):
		hjd /= 2;
	if (hjd < 1): hjd = 1
	return max(hjd + offset, 0.25);




func _process_map(game: BeepSaber_Game) -> void:
	if (Map.current_info == null):
		return
	var njs:float = Map.current_difficulty.note_jump_movement_speed
	var beats_per_second:float = Map.current_info.beats_per_minute / 60 
	var current_beat := game.song_player.get_playback_position() * (beats_per_second) 
	var bpm:float = Map.current_info.beats_per_minute
	var hjd:float = calcHjd(Map.current_difficulty.note_jump_start_beat_offset,bpm,njs)
	var jd:float = njs * (60 / bpm) * hjd * 2
	var rt:float = jd / (2 * njs)
	var look_ahead := current_beat + rt*beats_per_second
	
	#print(rt/beats_per_second," ",jd," ",njs," ",look_ahead," ",current_beat)
	#print(look_ahead - current_beat," ",reaction_time/2," ",beat," ",current_beat," ",jump_distance)
	
	# chains connect to a regular colornote and modify it, so we have to keep
	# track of what notes were spawned this frame, in case any become the head
	# of a chain.
	# why did they do this?
	var note_info_refs: Array[ColorNoteInfo] = []
	var cube_refs: Array[BeepCube] = []
	# spawn notes
	while not Map.note_stack.is_empty() and Map.note_stack[-1].beat <= look_ahead:
		var note := GlobalReferences.cube_pool.acquire() as BeepCube
		var note_info := Map.note_stack.pop_back() as ColorNoteInfo
		var color: = Map.color_left if note_info.color == 0 else Map.color_right
		if note_info.custom_data.has("_color"):
			note.spawn(note_info, current_beat, Color(note_info.custom_data["_color"][0], 
						note_info.custom_data["_color"][1], 
						note_info.custom_data["_color"][2]),
						njs,jd)
		else:
			note.spawn(note_info, current_beat, color,njs,jd)
		if note_info.custom_data.has("_track"):
			var found_tracks:Array 
			if note_info.custom_data["_track"] is String:
				found_tracks = [note_info.custom_data["_track"]]
			else:
				found_tracks = note_info.custom_data["_track"]
			for track in found_tracks:
				if track_map.has(track):
					track_map[track].append(note)
				else:
					track_map[track] = [note]
				note.just_released.connect(func() -> void: track_map[track].erase(note))
		note_info_refs.append(note_info)
		cube_refs.append(note)
	
	# spawn bombs
	while not Map.bomb_stack.is_empty() and Map.bomb_stack[-1].beat <= look_ahead:
		var bomb := bomb_template.instantiate() as Bomb
		bomb.spawn(Map.bomb_stack.pop_back() as BombInfo, current_beat,njs,jd)
		game.track.add_child(bomb)
	
	# spawn obstacles (walls)
	while not Map.obstacle_stack.is_empty() and Map.obstacle_stack[-1].beat <= look_ahead:
		var wall := wall_template.instantiate() as Wall
		var wall_info: = Map.obstacle_stack.pop_back() as ObstacleInfo
		if wall_info.custom_data.has("_color"):
			wall.spawn(wall_info, current_beat, Color(wall_info.custom_data["_color"][0], wall_info.custom_data["_color"][1], wall_info.custom_data["_color"][2]),njs,jd)
		else:
			wall.spawn(wall_info, current_beat, Settings.default_values.obstacle_color,njs,jd)
		game.track.add_child(wall)
	
	while not Map.arc_stack.is_empty() and Map.arc_stack[-1].head_beat <= look_ahead:
		var arc := arc_template.instantiate() as Arc
		var arc_info := Map.arc_stack.pop_back() as ArcInfo
		
		# find starting cube to use as magnet trigger
		var cube : BeepCube
		var cube_id := cube_refs.size()-1
		while cube_id >= 0:
			var current_cube : BeepCube = cube_refs[cube_id]
			if (current_cube.beat == arc_info.head_beat
				and current_cube.which_saber == arc_info.color
				):
					cube = current_cube
					break
			cube_id -= 1
		
		arc.spawn(arc_info, current_beat,njs,jd, cube)
		game.track.add_child(arc)
	
	while not Map.chain_stack.is_empty() and Map.chain_stack[-1].head_beat <= look_ahead:
		var chain_info := Map.chain_stack.pop_back() as ChainInfo
		if chain_info.slice_count > 1: # skip if the chain doesn't have any links
			ChainLink.construct_chain(chain_info, current_beat, note_info_refs, cube_refs,njs,jd)
	
	while not Map.event_stack.is_empty() and Map.event_stack[-1].beat <= current_beat:
		game.event_driver.process_event(Map.event_stack.pop_back() as EventInfo)
	
	while not Map.animate_track_stack.is_empty() and Map.animate_track_stack[-1].beat <= current_beat:
		print("track spawned")
		tracks.append(Map.animate_track_stack.pop_back() as AnimateTrackInfo)
	
	for track in tracks:
		var track_progress:float = (current_beat-track.beat)/track.duration
		if track_progress >= 1.0:
			tracks.erase(track)
			continue
		var objects:Array[Node3D]
		for track_name in track.target_tracks:
			if track_map.has(track_name):
				objects.append_array(track_map[track_name])
		for object in objects:
			if object is not BeepCube:
				push_error("unsupported type, please implement")
				continue
			var cube:BeepCube = object
			cube.track_offset.rotation_degrees = Vector3.ZERO
			cube.track_offset.position = Vector3.ZERO
			cube.track_offset.scale = Vector3.ONE
			if track.offset_positions != null:
				cube.track_offset.global_position += InterpolationHelper.get_animation(track.offset_positions,track_progress,track.default_easing)
			if track.offset_scale != null:
				cube.track_offset.scale = InterpolationHelper.get_animation(track.offset_scale,track_progress,track.default_easing)
				cube.track_offset.scale = cube.track_offset.scale.max(Vector3.ONE*0.001)
			if track.cube_dissolve != null:
				cube.dissolve = InterpolationHelper.get_animation(track.cube_dissolve,track_progress,track.default_easing)
			if track.arrow_dissolve != null:
				cube.arrow_dissolve = InterpolationHelper.get_animation(track.arrow_dissolve,track_progress,track.default_easing)
			if track.offset_local_rotation != null:
				cube.track_offset.rotation_degrees = InterpolationHelper.get_animation(track.offset_local_rotation,track_progress,track.default_easing)
			if track.colors != null:
				cube.set_color(InterpolationHelper.get_animation(track.colors,track_progress,track.default_easing))
			if track.offset_rotation:
				var new_rot:Vector3 = InterpolationHelper.get_animation(track.offset_rotation,cube.time)
				var new_transform:Transform3D = Transform3D.IDENTITY
				new_transform.origin.z = -cube.jd
				var rot_x = new_transform.orthonormalized().rotated(Vector3.RIGHT,deg_to_rad(new_rot.x))
				var rot_y = rot_x.orthonormalized().rotated(Vector3.UP,deg_to_rad(new_rot.y))
				
				rot_y.origin *= ((cube.time / (cube.jd/cube.njs))-0.5)/2
				cube.track_offset.transform = rot_y
