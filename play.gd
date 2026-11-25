extends Node3D

@export var fade_in_frames: int
@export var wait_frames0: int
@export var text_fade_out_frames: int
@export var wait_before_start_frames: int
@export var FAR_Z: float
@export var ONE_DISTANCE: float
@export var DISAPPEAR_Z: float
@export var HOLD_OUTLINE_CONST: float
@export var HIGHLIGHT_GHOST_A: float
@export var HIGHLIGHT_GHOST_A_2: float
@export var judgement_a: float

const MAX_HOLD_OUTLINE_WIDTH: float = 100.0

# 新しいシーンとして作られたときに外部から設定されるための変数
var chart_name: String = "tutorial"
var song_upper_text: String = "Tutorial"
var song_bottom_text: String = "test"
var song_color: Color = Color.WHITE
var speed_gain: float = 1.0
var is_sfx_enabled: bool = true

var is_hold_end_enabled: bool = false

var song_config: Dictionary[String, String] = {}
var chart: Dictionary = {}
var objs: Array = []
var song_path: String = ""
var audio_offset: float = 0.0

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var effect_tap_player: AudioStreamPlayer = $EffectTapPlayer
@onready var effect_weak_tap_player: AudioStreamPlayer = $EffectWeakTapPlayer
@onready var effect_slide_player: AudioStreamPlayer = $EffectSlidePlayer
@onready var effect_weak_player: AudioStreamPlayer = $EffectWeakPlayer

func play_effect_tap() -> void:
	if is_sfx_enabled:
		effect_tap_player.play()
func play_effect_weak_tap() -> void:
	if is_sfx_enabled:
		effect_weak_tap_player.play()
func play_effect_slide() -> void:
	if is_sfx_enabled:
		effect_slide_player.play()
func play_effect_weak() -> void:
	if is_sfx_enabled:
		effect_weak_player.play()

@onready var lane_lines: Array[Line2D] = [
	$svc/sv/Back2D/svc2d/sv/LaneLine0,
	$svc/sv/Back2D/svc2d/sv/LaneLine1,
	$svc/sv/Back2D/svc2d/sv/LaneLine2,
	$svc/sv/Back2D/svc2d/sv/LaneLine3,
	$svc/sv/Back2D/svc2d/sv/LaneLine4,
	$svc/sv/Back2D/svc2d/sv/LaneLine5,
	$svc/sv/Back2D/svc2d/sv/LaneLine6,
]
@onready var hit_line: Line2D = $svc/sv/Back2D/svc2d/sv/HitLine
@onready var hit_line_: Line2D = $svc/sv/Back2D/svc2d/sv/HitLine_
@onready var hit_line2: Line2D = $svc/sv/Back2D/svc2d/sv/HitLine2
@onready var camera: Camera3D = $svc/sv/svc3d/sv/Camera3D
func update_lines() -> void:
	for i: int in range(7):
		var x: float = i - 3.0
		lane_lines[i].points = Utils.line2infline(
			camera.unproject_position(Vector3(x, 0, 0)),
			camera.unproject_position(Vector3(x, 0, -10.0)),
		)
	hit_line.points = PackedVector2Array([
		camera.unproject_position(Vector3(-3, 0, 0)),
		camera.unproject_position(Vector3(3, 0, 0)),
	])
	const sub_z: float = -0.5
	hit_line_.points = PackedVector2Array([
		camera.unproject_position(Vector3(-3, 0, sub_z)),
		camera.unproject_position(Vector3(3, 0, sub_z)),
	])
	hit_line2.points = Utils.line2infline(
		camera.unproject_position(Vector3(-3, 0, 0)),
		camera.unproject_position(Vector3(3, 0, 0)),
	)

@onready var effect_material: ShaderMaterial = $svc.material
func set_effect_param(type: String, value) -> void:
	effect_material.set_shader_parameter(type, value)

@onready var color_overlay: ColorRect = $ColorOverlay

@onready var upper_text_label: Label = $UpperTextLabel
@onready var upper_text_label2: Label = $UpperTextLabel2
@onready var bottom_text_label: Label = $BottomTextLabel
@onready var deco_line: Line2D = $DecoLine

class Obj:
	var data: Dictionary = {}
	var node = null
	var node2 = null
	var has_already_used: bool = false
@onready var line2d := $svc/sv/Back2D/svc2d/sv/line
@onready var hold2d := $svc/sv/Back2D/svc2d/sv/hold
@onready var root3d := $svc/sv/svc3d/sv
@onready var judge_white_notes_node := $svc/sv/Back2D/svc2d/sv/judge_white_notes
var obj_line_tscn: PackedScene = preload("res://obj_line.tscn")
var tap_white_tscn: PackedScene = preload("res://tap_white.tscn")
var tap_yellow_tscn: PackedScene = preload("res://tap_yellow.tscn")
var slider_left_tscn: PackedScene = preload("res://slider_left.tscn")
var slider_right_tscn: PackedScene = preload("res://slider_right.tscn")
var slider_full_tscn: PackedScene = preload("res://slider_full.tscn")
var wide_red_tscn: PackedScene = preload("res://wide_red.tscn")
var wide_blue_tscn: PackedScene = preload("res://wide_blue.tscn")
var judge_blue_tscn: PackedScene = preload("res://judge_blue.tscn")
var hold_tscn: PackedScene = preload("res://hold.tscn")
var judge_white_tscn: PackedScene = preload("res://judge_white.tscn")
var wheel_tscn: PackedScene = preload("res://wheel.tscn")
var hold_effect_tscn: PackedScene = preload("res://hold_effect.tscn")
func new_Obj(data: Dictionary) -> Obj:
	var kind: String = data["kind"]
	if kind == "line":
		var line: Line2D = obj_line_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = line
		line2d.add_child(line)
		return obj
	elif kind in ["speed", "effect"]:
		var obj := Obj.new()
		obj.data = data
		return obj
	elif kind == "tap_white" || kind == "judge_red":
		var note: Node3D = tap_white_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "tap_yellow":
		var note: Node3D = tap_yellow_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "slider_left":
		var note: Node3D = slider_left_tscn.instantiate()
		var obj := Obj.new()
		if data["direction"] == "right":
			note.get_node("note").material.set_shader_parameter("dir", 1.0)
			note.get_node("arrow").flip_h = true
		else:
			note.get_node("note").material.set_shader_parameter("dir", -1.0)
			note.get_node("arrow").flip_h = false
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "slider_right":
		var note: Node3D = slider_right_tscn.instantiate()
		var obj := Obj.new()
		if data["direction"] == "right":
			note.get_node("note").material.set_shader_parameter("dir", 1.0)
			note.get_node("arrow").flip_h = true
		else:
			note.get_node("note").material.set_shader_parameter("dir", -1.0)
			note.get_node("arrow").flip_h = false
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "slider_full":
		var note: Node3D = slider_full_tscn.instantiate()
		var obj := Obj.new()
		if data["direction"] == "right":
			note.get_node("note").material.set_shader_parameter("dir", 1.0)
			note.get_node("arrow").flip_h = true
		else:
			note.get_node("note").material.set_shader_parameter("dir", -1.0)
			note.get_node("arrow").flip_h = false
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "wide_red":
		var note: Node3D = wide_red_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "wide_blue":
		var note: Node3D = wide_blue_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = note
		root3d.add_child(note)
		return obj
	elif kind == "judge_blue":
		var note: Line2D = judge_blue_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = note
		hold2d.add_child(note)
		return obj
	elif kind == "hold":
		var poly: Polygon2D = hold_tscn.instantiate()
		var efe: Node3D = hold_effect_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = poly
		obj.node2 = efe
		efe.get_node("Sprite3D").modulate.a = 0.0
		poly.get_node("Line2D").width = MAX_HOLD_OUTLINE_WIDTH
		poly.get_node("Line2D2").width = MAX_HOLD_OUTLINE_WIDTH
		hold2d.add_child(poly)
		root3d.add_child(efe)
		return obj
	elif kind == "judge_white":
		var node: Node2D = judge_white_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = node
		judge_white_notes_node.add_child(node)
		return obj
	elif kind == "wheel":
		var node: Node3D = wheel_tscn.instantiate()
		var obj := Obj.new()
		obj.data = data
		obj.node = node
		node.position.x = data["lane"] - 2.5
		judge_white_notes_node.add_child(node)
		return obj
		
	return Obj.new()

