extends Node3D
class_name DefaultSaber

var is_extended := false

@onready var _anim := $AnimationPlayer as AnimationPlayer
@onready var light_mesh := $LightSaber_Mesh as MeshInstance3D
@onready var _mat := light_mesh.material_override as ShaderMaterial
@onready var tip := $tip as Marker3D
@onready var tail := $tail as SaberTail
@onready var hitsound := $hitsound as AudioStreamPlayer3D
var play_cooldown:float
var play_queued:bool
func _ready() -> void:
	quickhide()

func set_color(color: Color) -> void:
	_mat.set_shader_parameter(&"color", color)
	tail.set_color(color)

func _process(delta: float) -> void:
	play_cooldown -= delta
	if play_cooldown<= 0.0 && play_queued:
		play_queued = false
		hitsound.play()

func set_thickness(value: float) -> void:
	light_mesh.scale.x = value
	light_mesh.scale.z = value

func set_trail(enabled: bool = true) -> void:
	tail.visible = enabled

func _show() -> void:
	_anim.play(&"Show")
	is_extended = true
	
func _hide() -> void:
	_anim.play(&"Hide")
	is_extended = false
	
func quickhide() -> void:
	_anim.play(&"QuickHide")
	is_extended = false

# has .1ms frame cost it seems somehow
func hit(time_offset: float) -> void:
	if time_offset>0.2 or time_offset<-0.05:
		hitsound.play()
	else:
		if time_offset <= 0:
			hitsound.play(-time_offset)
		else:
			play_cooldown = time_offset
			play_queued = true
			#await get_tree().create_timer(time_offset).timeout
