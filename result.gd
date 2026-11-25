extends Node2D

@export var frame_fade_start: int
@export var frame_fade_range: int
@export var frame_line_anim_start: int
@export var frame_line_anim_range: int
@export var frame_m_loop: int
@export var m_loop_len: int
@export var frame_start_check_back: int
@export var frame_back_range: int

# 新しいシーンとして作られたときに外部から設定されるための変数
var upper_text: String = "Song name"
var bottom_text: String = "Artist name"
var song_color: Color = Color.WHITE
var difficulty: String = "Easy"
var diff_num: String = "-"
var has_crashed: bool = true
var info_dict: Dictionary = {
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

func calc_percent() -> float:
	var perfect: int = info_dict["Perfect"]
	var good: int = info_dict["Good"]
	var bad: int = info_dict["Bad"]
	var miss: int = info_dict["Miss"]
	var damage: int = info_dict["Damage"]
	var p: float = (perfect * 1.0 + good * 0.7 + bad * 0.1) \
		/ float(perfect + good + miss + bad + damage)
	p *= 100.0
	if p != p: # pがnanとか-nanになってるか確認
		p = 50.0
	return p
@onready var percent: float = calc_percent()

func calc_grade() -> String:
	var status: String = info_dict["Status"]
	if status == "NONE":
		print(percent)
		var s: float = percent
		if has_crashed:
			s -= 10.0
		if s >= 98:
			return "SS"
		elif s >= 95:
			return "S"
		elif s >= 90:
			return "A"
		elif s >= 85:
			return "B"
		elif s >= 75:
			return "C"
		elif s >= 65:
			return "D"
		elif s >= 50:
			return "E"
		else:
			return "F"
	else:
		return status

@onready var grade_line: Line2D = $Grade/DecoLine
@onready var black_overlay: ColorRect = $blackOverlay
@onready var start_frame: int = Engine.get_process_frames()
@onready var text_line: Line2D = $DecoLine
@onready var m_label: Label = $MessageLabel

var text_line_p0: Vector2 = Vector2.ZERO
var text_line_p1: Vector2 = Vector2.ZERO
var grade_line_p0: Vector2 = Vector2.ZERO
var grade_line_p1: Vector2 = Vector2.ZERO
var m_default_text: String = ""

@onready var crash_label: Label = $Crashed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Utils.joy_button_load()
	
	$Perfect/Num.text = str(info_dict["Perfect"])
	$Good/Num.text = str(info_dict["Good"])
	$Bad/Num.text = str(info_dict["Bad"])
	$Miss/Num.text = str(info_dict["Miss"])
	$Damage/Num.text = str(info_dict["Damage"])
	$MaxCombo/Num.text = str(info_dict["Max Combo"])
	$LateTap/Num.text = str(info_dict["Late (tap)"])
	$EarlyTap/Num.text = str(info_dict["Early (tap)"])
	$LateSlide/Num.text = str(info_dict["Late (slide)"])
	$EarlySlide/Num.text = str(info_dict["Early (slide)"])
	var upper_text_label := $UpperTextLabel
	var upper_text_label2 := $UpperTextLabel2
	var bottom_text_label := $BottomTextLabel
	if upper_text.begins_with("'"):
		upper_text_label2.text = upper_text.trim_prefix("'")
		upper_text_label.visible = false
		upper_text_label2.visible = true
	else:
		upper_text_label.text = upper_text
	bottom_text_label.text = bottom_text
	upper_text_label.add_theme_color_override("font_color", song_color)
	upper_text_label2.add_theme_color_override("font_color", song_color)
	bottom_text_label.add_theme_color_override("font_color", song_color)
	var difficulty_label := $Difficulty
	difficulty_label.text = difficulty + " ( " + diff_num + " )"
	difficulty_label.add_theme_color_override("font_color", MyParser.color_parse(difficulty.to_lower()))
	
	var grade_label: Label = $Grade
	var grade: String = calc_grade()
	print("grade: ", grade)
	var grade_color: Color = MyParser.color_parse(grade)
	grade_label.text = grade
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_line.modulate = grade_color
	
	$Percent.text = str("%.2f" % percent) + "%"
	crash_label.visible = has_crashed
	
	black_overlay.modulate.a = 1.0
	
	grade_line_p0 = grade_line.get_point_position(0)
	grade_line_p1 = grade_line.get_point_position(1)
	text_line_p0 = text_line.get_point_position(0)
	text_line_p1 = text_line.get_point_position(1)
	
	m_default_text = m_label.text

var has_started_back: bool = false
var started_back_frame: int = -1

"""
なぜかpreloadじゃなくてloadにすると動く
https://forum.godotengine.org/t/failed-to-instantiate-scene-state-of-snake-body-tscn-node-count-is-0-make-sure-the-packedscene-resource-is-valid/70264/9
"""
var main_tscn: PackedScene = load("res://main.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Utils.joy_button_load()
	
	if has_started_back:
		var ff: int = Engine.get_process_frames() - started_back_frame
		if ff < frame_back_range:
			var q: float = float(ff) / float(frame_back_range)
			var p: float = q * (2.0 - q)
			black_overlay.modulate.a = p
		else:
			var new_scene: Node = main_tscn.instantiate()
			get_tree().root.add_child(new_scene)
			self.queue_free()
		return
	
	var f: int = Engine.get_process_frames() - start_frame
	
	if f < frame_fade_start:
		black_overlay.modulate.a = 1.0
	elif f < frame_fade_start + frame_fade_range:
		black_overlay.modulate.a = (30 - f) / 30.0
	else:
		black_overlay.modulate.a = 0.0
	
	if f < frame_line_anim_start:
		grade_line.visible = false
		text_line.visible = false
	elif f < frame_line_anim_start + frame_line_anim_range:
		grade_line.visible = true
		text_line.visible = true
		var q: float = float(f - frame_line_anim_start) / float(frame_line_anim_range)
		var p: float = q * (2.0 - q)
		grade_line.points = PackedVector2Array([
			grade_line_p0 + (grade_line_p1 - grade_line_p0) * (1.0 - p) * 0.5,
			grade_line_p1 + (grade_line_p0 - grade_line_p1) * (1.0 - p) * 0.5,
		])
		text_line.points = PackedVector2Array([
			text_line_p0 + (text_line_p1 - text_line_p0) * (1.0 - p) * 0.5,
			text_line_p1 + (text_line_p0 - text_line_p1) * (1.0 - p) * 0.5,
		])
	else:
		grade_line.visible = true
		text_line.visible = true
		grade_line.points = PackedVector2Array([grade_line_p0, grade_line_p1])
		text_line.points = PackedVector2Array([text_line_p0, text_line_p1])
	
	@warning_ignore("integer_division")
	var m_count: int = (f / frame_m_loop) % m_loop_len
	m_label.text = m_default_text + ".".repeat(m_count)
	
	if has_crashed:
		crash_label.modulate.a = 1.0 - (1.0 - cos(f * 0.15)) * 0.3
	
	if f > frame_start_check_back:
		if Utils.gen_pressed(0) \
		&& Utils.gen_pressed(1) \
		&& Utils.gen_pressed(2) \
		&& Utils.gen_pressed(3):
			has_started_back = true
			black_overlay.modulate.a = 0.0
			grade_line.visible = true
			text_line.visible = true
			grade_line.points = PackedVector2Array([grade_line_p0, grade_line_p1])
			text_line.points = PackedVector2Array([text_line_p0, text_line_p1])
			started_back_frame = Engine.get_process_frames()