func get_end_pos(obj: Obj) -> float:
	if obj.data["kind"] == "hold":
		return obj.data["endPos"]
	return obj.data["pos"]

var scroll_speed: float = 0.0
var basis_distance: float = 0.0
var basis_time: float = 0.0

var has_started: bool = false
var has_started_song: bool = false
var song_start_frame: int = 0

var latency_count: int = 0
var latency_total: float = 0
var audio_latency: float = 0.0
func action_before_started() -> void:
	latency_count += 1
	latency_total += AudioServer.get_output_latency()
	
	var frame: int = Engine.get_process_frames() - start_frame
	if frame < fade_in_frames:
		color_overlay.color = Color(0,0,0,1.0-float(frame)/float(fade_in_frames))
	elif frame == fade_in_frames:
		color_overlay.color = Color(0,0,0,0)
	elif frame < fade_in_frames + wait_frames0:
		pass
	elif frame < fade_in_frames + wait_frames0 + text_fade_out_frames:
		var x: float = (frame - (fade_in_frames + wait_frames0)) / float(text_fade_out_frames)
		var y: float = (1-x) ** 2
		upper_text_label.modulate.a = y
		upper_text_label2.modulate.a = y
		bottom_text_label.modulate.a = y
		var line_y: float = deco_line.points[0].y
		deco_line.points = PackedVector2Array([
			Vector2(0.5 * (1-y) * get_viewport().get_visible_rect().size.x, line_y),
			Vector2(0.5 * (1+y) * get_viewport().get_visible_rect().size.x, line_y)
		])
	elif frame == fade_in_frames + wait_frames0 + text_fade_out_frames:
		upper_text_label.hide()
		upper_text_label2.hide()
		bottom_text_label.hide()
		deco_line.hide()
	elif frame < fade_in_frames + wait_frames0 + text_fade_out_frames + wait_before_start_frames:
		pass
	else:
		var status := ResourceLoader.load_threaded_get_status(song_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			has_started = true
			song_start_frame = Engine.get_process_frames()
			audio_latency = latency_total / latency_count
			print("audio latency:", audio_latency)
		elif status == ResourceLoader.THREAD_LOAD_FAILED || status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			assert(false, "something was wrong with loading song: %" % status)
	
	make_game_input_data(0.0)
func start_song() -> void:
	var stream := ResourceLoader.load_threaded_get(song_path)
	audio_player.stream = stream
	audio_player.play()

var next_obj_index: int = 0
var displayed_objs: Array[Obj] = []
func time2distance(time: float) -> float:
	return (time - basis_time) * scroll_speed + basis_distance
func pos2distance(pos: float, current_distance: float) -> float:
	return (current_distance - pos) * ONE_DISTANCE * speed_gain

func update_obj(obj: Obj, current_distance: float) -> void:
	var distance: float = pos2distance(obj.data["pos"], current_distance)
	var kind: String = obj.data["kind"]
	if kind == "line":
		#print(distance)
		var line: Line2D = obj.node
		line.points = AiUtils.safe_unprojection_line(
			camera,
			Vector3(-3, 0, distance),
			Vector3(3, 0, distance)
		)
	elif kind == "tap_white" \
		|| kind == "tap_yellow" \
		|| kind == "slider_left" \
		|| kind == "slider_right" \
		|| kind == "slider_full" \
		|| kind == "wide_red" \
		|| kind == "wide_blue" \
		|| kind == "judge_red":
		var note: Node3D = obj.node
		if kind == "judge_red" && distance > 0:
			note.visible = false
		else:
			note.position = Vector3(obj.data["lane"] - 3.0, 0, distance)
		
		# なんでこんなことしないといけないんだよ！
		if note.visible && kind in ["tap_white", "judge_red"]:
			note.position.x += note.position.z * 0.002
	elif kind == "hold":
		var poly: Polygon2D = obj.node
		var x: float = obj.data["lane"] - 3.0
		var end_x: float = obj.data["endLane"] - 3.0
		var end_distance: float = pos2distance(obj.data["endPos"], current_distance)
		
		# modified x
		var mx := x
		var md := distance
		
		if distance > 0:
			md = 0
			mx = x + (end_x - x) \
				* (-distance / (end_distance - distance))
		
		poly.polygon = AiUtils.safe_unprojection_polygon(
			camera, 
			[
				Vector3(mx, 0, md),
				Vector3(mx+1, 0, md),
				Vector3(end_x+1, 0, end_distance),
				Vector3(end_x, 0, end_distance),
			]
		)
		var line0: Line2D = poly.get_node("Line2D")
		var line1: Line2D = poly.get_node("Line2D2")
		var upl0 := AiUtils.safe_unprojection_line_with_width(
			camera,
			Vector3(mx, 0, md),
			Vector3(end_x, 0, end_distance),
			HOLD_OUTLINE_CONST / MAX_HOLD_OUTLINE_WIDTH
		)
		line0.points = PackedVector2Array([upl0.from_pos, upl0.to_pos])
		line0.width_curve = upl0.width_curve
		
		var upl1 := AiUtils.safe_unprojection_line_with_width(
			camera,
			Vector3(mx+1, 0, md),
			Vector3(end_x+1, 0, end_distance),
			HOLD_OUTLINE_CONST / MAX_HOLD_OUTLINE_WIDTH
		)
		line1.points = PackedVector2Array([upl1.from_pos, upl1.to_pos])
		line1.width_curve = upl1.width_curve
		
		obj.node2.position = Vector3(mx, 0, 1e-6)
		var sprite: Sprite3D = obj.node2.get_node("Sprite3D")
		var target_a: float = 0
		if distance > 0:
			if is_lane_pushed(mx + 3.0):
				target_a = 1.0
		sprite.modulate.a += (target_a - sprite.modulate.a) * 0.2
	elif kind == "judge_blue":
		var line: Line2D = obj.node
		if distance > 0:
			line.visible = false
		else:
			var x: float = obj.data["lane"] - 3.0
			line.points = AiUtils.safe_unprojection_line(
				camera,
				Vector3(x, 0, distance),
				Vector3(x+1, 0, distance)
			)
			var w: float = HOLD_OUTLINE_CONST / absf((camera.global_transform.affine_inverse() * Vector3(x+0.5, 0, distance)).z)
			line.width = w
	elif kind == "judge_white":
		var node: Node2D = obj.node
		if distance > 0.0:
			node.visible = false
		else:
			node.visible = true
			var x: float = obj.data["lane"] - 3.0
			var p := Vector3(x+0.5,0.0,distance)
			node.position = camera.unproject_position(p)
			var scale_: float = 2.0 / absf((camera.global_transform.affine_inverse() * p).z)
			node.scale = Vector2(scale_,scale_)
	elif kind == "wheel":
		obj.node.position.z = distance

enum SingleInputType {
	Push,
	Release,
	SlideRedLeft,
	SlideRedRight,
	SlideBlueLeft,
	SlideBlueRight,
}
class SingleInput:
	var lane: float = 0.0
	var time: float = 0.0
	var type: SingleInputType = SingleInputType.Push
	static func gen(lane_: float, time_: float, type_: SingleInputType)  -> SingleInput:
		var si := SingleInput.new()
		si.lane = lane_
		si.time = time_
		si.type = type_
		return si
class GameInput:
	# 直前のフレームから今のフレームまでの間に受け取った入力のリスト
	var array: Array[SingleInput] = []
	# 今長押し入力されてるレーン(float)のリスト
	var pushed_lanes: Array[float] = []
	# それぞれのスライダーの現在の位置
	var red_slider_lane: float = 0.0
	var blue_slider_lane: float = 4.0
var game_input: GameInput = GameInput.new()
func make_game_input_data(current_time: float) -> void:
	game_input.array.clear()
	game_input.pushed_lanes.clear()
	
	const key_event_names: Array[String] = ["keyS", "keyD", "keyF", "keyJ", "keyK", "keyL"]
	for i in range(6):
		var event_name := key_event_names[i]
		if Input.is_action_just_pressed(event_name):
			game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.Push))
			if i < 3:
				game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.SlideRedLeft))
				game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.SlideRedRight))
			else:
				game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.SlideBlueLeft))
				game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.SlideBlueRight))
		if Input.is_action_just_released(event_name):
			game_input.array.push_back(SingleInput.gen(float(i), current_time, SingleInputType.Release))
		if Input.is_action_pressed(event_name):
			game_input.pushed_lanes.push_back(float(i))
	
	# controller
	var joypads: Array[int] = Input.get_connected_joypads()
	if joypads:
		var index = joypads[0]
		@warning_ignore("int_as_enum_without_cast")
		game_input.red_slider_lane = (Input.get_joy_axis(index, 0) - 0.26) / 0.43 * 2
		@warning_ignore("int_as_enum_without_cast")
		game_input.blue_slider_lane = 4.0 - (Input.get_joy_axis(index, 1) - 0.26) / 0.42 * 2
		
		if Utils.joy_button_just_pressed(0):
			game_input.array.push_back(SingleInput.gen(game_input.red_slider_lane, current_time, SingleInputType.Push))
		if Utils.joy_button_just_pressed(1):
			game_input.array.push_back(SingleInput.gen(game_input.red_slider_lane + 1.0, current_time, SingleInputType.Push))
		if Utils.joy_button_just_pressed(2):
			game_input.array.push_back(SingleInput.gen(game_input.blue_slider_lane, current_time, SingleInputType.Push))
		if Utils.joy_button_just_pressed(3):
			game_input.array.push_back(SingleInput.gen(game_input.blue_slider_lane + 1.0, current_time, SingleInputType.Push))
		
		if Utils.joy_button_pressed(0):
			game_input.pushed_lanes.push_back(game_input.red_slider_lane)
		if Utils.joy_button_pressed(1):
			game_input.pushed_lanes.push_back(game_input.red_slider_lane + 1.0)
		if Utils.joy_button_pressed(2):
			game_input.pushed_lanes.push_back(game_input.blue_slider_lane)
		if Utils.joy_button_pressed(3):
			game_input.pushed_lanes.push_back(game_input.blue_slider_lane + 1.0)
		
		if Utils.joy_button_just_pressed(4):
			game_input.array.push_back(SingleInput.gen(1.0, current_time, SingleInputType.SlideRedLeft))
		if Utils.joy_button_just_pressed(5):
			game_input.array.push_back(SingleInput.gen(1.0, current_time, SingleInputType.SlideRedRight))
		if Utils.joy_button_just_pressed(6):
			game_input.array.push_back(SingleInput.gen(1.0, current_time, SingleInputType.SlideBlueLeft))
		if Utils.joy_button_just_pressed(7):
			game_input.array.push_back(SingleInput.gen(1.0, current_time, SingleInputType.SlideBlueRight))
	else:
		game_input.red_slider_lane = sin(Engine.get_process_frames() / 20.0) * 0.5 + 0.5
		game_input.blue_slider_lane = 3.5 - sin(Engine.get_process_frames() / 20.0) * 0.5

