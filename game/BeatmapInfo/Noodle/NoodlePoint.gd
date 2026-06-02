class_name NoodlePoint extends RefCounted

## this is a RefCounted so point definitions can be reused

var data_point:Variant
var time:float ## 0 to 1 value indicating the objects lifespan
var easing:InterpolationHelper.Easings.easing_types

static func create_point_from_data(arr:Array) -> PointDefinition:
	var p:PointDefinition = PointDefinition.new()
	var working_array:Array
	if arr[0] is Array:
		working_array = arr[0]
	else:
		working_array = arr
	var parameter_size = working_array.size()
	while working_array[-1] is String:
		parameter_size -= 1
		working_array.pop_back()
	# keep in mind this will still include the time info, thats why theres one more
	if parameter_size == 4:
		p.points_array = create_vec3_from_data(arr)
	elif parameter_size == 2:
		p.points_array = create_float_from_data(arr)
	else:
		p.points_array = []
	return p

static func create_vec3_from_data(arr:Array) -> Array[NoodlePoint]:
	if arr[0] is Array:
		var points:Array[NoodlePoint]
		for point:Array in arr:
			var vec:Vector3 = Vector3(point[0],point[1],point[2])
			var new_point:NoodlePoint = NoodlePoint.new()
			new_point.data_point = vec
			new_point.time = point[3]
			if point.size() == 5:
				new_point.easing = InterpolationHelper.Easings.get_easing_type(point[4])
			points.append(new_point)
		return points
	else:
		var vec:Vector3 = Vector3(arr[0],arr[1],arr[2])
		var new_point:NoodlePoint = NoodlePoint.new()
		new_point.data_point = vec
		new_point.time = arr[3]
		if arr.size() == 5:
			new_point.easing = InterpolationHelper.Easings.get_easing_type(arr[4])
		return [new_point]

static func create_float_from_data(arr:Array) -> Array[NoodlePoint]:
	if arr[0] is Array:
		var points:Array[NoodlePoint]
		for point:Array in arr:
			var vec:float = point[0]
			var new_point:NoodlePoint = NoodlePoint.new()
			new_point.data_point = vec
			new_point.time = point[1]
			if point.size() == 3:
				new_point.easing = InterpolationHelper.Easings.get_easing_type(point[2])
			points.append(new_point)
		return points
	else:
		var vec:float = arr[0]
		var new_point:NoodlePoint = NoodlePoint.new()
		new_point.data_point = vec
		new_point.time = arr[1]
		if arr.size() == 3:
			new_point.easing = InterpolationHelper.Easings.get_easing_type(arr[2])
		return [new_point]
