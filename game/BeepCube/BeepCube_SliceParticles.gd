extends Node3D
class_name BeepCubeSliceParticles

@export var c1:GPUParticles3D

func _ready() -> void:
	c1.one_shot = true
	reset()

func reset() -> void:
	if not c1: return
	visible = false
	c1.emitting = false
	c1.restart()

func fire() -> void:
	if not c1: return
	visible = true
	c1.emitting = true