@onready var effects_node: Node2D = $svc/sv/Front2D/svc2d/sv/effects
var effect_tscn: PackedScene = preload("res://effect.tscn")
var effects_array: Array[Node2D] = []
func place_effect_on_lane(lane: float) -> void:
	var node: Node2D = effect_tscn.instantiate()
	node.position = camera.unproject_position(Vector3(lane + 0.5 - 3.0, 0, 0))
	node.scale = Vector2(1,1) * 0.1
	effects_node.add_child(node)
	effects_array.push_back(node)
func update_effects() -> void:
	for i: int in range(len(effects_array)-1,-1,-1):
		var sprite: Sprite2D = effects_array[i].get_node("Sprite2D")
		sprite.scale += Vector2(1,1) * 0.4
		sprite.modulate.a = 1.0 - max(0, (sprite.scale.x - 5.0) / 3.0)
		if sprite.scale.x >= 8.0:
			effects_array.pop_at(i).queue_free()
var effect2_tscn: PackedScene = preload("res://effect2.tscn")
var effect2_array: Array[Node3D] = []
var effect2_count: Array[int] = []
@onready var effect_node3d: Node3D = $svc/sv/svc3d/sv/effects
func place_effect2_on_lane(lane: float) -> void:
	var node: Node3D = effect2_tscn.instantiate()
	node.position = Vector3(lane - 3.0, 0, 0)
	effect_node3d.add_child(node)
	effect2_array.push_back(node)
	effect2_count.push_back(0)
