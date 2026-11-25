extends Node

class_name Utils

static func line2infline(a: Vector2, b: Vector2) -> PackedVector2Array:
	const huge: float = 2000
	var temp: Vector2 = (a-b).abs()
	var d: Vector2 = (a-b) / (temp.x + temp.y)
	return PackedVector2Array([a + d * huge, b - d * huge])

static func array2curve(points: Array[Vector2]) -> Curve:
	var curve := Curve.new()
	for p in points:
		curve.add_point(p)
	return curve

static func percent2db(percent: float) -> float:
	return 20 * log(percent / 100.0) / log(10)

static func flip_but_i(i: int) -> int:
	if i < 4:
		return [1,0,3,2][i]
	return i

static var but_count: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
static var prev_but_count: Array[int] = [-1, -1, -1, -1, -1, -1, -1, -1]
static var input_flipped: bool = false
const but_map: Array[Array] = [
	[0, 1, 4, 3, 6, 7, 11, 10],
	[0, 1, 3, 2, 9, 10, 6, 4]
]
static var but_map_i: int = 0
static func joy_button_load() -> void:
	var joypads: Array[int] = Input.get_connected_joypads()
	if len(joypads) == 0:
		for i in range(8):
			but_count[i] = 0
			prev_but_count[i] = 0
		return
	
	if Input.is_action_just_pressed("flipBut"):
		input_flipped = !input_flipped
	
	var index: int = joypads[0]
	@warning_ignore("int_as_enum_without_cast")
	if Input.is_joy_button_pressed(index, 2):
		but_map_i = 1
	
	for i in range(8):
		prev_but_count[i] = but_count[i]
		@warning_ignore("int_as_enum_without_cast")
		var ii: int = i
		if input_flipped:
			ii = flip_but_i(ii)
		if Input.is_joy_button_pressed(index, but_map[but_map_i][ii]):
			but_count[i] = 2
		else:
			if but_count[i] > 0:
				but_count[i] -= 1
	
	if prev_but_count[0] < 0:
		for i in range(8):
			prev_but_count[i] = but_count[i]
static func joy_button_just_pressed(i: int):
	return but_count[i] > (prev_but_count[i] + 1)
static func joy_button_pressed(i: int):
	return but_count[i] > 0
const key_input_names: Array[String] = ["keyD", "keyF", "keyJ", "keyK"]
static func key_just_pressed(i: int):
	return Input.is_action_just_pressed(key_input_names[i])
static func key_pressed(i: int):
	return Input.is_action_pressed(key_input_names[i])
static func gen_just_pressed(i: int):
	return key_just_pressed(i) || joy_button_just_pressed(i)
static func gen_pressed(i: int):
	return key_pressed(i) || joy_button_pressed(i)
