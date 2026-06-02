class_name InterpolationHelper extends RefCounted


# this is cursed
static func get_animation(arrays:PointDefinition,time:float, default_easing:InterpolationHelper.Easings.easing_types = InterpolationHelper.Easings.easing_types.none) -> Variant:
	# [[Vector3,time,easing],[Vector3,time,easing],[Vector3,time,easing]]
	if !arrays.points_array:
		push_error("empty ass point definition bruh")
		return
	if arrays.points_array[0].time > time:
		return arrays.points_array[0].data_point
	elif arrays.points_array[-1].time < time:
		return arrays.points_array[-1].data_point
	#                                        \/ watch this be an off-by-one error
	for cur_inbetween in range(arrays.points_array.size()-1):
		var from_def:NoodlePoint = arrays.points_array[cur_inbetween]
		#print(from_def)
		var to_def:NoodlePoint = arrays.points_array[cur_inbetween+1]
		#print(to_def)
		if from_def.time < time && to_def.time > time:
			var easing:int = -1
			easing = Easings.get_easing_type(from_def.easing if from_def.easing != InterpolationHelper.Easings.easing_types.none else default_easing)
			var interpolate:float = Easings.get_ease(time,easing)
			return lerp(from_def.data_point,to_def.data_point,interpolate)
	return arrays.points_array[0].data_point

## returns in euler angles, but interpolates with basis
static func get_animation_rotations(arrays:Array[Array],time:float) -> Variant:
	# [[Vector3,time,easing],[Vector3,time,easing],[Vector3,time,easing]]
	if arrays[0][1] > time:
		return arrays[0][0]
	elif arrays[-1][1] < time:
		return arrays[-1][0]
	#                                        \/ watch this be an off-by-one error
	for cur_inbetween in range(arrays.size()-1):
		var from_array:Array = arrays[cur_inbetween]
		#print(from_array)
		var to_array:Array = arrays[cur_inbetween+1]
		#print(to_array)
		if from_array[1] < time && to_array[1] > time:
			var easing:int = -1
			if arrays[cur_inbetween+1].size() > 2:
				easing = Easings.get_easing_type(to_array[2])
			var interpolate:float = Easings.get_ease(time,easing)
			var from_basis:Basis = Basis.from_euler(from_array[0])
			var to_basis:Basis = Basis.from_euler(to_array[0])
			var new_basis:Basis = lerp(from_basis,to_basis,interpolate)
			return new_basis.get_euler()
	return arrays[0][0]