func update_effect2() -> void:
	for i: int in range(len(effect2_array)-1,-1,-1):
		var node: Node3D = effect2_array[i]
		var sprite: Sprite3D = node.get_node("Sprite3D")
		var count: int = effect2_count[i]
		effect2_count[i] += 1
		sprite.modulate.a = min((1.0 - count / 20.0) * 4.0, 1.0)
		sprite.scale.y = (0.3 + min(count / 8.0, 1.0) * 1.2) * 0.55
		if count >= 20:
			effect2_array.pop_at(i).queue_free()
			effect2_count.pop_at(i)
var effect_slide_tscn: PackedScene = preload("res://effect_slide.tscn")
var effect_slide_array: Array[Node3D] = []
var effect_slide_dir: Array[int] = []
var effect_slide_count: Array[int] = []
func place_effect_slide_on_lane(lane: float, dir: int, long: bool = false) -> void:
	var node: Node3D = effect_slide_tscn.instantiate()
	var sprite: CSGBox3D = node.get_node("plane")
	if long:
		sprite.size.x = 10.0 / 3.0
	node.position = Vector3(lane - 2.5, 0, 0)
	effect_node3d.add_child(node)
	effect_slide_array.push_back(node)
	effect_slide_dir.push_back(dir)
	effect_slide_count.push_back(0)
	if dir < 0:
		node.rotation.y = PI
	node.position.x -= dir * 0.5
func update_effect_slide() -> void:
	for i: int in range(len(effect_slide_array)-1,-1,-1):
		var node: Node3D = effect_slide_array[i]
		var sprite: CSGBox3D = node.get_node("plane")
		var count: int = effect_slide_count[i]
		effect_slide_count[i] += 1
		sprite.set_instance_shader_parameter("a", maxf(1.0 - count / 20.0, 0.0))
		node.position.x += effect_slide_dir[i] * 0.05
		if count >= 20:
			effect_slide_array.pop_at(i).queue_free()
			effect_slide_dir.pop_at(i)
			effect_slide_count.pop_at(i)

@onready var judgement_node: Node2D = $svc/sv/Front2D/svc2d/sv/judgement
@onready var judgement_label: Label = $svc/sv/Front2D/svc2d/sv/judgement/judgement
@onready var combo_label: Label = $svc/sv/Front2D/svc2d/sv/combo
var combo: int = 0
var judgement_label_default_pos: Vector2

func set_combo(value) -> void:
	combo = value
	if value == 0:
		combo_label.text = ""
	else:
		combo_label.text = str(combo)
func count_combo() -> void:
	set_combo(combo + 1)
	info_overlay_data["Max Combo"] = max(info_overlay_data["Max Combo"], combo)
func reset_combo() -> void:
	set_combo(0)
func update_combo_color() -> void:
	var status: String = info_overlay_data["Status"]
	var color := Color.WHITE
	if status == "AP":
		color = Color("#fffdad")
	elif status == "FC":
		color = Color("#94d8ff")
	combo_label["theme_override_colors/font_color"] = color

var last_judgement_label_changed_frame: int = -100
func change_judgement_label_text(text: String, color: Color) -> void:
	judgement_label.text = text
	judgement_label["theme_override_colors/font_color"] = Color(color, judgement_a)
	last_judgement_label_changed_frame = Engine.get_process_frames()
func judgement_lerp(x: float) -> float:
	return -x*(2.0-x)
func update_judgement_label() -> void:
	var judgement_anim_frames: int = 10
	var scale_: float = 1.0 + 0.2 * judgement_lerp(min(1, (Engine.get_process_frames() - last_judgement_label_changed_frame) / float(judgement_anim_frames)))
	judgement_node.scale = Vector2(1,1) * scale_

@onready var info_overlay_key_label = $svc/sv/Front2D/svc2d/sv/info_overlay_key
@onready var info_overlay_value_label = $svc/sv/Front2D/svc2d/sv/info_overlay_value
var info_overlay_data: Dictionary = {
	"Perfect": 0,
	"Good": 0,
	"Bad": 0,
	"Miss": 0,
	"Damage": 0,
	"Max Combo": 0,
	"Late (tap)": 0,
	"Early (tap)": 0,
	"Late (slide)": 0,
	"Early (slide)": 0,
	"Status": "AP"
}
func update_info_overlay() -> void:
	var key_text: String = ""
	var value_text: String = ""
	for key in info_overlay_data:
		key_text += key + "\n"
		value_text += str(info_overlay_data[key]) + "\n"
	info_overlay_key_label.text = key_text
	info_overlay_value_label.text = value_text
func check_tap_late(lag: float) -> void:
	if lag > 0:
		info_overlay_data["Early (tap)"] += 1
	else:
		info_overlay_data["Late (tap)"] += 1
func check_slide_late(lag: float) -> void:
	if lag > 0:
		info_overlay_data["Early (slide)"] += 1
	else:
		info_overlay_data["Late (slide)"] += 1

