class_name AnimateTrackInfo extends RefCounted

# https://heck.aeroluna.dev/animation/tracks-and-points/#events
# Attempting to animate a property which is already being animated will
# stop the overwritten AnimateTrack
var target_tracks:Array[StringName]
var beat:float
var duration:float # in beats!!!
var default_easing:InterpolationHelper.Easings.easing_types
var repeats:int = 0

var colors:PointDefinition
var offset_positions:PointDefinition
var offset_local_rotation:PointDefinition
var offset_rotation:PointDefinition
var offset_scale:PointDefinition
var cube_dissolve:PointDefinition
var arrow_dissolve:PointDefinition