class Easings:
	enum easing_types{
		none,
		easeInSine,
		easeOutSine,
		easeInOutSine,
		easeInCubic,
		easeOutCubic,
		easeInOutCubic,
		easeInQuint,
		easeOutQuint,
		easeInOutQuint,
		easeInCirc,
		easeOutCirc,
		easeInOutCirc,
		easeInElastic,
		easeOutElastic,
		easeInOutElastic,
		easeInQuad,
		easeOutQuad,
		easeInOutQuad,
		easeInQuart,
		easeOutQuart,
		easeInExpo,
		easeOutExpo,
		easeInOutExpo,
		easeInBack,
		easeOutBack,
		easeInOutBack,
		easeInBounce,
		easeOutBounce,
		easeInOutBounce,
		easeStep,
	}
	
	# thank GOD godot supports multi cursors
	static func get_ease(time:float,easing:int) -> float:
		match easing:
			easing_types.easeInSine:
				return easeInSine(time)
			easing_types.easeOutSine:
				return easeOutSine(time)
			easing_types.easeInOutSine:
				return easeInOutSine(time)
			easing_types.easeInCubic:
				return easeInCubic(time)
			easing_types.easeOutCubic:
				return easeOutCubic(time)
			easing_types.easeInOutCubic:
				return easeInOutCubic(time)
			easing_types.easeInQuint:
				return easeInQuint(time)
			easing_types.easeOutQuint:
				return easeOutQuint(time)
			easing_types.easeInOutQuint:
				return easeInOutQuint(time)
			easing_types.easeInCirc:
				return easeInCirc(time)
			easing_types.easeOutCirc:
				return easeOutCirc(time)
			easing_types.easeInOutCirc:
				return easeInOutCirc(time)
			easing_types.easeInElastic:
				return easeInElastic(time)
			easing_types.easeOutElastic:
				return easeOutElastic(time)
			easing_types.easeInOutElastic:
				return easeInOutElastic(time)
			easing_types.easeInQuad:
				return easeInQuad(time)
			easing_types.easeOutQuad:
				return easeOutQuad(time)
			easing_types.easeInOutQuad:
				return easeInOutQuad(time)
			easing_types.easeInQuart:
				return easeInQuart(time)
			easing_types.easeOutQuart:
				return easeOutQuart(time)
			easing_types.easeInExpo:
				return easeInExpo(time)
			easing_types.easeOutExpo:
				return easeOutExpo(time)
			easing_types.easeInOutExpo:
				return easeInOutExpo(time)
			easing_types.easeInBack:
				return easeInBack(time)
			easing_types.easeOutBack:
				return easeOutBack(time)
			easing_types.easeInOutBack:
				return easeInOutBack(time)
			easing_types.easeInBounce:
				return easeInBounce(time)
			easing_types.easeOutBounce:
				return easeOutBounce(time)
			easing_types.easeInOutBounce:
				return easeInOutBounce(time)
			easing_types.easeStep:
				return easeStep(time)
			easing_types.none: # aka "linear"
				return lerpf(0,1,time)
			_:
				push_error("MISSING INTERPOLATION")
				return lerpf(0,1,time)
	
	## not sure this is the best most optimized
	static func get_easing_type(source:Variant) -> int:
		if source is not String:
			return easing_types.none
		if easing_types.has(source):
			return easing_types[source]
		else:
			push_error("MISSING EASING: ",source)
			return easing_types.none


	static func easeInSine(x: float) -> float:
		return 1 - cos((x * PI) / 2);

	static func easeOutSine(x: float) -> float:
		return sin((x * PI) / 2);

	static func easeInOutSine(x: float) -> float:
		return -(cos(PI * x) - 1) / 2;

	static func easeInCubic(x: float) -> float:
		return x * x * x;

	static func easeOutCubic(x: float) -> float:
		return 1 - pow(1 - x, 3);

	static func easeInOutCubic(x: float) -> float:
		return 4 * x * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 3) / 2;

	static func easeInQuint(x: float) -> float:
		return x * x * x * x * x;

	static func easeOutQuint(x: float) -> float:
		return 1 - pow(1 - x, 5);

	static func easeInOutQuint(x: float) -> float:
		return  16 * x * x * x * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 5) / 2

	static func easeInCirc(x: float) -> float:
		return 1 - sqrt(1 - pow(x, 2));

	static func easeOutCirc(x: float) -> float:
		return sqrt(1 - pow(x - 1, 2));

	static func easeInOutCirc(x: float) -> float:
		return (1 - sqrt(1 - pow(2 * x, 2))) / 2\
				if x < 0.5 else (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2;

	static func easeInElastic(x: float) -> float:
		const c4 = (2 * PI) / 3;

		return 0.0 if x == 0 else 1.0 if x == 1 else -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4);

	static func easeOutElastic(x: float) -> float:
		const c4 = (2 * PI) / 3;

		return 0.0 if x == 0 else 1.0 if x == 1 else pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;

	static func easeInOutElastic(x: float) -> float:
		const c5 = (2 * PI) / 4.5;

		return 0.0\
			if x == 0 else  1.0\
			if x == 1 else -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2\
			if x < 0.5 else (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
	
	static func easeInQuad(x: float) -> float:
		return x * x;

	static func easeOutQuad(x: float) -> float:
		return 1 - (1 - x) * (1 - x);

	static func easeInOutQuad(x: float) -> float:
		return 2 * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 2) / 2;

	static func easeInQuart(x: float) -> float:
		return x * x * x * x;

	static func easeOutQuart(x: float) -> float:
		return 1 - pow(1 - x, 4);

	static func easeInOutQuart(x: float) -> float:
		return 8 * x * x * x * x if x < 0.5 else 1 - pow(-2 * x + 2, 4) / 2;

	static func easeInExpo(x: float) -> float:
		return 0.0 if x == 0.0 else pow(2, 10 * x - 10);

	static func easeOutExpo(x: float) -> float:
		return 1.0 if x == 1.0 else 1.0 - pow(2, -10 * x);

	static func easeInOutExpo(x: float) -> float:
		return 0.0 if x == 0.0 else 1.0\
		 if x == 1 else pow(2, 20 * x - 10) / 2\
		 if x < 0.5 else (2 - pow(2, -20 * x + 10)) / 2;

	## TODO: add the remaining

	static func easeInBack(x: float) -> float:
		const c1 = 1.70158;
		const c3 = c1 + 1;

		return c3 * x * x * x - c1 * x * x;

	static func easeOutBack(x: float) -> float:
		const c1 = 1.70158;
		const c3 = c1 + 1;

		return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2);

	static func easeInOutBack(x: float) -> float:
		const c1 = 1.70158;
		const c2 = c1 * 1.525;

		return (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2 if x < 0.5 else\
		  (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;

	static func easeInBounce(x: float) -> float:
		return 1 - easeOutBounce(1 - x);

	static func easeOutBounce(p: float) -> float:
		var a:float = (121 / 16) * p * p
		var x:float = a

		var q1:float = p - (6 / 11)
		var b:float = ((363 / 40) * q1 * q1) + (7 / 10)
		x =  b if (b < x) else x

		var q2:float = p - (179 / 220)
		var c:float = ((4356 / 361) * q2 * q2) + (91 / 100)
		x = c if (c < x) else x

		var q3:float = p - (19 / 20)
		var d:float = ((54 / 5) * q3 * q3) + (973 / 1000)
		x = d if (d < x) else x
		return x;

	static func easeInOutBounce(x: float) -> float:
		return (1 - easeOutBounce(1 - 2 * x)) / 2 if x < 0.5 else (1 + easeOutBounce(2 * x - 1)) / 2;
	
	static func easeStep(x: float) -> float:
		return floor(x)