@onready var dmg_sprite: Sprite2D = $svc/sv/Front2D/svc2d/sv/dmg_effect
var dmg_start_frame: int = -1
var dmg_duration_frame: int = 0
var dmg_strength: float = 0.0
var dmg_color: Color = Color.WHITE
var flip_target: float = 0.0
var flip_value_current: float = 0.0
var chr_start_frame: int = -1
var chr_duration_frame: int = 0
var chr_strength: float = 0.0
var chr_base: float = 0.0
func act_for_effect(effect_name: String) -> void:
	var array := effect_name.split(";")
	if array[0] == "dmg":
		dmg_start_frame = Engine.get_process_frames()
		dmg_color = Color(array[1])
		dmg_duration_frame = int(array[2])
		dmg_strength = float(array[3])
	elif array[0] == "flip":
		flip_target = float(array[1])
	elif array[0] == "chr":
		chr_start_frame = Engine.get_process_frames()
		chr_duration_frame = int(array[1])
		chr_strength = float(array[2])
	elif array[0] == "chr2":
		chr_base = float(array[1])

func update_post_effects() -> void:
	var f: int = Engine.get_process_frames()
	if dmg_start_frame >= 0 && f < dmg_start_frame + dmg_duration_frame:
		var p: float = float(f - dmg_start_frame) / float(dmg_duration_frame)
		var q: float = 1.0 - p
		dmg_sprite.modulate = dmg_color
		dmg_sprite.modulate.a = q * dmg_strength
	else:
		dmg_sprite.modulate.a = 0.0
	
	flip_value_current += (flip_target - flip_value_current) * 0.1
	set_effect_param("flip", flip_value_current)
	
	var chrom_val: float = 0.0
	if chr_start_frame >= 0 && f < chr_start_frame + chr_duration_frame:
		var p: float = float(f - chr_start_frame) / float(chr_duration_frame)
		var q: float = 1.0 - p
		chrom_val = q * chr_strength
	else:
		chrom_val = 0.0
	chrom_val += chr_base
	set_effect_param("chrom", chrom_val)

@onready var damage_sprite: Sprite2D = $svc/sv/Front2D/svc2d/sv/damage

enum Judgement {
	Perfect,
	Good,
	Bad,
	Miss,
	Damage
}
func act_for_judgement(j: Judgement, update_hp: bool = true) -> void:
	if update_hp:
		update_hp_for_judgement(j)
	if j == Judgement.Perfect:
		change_judgement_label_text("Perfect", MyParser.color_parse("yellow"))
		count_combo()
		info_overlay_data["Perfect"] += 1
	elif j == Judgement.Good:
		change_judgement_label_text("Good", MyParser.color_parse("cyan"))
		count_combo()
		info_overlay_data["Good"] += 1
		if info_overlay_data["Status"] == "AP":
			info_overlay_data["Status"] = "FC"
	elif j == Judgement.Bad:
		change_judgement_label_text("Bad", MyParser.color_parse("red"))
		reset_combo()
		info_overlay_data["Bad"] += 1
		info_overlay_data["Status"] = "NONE"
	elif j == Judgement.Miss:
		change_judgement_label_text("Miss", MyParser.color_parse("violet"))
		reset_combo()
		info_overlay_data["Miss"] += 1
		info_overlay_data["Status"] = "NONE"
	elif j == Judgement.Damage:
		change_judgement_label_text("Damage", MyParser.color_parse("red"))
		reset_combo()
		info_overlay_data["Damage"] += 1
		info_overlay_data["Status"] = "NONE"
		damage_sprite.modulate.a = 1.0
	else:
		assert(false, "Invalid judgement")
@export var max_judged_diff: float
@export var perfect_diff: float
@export var good_diff: float
@export var slider_judged_diff: float
@export var yellow_judged_lane_diff: float
@export var judge_white_lane_diff: float
# Missのときは基本的にそもそも判定すべきでないずれなのでただfalseを返してしまう仕様
# Earlyのときseconds > 0
func calc_judgement_s(seconds: float) -> Judgement:
	if absf(seconds) < perfect_diff:
		return Judgement.Perfect
	elif absf(seconds) < good_diff:
		return Judgement.Good
	elif absf(seconds) < max_judged_diff:
		return Judgement.Bad
	else:
		return Judgement.Miss

func is_lane_pushed(obj_lane: float, max_diff: float = 0.5) -> bool:
	for lane: float in game_input.pushed_lanes:
		if absf(lane - obj_lane) <= max_diff:
			return true
	return false

# そのkindに当てはまるJudgeされるノーツで一番手前にあるやつの番号を取得
# ロングノーツは非対応
func get_obj_judged(
	current_time: float,
	kinds: Array[String],
	lane: float,
	skip_tap_yellow: bool = false,
	time_diff: float = max_judged_diff,
	diff: float = 0.5
	) -> int:
	for i:int in range(len(displayed_objs)):
		var dict := displayed_objs[i].data
		if skip_tap_yellow:
			if (!displayed_objs[i].has_already_used) \
				&& dict["kind"] == "tap_yellow" \
				&& absf(lane - dict["lane"]) <= 0.5:
				return -1
		if dict["kind"] in kinds:
			if (not displayed_objs[i].has_already_used) \
				&& absf(current_time - dict["time"]) < time_diff:
				if lane < 0 || absf(lane - dict["lane"]) <= diff:
					return i
	return -1

