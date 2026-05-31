# The Feature_VRSimulator provides some basic functionality to control the ARVRNodes
# via keyboard for desktop debugging and basic tests
extends Node3D

const walk_speed := 1.0
const controller_move_speed := 0.002
const player_height := 1.8
const duck_multiply := 0.4
const info_label_visible := true

# camera relative positioning of controllers
var left_controller_node: Node3D
var right_controller_node: Node3D

var info_label: Label
var info_rect: ColorRect

const info_text := """VR Simulator Keys:
	mouse right-click: move (camera or controller)
	W A S D: move (camera or controller)
	space: duck player
	shift: fly mode (moves origin up)

	hold CTRL/ALT: enable left/right controller for manipulation
	mouse left-click: Trigger Button
	Keypad 7: Y/B Button
	Keypad 1: X/A Button

	'r': reset controller positions
"""

func _ready() -> void:
	# set up everything for simulation
	left_controller_node = Node3D.new()
	vr.vrCamera.add_child(left_controller_node)

	right_controller_node = Node3D.new()
	vr.vrCamera.add_child(right_controller_node)


	# show some keyboard info in a UI overlay
	info_label = Label.new()
	info_label.text = info_text
	var m := 8
	info_label.offset_left = m
	info_label.offset_right = m
	info_label.offset_top = m
	info_label.offset_bottom = m
	info_rect = ColorRect.new()
	
	info_rect.color = Color(0, 0, 0, 0.7)
	info_rect.size = info_label.get_minimum_size() #Vector2(128, 128);
	info_rect.add_child(info_label)
	add_child(info_rect)
	
	info_rect.scale = Vector2(0.5,0.5)
	
	vr.vrCamera.position.y = player_height
	_reset_controller_position()

func _reset_controller_position() -> void:
	left_controller_node.position = Vector3(-0.2, -0.1, -0.4)
	right_controller_node.position = Vector3( 0.2, -0.1, -0.4)
	_update_virtual_controller_position()

# moves the ARVRController nodes to the simulated position
func _update_virtual_controller_position() -> void:
	if (vr.leftController && left_controller_node):
		vr.leftController.global_transform = left_controller_node.global_transform
	if (vr.rightController && right_controller_node):
		vr.rightController.global_transform = right_controller_node.global_transform

func _is_interact_left() -> bool:
	return Input.is_key_pressed(KEY_CTRL)

func _is_interact_right() -> bool:
	return Input.is_key_pressed(KEY_ALT)

func _interact_move_controller(dir: Vector3, rot: Vector3) -> void:
	if (_is_interact_left()):
		if (left_controller_node):
			left_controller_node.rotate_x(rot.x)
			left_controller_node.rotate_y(rot.y)
			left_controller_node.position += dir
	if (_is_interact_right()):
		if (right_controller_node):
			right_controller_node.rotate_x(rot.x)
			right_controller_node.rotate_y(rot.y)
			right_controller_node.position += dir
	_update_virtual_controller_position()

func _update_keyboard(dt: float) -> void:
	var move_direction := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_F)) - float(Input.is_key_pressed(KEY_V)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	
	if _is_interact_left() || _is_interact_right():
		if move_direction.length_squared() > 0.01:
			_interact_move_controller(Vector3(0.0, 0.0, move_direction.z * dt), Vector3(move_direction.y, move_direction.x, 0.0) * 8.0 * dt)
	else:
		move_direction = vr.vrCamera.transform.basis * move_direction
		if (Input.is_key_pressed(KEY_SHIFT)): # fly mode
			vr.vrOrigin.position = vr.vrOrigin.position + move_direction.normalized() * dt * walk_speed
		else:
			move_direction.y = 0.0
			if move_direction.length_squared() > 0.01:
				vr.vrCamera.position = vr.vrCamera.position + move_direction.normalized() * dt * walk_speed
				_update_virtual_controller_position()
	
	var button_BY := Input.is_key_pressed(KEY_KP_7) || Input.is_key_pressed(KEY_7)
	var button_AX := Input.is_key_pressed(KEY_KP_1) || Input.is_key_pressed(KEY_1)
	var button_trigger := Input.is_key_pressed(KEY_KP_0) || Input.is_key_pressed(KEY_0) || Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	vr.leftController.trigger_last_frame = vr.leftController.trigger
	vr.leftController.ax_last_frame = vr.leftController.ax
	vr.leftController.by_last_frame = vr.leftController.by
	vr.rightController.trigger_last_frame = vr.rightController.trigger
	vr.rightController.ax_last_frame = vr.rightController.ax
	vr.rightController.by_last_frame = vr.rightController.by
	
	vr.leftController.trigger_last_frame = vr.leftController.trigger
	vr.leftController.ax_last_frame = vr.leftController.ax
	vr.leftController.by_last_frame = vr.leftController.by
	vr.rightController.trigger_last_frame = vr.rightController.trigger
	vr.rightController.ax_last_frame = vr.rightController.ax
	vr.rightController.by_last_frame = vr.rightController.by
	
	vr.leftController.trigger = button_trigger
	vr.leftController.by = button_BY
	vr.leftController.ax = button_AX
	vr.rightController.trigger = button_trigger
	vr.rightController.by = button_BY
	vr.rightController.ax = button_AX


func _input(event: InputEvent) -> void:
	if vr.inVR:
		return
	
	# basic keyboard events
	if (event is InputEventKey):
		var eventKey := event as InputEventKey
		if eventKey.pressed and eventKey.keycode == KEY_R:
			_reset_controller_position()
	
	# this is here instead of in _update_keyboard because if it's there, then
	# the sabers don't follow your crouched camera until a mouse motion event
	# happens.
	var current_player_height := player_height
	if (Input.is_key_pressed(KEY_SPACE)):
		current_player_height = player_height * duck_multiply
	vr.vrCamera.position.y = current_player_height
	
	# camera movement on mouse movement
	if (event is InputEventMouseMotion && Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		var eventMouse := event as InputEventMouseMotion
		if (_is_interact_left() || _is_interact_right()):
			var move := Vector3(eventMouse.relative.x, -eventMouse.relative.y, 0.0)
			_interact_move_controller(move * controller_move_speed, Vector3.ZERO)
		else:
			var yaw := eventMouse.relative.x /10.0
			var pitch := eventMouse.relative.y /10.0
			vr.vrCamera.rotate_y(deg_to_rad(-yaw))
			vr.vrCamera.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
	_update_virtual_controller_position()


func _physics_process(dt: float) -> void:
	if vr.inVR:
		return
	
	info_rect.visible = info_label_visible
	_update_keyboard(dt)