func act_for_inputs(current_time: float, _current_distance: float) -> void:
	for i:int in range(len(displayed_objs)-1,-1,-1):
		var dict := displayed_objs[i].data
		var kind: String = dict["kind"]
		if dict["time"] > current_time:
			continue
		if kind == "speed" || kind == "effect":
			continue
		if kind == "wide_red" || kind == "wide_blue":
			if displayed_objs[i].has_already_used:
				continue
			else:
				displayed_objs[i].has_already_used = true
			if kind == "wide_red":
				if absf(game_input.red_slider_lane - dict["lane"]) < 0.5:
					act_for_judgement(Judgement.Perfect)
					place_effect_on_lane(dict["lane"] + 0.5)
				else:
					act_for_judgement(Judgement.Miss)
					displayed_objs[i].node.get_node("note").modulate.a = 0.5
					displayed_objs[i].node.get_node("mark").modulate.a = 0.5
			if kind == "wide_blue":
				if absf(game_input.blue_slider_lane - dict["lane"]) < 0.5:
					act_for_judgement(Judgement.Perfect)
					place_effect_on_lane(dict["lane"] + 0.5)
				else:
					act_for_judgement(Judgement.Miss)
					displayed_objs[i].node.get_node("note").modulate.a = 0.5
					displayed_objs[i].node.get_node("mark").modulate.a = 0.5
		elif kind == "judge_white":
			if displayed_objs[i].has_already_used:
				continue
			else:
				displayed_objs[i].has_already_used = true
			if is_lane_pushed(dict["lane"], judge_white_lane_diff):
				act_for_judgement(Judgement.Perfect)
				place_effect_on_lane(dict["lane"])
			else:
				act_for_judgement(Judgement.Miss)
			displayed_objs.pop_at(i).node.queue_free()
		elif kind == "tap_yellow":
			if displayed_objs[i].has_already_used:
				continue
			else:
				displayed_objs[i].has_already_used = true
			if is_lane_pushed(dict["lane"], yellow_judged_lane_diff):
				act_for_judgement(Judgement.Perfect)
				place_effect_on_lane(dict["lane"])
				place_effect2_on_lane(dict["lane"])
				displayed_objs.pop_at(i).node.queue_free()
				play_effect_weak()
			else:
				act_for_judgement(Judgement.Miss, false)
				update_hp_for_diff(hp_miss_yellow)
				
				displayed_objs[i].node.get_node("note").modulate.a = 0.5
		elif kind == "wheel":
			if displayed_objs[i].has_already_used:
				continue
			else:
				displayed_objs[i].has_already_used = true
			const nerf: float = 0.2
			if absf((game_input.red_slider_lane + 1.0) - (dict["lane"] + 0.5)) < 1.0 - nerf \
			or absf((game_input.blue_slider_lane + 1.0) - (dict["lane"] + 0.5)) < 1.0 - nerf:
				act_for_judgement(Judgement.Damage)
	
	for si: SingleInput in game_input.array:
		var input_time: float = si.time
		if si.type == SingleInputType.Push:
			var i := get_obj_judged(current_time, ["tap_white", "judge_red"], si.lane, true)
			if i < 0:
				continue
			var lag: float = displayed_objs[i].data["time"] - input_time
			var judgement := calc_judgement_s(lag)
			act_for_judgement(judgement)
			check_tap_late(lag)
			if judgement == Judgement.Perfect:
				play_effect_tap()
			elif judgement == Judgement.Good:
				play_effect_weak_tap()
			if judgement != Judgement.Bad:
				place_effect_on_lane(displayed_objs[i].data["lane"])
				place_effect2_on_lane(displayed_objs[i].data["lane"])
			if displayed_objs[i].data["kind"] == "tap_white":
				displayed_objs.pop_at(i).node.queue_free()
			else:
				displayed_objs[i].has_already_used = true
		elif si.type == SingleInputType.Release:
			var i := get_obj_judged(input_time, ["tap_blue", "judge_blue"], si.lane)
			if i < 0:
				continue
			if displayed_objs[i].data["kind"] != "judge_blue" || is_hold_end_enabled:
				displayed_objs[i].has_already_used = true
				var judgement := calc_judgement_s(displayed_objs[i].data["time"] - input_time)
				act_for_judgement(judgement)
				if displayed_objs[i].data["kind"] == "tap_blue":
					play_effect_tap()
				place_effect_on_lane(displayed_objs[i].data["lane"])
				if displayed_objs[i].data["kind"] == "judge_blue":
					displayed_objs.pop_at(i).node.queue_free()
		elif si.type in [SingleInputType.SlideRedLeft,
						 SingleInputType.SlideRedRight,
						 SingleInputType.SlideBlueLeft,
						 SingleInputType.SlideBlueRight]:
			var slider_colored: String = "slider_left"
			if si.type in [SingleInputType.SlideBlueLeft,
						   SingleInputType.SlideBlueRight]:
				slider_colored = "slider_right"
			var direction: String = "left"
			if si.type in [SingleInputType.SlideRedRight,
						   SingleInputType.SlideBlueRight]:
				direction = "right"
			var i := get_obj_judged(input_time, [slider_colored, "slider_full"], -1, false, slider_judged_diff)
			if i < 0 || displayed_objs[i].data["direction"] != direction:
				continue
			play_effect_slide()
			var lag: float = displayed_objs[i].data["time"] - input_time
			act_for_judgement(Judgement.Perfect)
			check_slide_late(lag)
			play_effect_tap()
			var dir: int = 1 if direction == "right" else -1
			if displayed_objs[i].data["kind"] == "slider_full":
				place_effect_on_lane(displayed_objs[i].data["lane"] + 2.5)
				place_effect_slide_on_lane(displayed_objs[i].data["lane"] + 2.5, dir, true)
			else:
				place_effect_on_lane(displayed_objs[i].data["lane"] + 1)
				place_effect_slide_on_lane(displayed_objs[i].data["lane"] + 1, dir)
			displayed_objs.pop_at(i).node.queue_free()

var song_started_frame: int = 0
var time_bias: float = 0.0
var audio_has_finished: bool = false
var audio_fix_count: int = 0
func _on_audio_finished() -> void:
	if !audio_has_finished:
		audio_has_finished = true
func update_Objs() -> void:
	var current_time: float = 0.0
	var current_distance: float = 0.0
	
	if Input.is_action_just_pressed("keySpace"):
		if audio_player.playing:
			const debug_audio_duration: float = 1.0
			audio_player.seek(audio_player.get_playback_position() + debug_audio_duration)
			time_bias += debug_audio_duration
	
	if !has_started_song:
		current_time = (basis_distance / scroll_speed) + (Engine.get_process_frames() - song_start_frame) / 60.0 - audio_latency
		current_distance = current_time * scroll_speed
		if current_time >= -audio_latency:
			has_started_song = true
			start_song()
			audio_has_finished = false
			audio_player.finished.connect(_on_audio_finished)
			song_started_frame = Engine.get_process_frames()
			basis_time = 0.0
			basis_distance = 0.0
	if has_started_song:
		current_time = (Engine.get_process_frames() - song_started_frame) / 60.0 + time_bias - audio_latency
		if !audio_has_finished:
			# https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html#class-audiostreamplayer-method-get-playback-position
			var pp: float = audio_player.get_playback_position()
			var audio_time: float = pp + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
			var diff: float = audio_time - current_time
			if Engine.get_process_frames() > song_started_frame && pp == 0:
				audio_has_finished = true
			else:
				if absf(diff) > 0.03:
					audio_fix_count += 1
				else:
					audio_fix_count = 0
				if audio_fix_count >= 2:
					if audio_time > current_time:
						print("warn: fixed time+")
					else:
						print("warn: fixed time-")
					time_bias += audio_time - current_time
					current_time = audio_time
				else:
					var added_diff: float = diff * 0.2
					time_bias += added_diff
					current_time += added_diff
		current_distance = time2distance(current_time)
	
	make_game_input_data(current_time)
	
	while next_obj_index < len(objs) && -pos2distance(objs[next_obj_index]["pos"], current_distance) < FAR_Z:
		var new_obj: Obj = new_Obj(objs[next_obj_index])
		if new_obj.data:
			displayed_objs.append(new_obj)
		next_obj_index += 1
	
	for obj in displayed_objs:
		if obj.data["pos"] < current_distance:
			var dict := obj.data
			if dict["kind"] == "speed" && not obj.has_already_used:
				scroll_speed = dict["ratio"]
				basis_time = dict["time"]
				basis_distance = dict["pos"]
				obj.has_already_used = true
	
	act_for_inputs(current_time, current_distance)
	
	for i:int in range(len(displayed_objs)-1,-1,-1):
		var kind: String = displayed_objs[i].data["kind"]
		if kind == "effect" && displayed_objs[i].data["time"] <= current_time:
			act_for_effect(displayed_objs.pop_at(i).data["name"])
			continue
		
		var delay: float = current_time - displayed_objs[i].data["time"]
		
		# 過ぎ去ったobjのmiss判定
		if !displayed_objs[i].has_already_used:
			if kind in ["tap_white", "judge_red"] && delay > max_judged_diff:
				displayed_objs[i].has_already_used = true
				displayed_objs[i].node.get_node("note").modulate.a = 0.5
				act_for_judgement(Judgement.Miss)
			if kind in ["slider_right", "slider_left", "slider_full"] && delay > slider_judged_diff:
				displayed_objs[i].has_already_used = true
				displayed_objs[i].node.get_node("arrow").modulate.a = 0.5
				displayed_objs[i].node.get_node("note").set_instance_shader_parameter("a", 0.5)
				act_for_judgement(Judgement.Miss)
			if kind == "judge_blue" && delay > max_judged_diff:
				if is_hold_end_enabled:
					displayed_objs[i].has_already_used = true
					act_for_judgement(Judgement.Miss)
		
		var is_to_delete: bool = false;
		if kind == "hold":
			is_to_delete = -pos2distance(get_end_pos(displayed_objs[i]), current_distance) < 0.0
		else:
			is_to_delete = delay > max(max_judged_diff, slider_judged_diff) && -pos2distance(get_end_pos(displayed_objs[i]), current_distance) < -DISAPPEAR_Z
		if is_to_delete:
			var deleted_obj: Obj = displayed_objs.pop_at(i)
			if deleted_obj.node is Node:
				deleted_obj.node.queue_free()
			if deleted_obj.node2 is Node:
				deleted_obj.node2.queue_free()
	
	for obj:Obj in displayed_objs:
		update_obj(obj, current_distance)

var chart_finished: bool = false
func check_chart_finished() -> bool:
	if !chart_finished && audio_has_finished && next_obj_index >= len(objs) && len(displayed_objs) == 0:
		chart_finished = true
		color_overlay.color.a = 0
	if chart_finished:
		color_overlay.color.a += 0.03
		if color_overlay.color.a >= 1.3:
			show_result()
			return true
	return false

@onready var ghost_red: Sprite3D = $svc/sv/svc3d/sv/GhostRed
@onready var ghost_blue: Sprite3D = $svc/sv/svc3d/sv/GhostBlue
@onready var ghost_of_ghosts: Node3D = $svc/sv/svc3d/sv/GhostOfGhosts
var ghost_ghost_red_tscn: PackedScene = preload("res://ghost_ghost_red.tscn")
var ghost_ghost_blue_tscn: PackedScene = preload("res://ghost_ghost_blue.tscn")
var ghosts_array: Array[Node3D] = []
func update_ghosts() -> void:
	ghost_red.position.x = game_input.red_slider_lane - 2.0
	ghost_blue.position.x = game_input.blue_slider_lane - 2.0
	
	for i: int in range(len(ghosts_array)-1,-1,-1):
		var sprite: Sprite3D = ghosts_array[i].get_node("ghost")
		sprite.modulate.a -= 0.003
		if sprite.modulate.a <= 0.0:
			ghosts_array.pop_at(i).queue_free()
	
	if Engine.get_process_frames() % 10 == 0:
		var new_red_ghost: Node3D = ghost_ghost_red_tscn.instantiate()
		new_red_ghost.position = ghost_red.position
		new_red_ghost.get_node("ghost").modulate.a = 0.3
		var new_blue_ghost: Node3D = ghost_ghost_blue_tscn.instantiate()
		new_blue_ghost.position = ghost_blue.position
		new_blue_ghost.get_node("ghost").modulate.a = 0.3
		
		ghost_of_ghosts.add_child(new_red_ghost)
		ghost_of_ghosts.add_child(new_blue_ghost)
		
		ghosts_array.push_back(new_red_ghost)
		ghosts_array.push_back(new_blue_ghost)

var highlights: Array[Node3D] = []
var highlight_tscn: PackedScene = preload("res://highlight.tscn")
@onready var highlights_node: Node3D = $svc/sv/svc3d/sv/highlights
func init_highlights() -> void:
	for i in range(6):
		var hl: Node3D = highlight_tscn.instantiate()
		hl.position = Vector3(i - 3.0, 0, -.01)
		highlights.push_back(hl)
		highlights_node.add_child(hl)
	update_highlights()
func update_highlights() -> void:
	for i in range(6):
		var a: float = 0.0
		var rd0: float = game_input.red_slider_lane - float(i)
		var rd1: float = game_input.red_slider_lane + 1.0 - float(i)
		var bd0: float = game_input.blue_slider_lane - float(i)
		var bd1: float = game_input.blue_slider_lane + 1.0 - float(i)
		if -0.5 <= rd0 && rd0 < 0.5:
			a = HIGHLIGHT_GHOST_A
		if -0.5 <= rd1 && rd1 < 0.5:
			a = HIGHLIGHT_GHOST_A
		if -0.5 < bd0 && bd0 <= 0.5:
			a = HIGHLIGHT_GHOST_A
		if -0.5 < bd1 && bd1 <= 0.5:
			a = HIGHLIGHT_GHOST_A
		for lane in game_input.pushed_lanes:
			var d: float = lane - float(i)
			if -0.5 <= d && d < 0.5:
				a = HIGHLIGHT_GHOST_A_2
				break
		if a > highlights[i].modulate.a:
			highlights[i].modulate.a = a
		else:
			highlights[i].modulate.a += (a - highlights[i].modulate.a) * 0.15

var result_tscn: PackedScene = preload("res://result.tscn")
var difficulty: String = ""
var diff_num: String = "-"
func show_result() -> void:
	var new_scene := result_tscn.instantiate()
	new_scene.info_dict = info_overlay_data
	new_scene.upper_text = song_upper_text
	new_scene.bottom_text = song_bottom_text
	new_scene.song_color = song_color
	new_scene.difficulty = difficulty
	new_scene.has_crashed = hp_has_crashed
	new_scene.diff_num = diff_num
	print(difficulty)
	get_tree().root.add_child(new_scene)
	self.queue_free()

var hp_enabled: bool = false
var hp_max: float = 100.0
var hp_judge_map: Dictionary[Judgement, float] = {
	Judgement.Perfect: 1.0,
	Judgement.Good: 0.0,
	Judgement.Bad: -2.0,
	Judgement.Miss: -5.0,
	Judgement.Damage: -5.0,
}
var hp_miss_yellow: float = -1.0
var hp_score: float = 70.0
var hp_has_crashed: bool = false
@onready var hp_box: Sprite2D = $svc/sv/Front2D/svc2d/sv/HP/HpBox
@onready var hp_bar: Node2D = $svc/sv/Front2D/svc2d/sv/HP/bar
@onready var hp_bar_sprite: Sprite2D = $svc/sv/Front2D/svc2d/sv/HP/bar/Hp2
@onready var crashed_label: Label = $svc/sv/Front2D/svc2d/sv/HP/crashed
func update_hp_for_judgement(j: Judgement):
	update_hp_for_diff(hp_judge_map[j])
func update_hp_for_diff(diff: float):
	if !hp_enabled: return
	if hp_has_crashed: return
	
	hp_score += diff
	
	if hp_max - hp_score < 1e-6:
		hp_score = hp_max
	elif hp_score < 1e-6:
		hp_score = 0.0
	if hp_score == 0.0:
		hp_has_crashed = true
		crashed_label.visible = true
func update_hp_ui() -> void:
	if !hp_enabled: return
	
	var y: float = float(hp_score) / float(hp_max)
	if y <= 0.0:
		hp_bar.visible = false
	else:
		hp_bar.visible = true
		hp_bar.scale.y = y
	var color: Color = Color.WHITE
	if y <= 0.3:
		color = MyParser.color_parse("red")
	hp_bar_sprite.modulate = color
	hp_box.modulate = color

func _exit_tree() -> void:
	audio_player.stop()
	effect_tap_player.stop()

@onready var volume_data := MyParser.load_volume()
func _ready() -> void:
	Utils.joy_button_load()
	
	judgement_label_default_pos = judgement_label.position
	
	song_config = MyParser.load_a_chart_config(chart_name)
	difficulty = song_config["difficulty"]
	if "diff_num" in song_config:
		diff_num = str(song_config["diff_num"])
	is_hold_end_enabled = "hold-end" in song_config && song_config["hold-end"] == "ON"
	print("is_hold_end_enabled: ", is_hold_end_enabled)
	
	if "speedGain" in song_config:
		speed_gain *= float(song_config["speedGain"])
		print(speed_gain)
	
	chart = MyParser.load_chart(chart_name)
	objs = chart["objs"]
	if "audioOffset" in chart:
		audio_offset = chart["audioOffset"]
		if audio_offset != 0.0:
			var pos_offset: float = -MyParser.get_initial_speed(chart) * audio_offset
			for obj in objs:
				obj["time"] += -audio_offset
				obj["pos"] += pos_offset
				if "endPos" in obj:
					obj["endPos"] += pos_offset
	
	song_path = "res://content/songs/" + song_config.filename
	
	if song_config.filename in volume_data:
		var db: float = Utils.percent2db(volume_data[song_config.filename])
		audio_player.volume_db = db
	
	ResourceLoader.load_threaded_request(song_path)
	
	if "hp" in song_config:
		var hp_lines: PackedStringArray = song_config["hp"].split("\n")
		hp_enabled = hp_lines[0] == "ON"
		if hp_enabled:
			var hp_nums: Array[float] = []
			for e: String in hp_lines[1].split(","):
				hp_nums.push_back(float(e))
			hp_score = hp_nums[0]
			hp_max = hp_nums[1]
			hp_judge_map = {
				Judgement.Perfect: hp_nums[2],
				Judgement.Good: hp_nums[3],
				Judgement.Bad: hp_nums[4],
				Judgement.Miss: hp_nums[5],
				Judgement.Damage: hp_nums[6],
			}
			if len(hp_nums) >= 8:
				hp_miss_yellow = hp_nums[7]
			print(hp_judge_map)
	else:
		hp_enabled = false
	$svc/sv/Front2D/svc2d/sv/HP.visible = hp_enabled
	crashed_label.visible = false
	
	scroll_speed = MyParser.get_initial_speed(chart)
	var start_wait_frames = ceil(((FAR_Z / (ONE_DISTANCE * speed_gain * scroll_speed)) + max(audio_offset, 0)) * 60.0)
	basis_time = -start_wait_frames / 60.0
	basis_distance = scroll_speed * basis_time
	
	color_overlay.color = Color(0,0,0,1)
	
	if song_upper_text.begins_with("'"):
		upper_text_label2.text = song_upper_text.trim_prefix("'")
		upper_text_label.visible = false
		upper_text_label2.visible = true
	else:
		upper_text_label.text = song_upper_text
	upper_text_label.add_theme_color_override("font_color", song_color)
	upper_text_label2.add_theme_color_override("font_color", song_color)
	bottom_text_label.add_theme_color_override("font_color", song_color)
	bottom_text_label.text = song_bottom_text
	
	judgement_label.text = ""
	
	update_lines()
	init_highlights()
	
	update_hp_ui()
	
	reset_combo()

@onready var start_frame: int = Engine.get_process_frames()
func _process(_delta: float) -> void:
	Utils.joy_button_load()
	
	# この2つの関数のどっちでもmake_game_input_dataが呼ばれて使えるようになる
	if !has_started:
		action_before_started()
	else:
		update_Objs()
	
	if check_chart_finished():
		return
	
	update_lines()
	update_ghosts()
	update_highlights()
	update_effects()
	update_effect2()
	update_effect_slide()
	update_judgement_label()
	update_info_overlay()
	update_combo_color()
	update_hp_ui()
	damage_sprite.modulate.a *= 0.98
	update_post_effects()
