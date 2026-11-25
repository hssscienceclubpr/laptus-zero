extends Node2D

@export var left_x: int
@export var interval_y: int
@export var p_gain: float
@export var cursor_y: int
@export var dent: int
@export var huge_dent: int
@export var hide_frames: int

@export var settings_left_x: int
@export var settings_upper_y: int
@export var settings_interval_y: int
@export var settings_hide_x: int

@export var load_count_to_load: int

@export var transition_interval: int

@onready var bread_crumbs: Label = get_parent().get_node("Breadcrumbs")
@onready var chart_data_labels_node: Node = get_parent().get_node("ChartDataLabels")
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var back_sprite: Sprite2D = get_parent().get_node("Back")

@onready var volume_data := MyParser.load_volume()

var rail_tscn: PackedScene = preload("res://rail.tscn")

var current_cursor: int = 0
var anim_current_cursor: int = 0
var anim_current_link: String = ""
var current_link: String = ""

var hiding: bool = false
var anim_state_change_frame: int = -1
var anim_state_change_link: String = ""

var prev_links: Array[String] = []
var prev_cursors: Array[int] = []

class Element:
	var upper_text: String
	var bottom_text: String
	var color: Color
	var link: String

var flowchart: Dictionary[String, Array] = {}

var rails: Array[Node] = []

func parse_element(text: String) -> Element:
	var array: PackedStringArray = text.split(" | ")
	var elem: Element = Element.new()
	elem.link = array[0]
	elem.upper_text = array[1]
	elem.bottom_text = array[2]
	elem.color = MyParser.color_parse(array[3])
	return elem

func make_flowchart() -> void:
	var text:String = FileAccess.open("res://content/flowchart.md", FileAccess.READ).get_as_text()
	
	var current_name: String = ""
	var current_array: Array[Element] = []
	
	flowchart.clear()
	
	for line: String in text.split("\n"):
		if line.is_empty(): continue
		if line.begins_with("//"): continue
		
		if line.begins_with("# "):
			var link_name: String = line.trim_prefix("# ")
			if current_name.is_empty() && current_array.is_empty():
				current_name = link_name
			else:
				flowchart[current_name] = current_array
				current_array = []
				current_name = link_name
		else:
			current_array.push_back(parse_element(line))
	
	if not current_name.is_empty():
		flowchart[current_name] = current_array

func apply_breadcrumbs(text: String) -> void:
	bread_crumbs.text = text

func regenerate_from_reserved_action() -> void:
	anim_current_link = anim_state_change_link
	
	for rail: Node in rails:
		rail.queue_free()
	rails.clear()
	
	var i: int = 0
	for elem: Element in flowchart[anim_current_link]:
		var rail: Node = rail_tscn.instantiate()
		if elem.upper_text.begins_with("'"):
			rail.get_node("UpperText2").text = elem.upper_text.trim_prefix("'")
			rail.get_node("UpperText").visible = false
			rail.get_node("UpperText2").visible = true
		else:
			rail.get_node("UpperText").text = elem.upper_text
		rail.get_node("BottomText").text = elem.bottom_text
		rail.get_node("RailMask").modulate = elem.color
		rail.get_node("TailMask").modulate = elem.color
		
		rail.position = Vector2(left_x + huge_dent, 0) + Vector2(0, interval_y) * i
		i += 1
		
		add_child(rail)
		rails.append(rail)
	
	position = Vector2(0, cursor_y - current_cursor * interval_y)

func load_link(link: String, cursor: int) -> void:
	hiding = true
	anim_state_change_frame = Engine.get_process_frames() + hide_frames
	anim_state_change_link = link
	anim_current_cursor = current_cursor
	current_cursor = cursor
	
	current_link = link

func update_rails(delta: float, immediatly: bool = false) -> void:
	var gain: float = p_gain * delta
	if immediatly:
		gain = 1
		if hiding:
			hiding = false
			regenerate_from_reserved_action()
	else:
		if hiding && Engine.get_process_frames() > anim_state_change_frame:
			hiding = false
			regenerate_from_reserved_action()
	
	var cc: int = 0
	if hiding:
		cc = anim_current_cursor
	else:
		cc = current_cursor
	
	if hiding:
		for i:int in range(len(rails)):
			var rail_target_pos: Vector2 = Vector2(left_x + huge_dent, i * interval_y)
			rails[i].position += (rail_target_pos - rails[i].position) * gain
		return
	
	var target_pos: Vector2 = Vector2(0, cursor_y - cc * interval_y)
	position += (target_pos - position) * gain
	for i:int in range(len(rails)):
		var rail_target_pos: Vector2 = Vector2(left_x, 0) + Vector2(0, interval_y) * i
		if i != cc:
			rail_target_pos += Vector2(dent, 0)
		rails[i].position += (rail_target_pos - rails[i].position) * gain

func apply_highlight() -> void:
	for i:int in range(len(rails)):
		var v: bool = i == current_cursor
		rails[i].get_node("RailHighLight").visible = v
		rails[i].get_node("TailHighLight").visible = v

func select_action() -> void:
	var link: String = flowchart[current_link][current_cursor].link
	if link in flowchart:
		update_rails(0, true)
		prev_links.push_back(anim_current_link)
		prev_cursors.push_back(current_cursor)
		apply_breadcrumbs(" > ".join(prev_links + [link]))
		load_link(link, 0)
	elif link.begins_with("!"):
		open_song_settings()

@onready var chart_configs: Dictionary[String, Dictionary] = MyParser.load_chart_configs()

var chart_name_loading_song: String = ""
var already_loaded: bool = false
var load_count: int = 0
func check_song() -> void:
	var link: String = flowchart[current_link][current_cursor].link
	if hiding or not link.begins_with("!"):
		audio_player.stop()
		audio_player.stream = null
		chart_name_loading_song = ""
		load_count = 0
		already_loaded = false
		chart_data_labels_node.visible = false
		return
	var chart_name: String = link.trim_prefix("!")
	
	chart_data_labels_node.visible = !is_in_song_settings
	
	var diff_num: String = "-"
	if "diff_num" in chart_configs[chart_name]:
		diff_num = str(chart_configs[chart_name]["diff_num"])
	
	var config := chart_configs[chart_name]
	
	chart_data_labels_node.get_node("Difficulty").get_node("Label").text = \
		config["difficulty"] + " ( " + diff_num + " )"
	chart_data_labels_node.get_node("Artist").get_node("Label").text = config["artist"]
	chart_data_labels_node.get_node("Comment").get_node("Label").text = config["comment"]
	chart_data_labels_node.get_node("HoldEnd").visible = "hold-end" in config && config["hold-end"] == "ON"
	
	var filename: String = chart_configs[chart_name]["filename"]
	var path: String = "res://content/songs/" + filename
	if chart_name_loading_song != chart_name:
		audio_player.stop()
		audio_player.stream = null
		chart_name_loading_song = ""
		if load_count >= load_count_to_load:
			chart_name_loading_song = chart_name
			ResourceLoader.load_threaded_request(path)
			
			if filename in volume_data:
				var db: float = Utils.percent2db(volume_data[filename])
				audio_player.volume_db = db
			
			already_loaded = false
		load_count += 1
	
	if not already_loaded:
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var stream := ResourceLoader.load_threaded_get(path)
			audio_player.stream = stream
			audio_player.play()
			already_loaded = true
			load_count = 0

const song_settings_array: Array[Array] = [
	["Play", [""]],
	["Speed", ["normal", "very fast", "fast", "slow", "very slow"]],
	["SFX", ["ON", "OFF"]],
]
const speed_table: Dictionary[String, float] = {
	"normal": 1.2,
	"very fast": 2.0,
	"fast": 1.5,
	"slow": 1.0,
	"very slow": 0.7,
}
@onready var song_settings_node: Node = self.get_parent().get_node("Settings")
var song_settings_label_tscn: PackedScene = preload("res://song_settings_label.tscn")
var song_settings_label_default: Node = song_settings_label_tscn.instantiate()
var song_settings_underline_default = song_settings_label_default.get_node("Option").get_node("Underline")
var song_settings_labels: Array[Node] = []
var is_in_song_settings: bool = false
var song_settings_cursor: int = 0
var song_settings_line_length: float = 0
var song_settings_indexes: Array[int] = []
func generate_song_settings_labels() -> void:
	for label: Node in song_settings_labels:
		label.queue_free()
	song_settings_labels.clear()
	
	var i: int = 0
	
	for elem in song_settings_array:
		var settings_name: String = elem[0]
		var options: Array = elem[1]
		
		var label: Node = song_settings_label_tscn.instantiate()
		label.get_node("Name").text = settings_name
		label.get_node("Option").text = options[0]
		
		label.position = Vector2(settings_left_x, settings_upper_y) + Vector2(0, settings_interval_y) * i
		
		song_settings_node.add_child(label)
		song_settings_labels.append(label)
		song_settings_indexes.append(0)
		
		i += 1
	
	song_settings_labels[0].get_node("Name").modulate = MyParser.color_parse("brown")
func open_song_settings() -> void:
	update_song_settings(0, true)
	is_in_song_settings = true
	chart_data_labels_node.visible = false
	song_settings_cursor = 0
func close_song_settings() -> void:
	update_song_settings(0, true)
	is_in_song_settings = false
	chart_data_labels_node.visible = true
func update_song_settings(delta: float, immediatly: bool = false) -> void:
	var gain: float = p_gain * delta
	if immediatly:
		gain = 1
	
	var target_x: int = 0
	if !is_in_song_settings:
		target_x = settings_hide_x
	song_settings_node.position.x += (target_x - song_settings_node.position.x) * gain
	
	var i: int = 0
	for label: Node in song_settings_labels:
		var selected: bool = i == song_settings_cursor
		var name_label: Node = label.get_node("Name")
		var tri_node: Node = name_label.get_node("tri")
		var option_label: Node = label.get_node("Option")
		var underline_node: Node = option_label.get_node("Underline")
		tri_node.visible = selected
		underline_node.visible = selected && i > 0
		option_label.text = song_settings_array[i][1][song_settings_indexes[i]]
		if underline_node.visible:
			underline_node.clear_points()
			var s :Vector2 = song_settings_underline_default.get_point_position(1)
			var e :Vector2 = song_settings_underline_default.get_point_position(0)
			underline_node.add_point(s)
			underline_node.add_point((e-s) * song_settings_line_length + s)
		for _i in range(2):
			name_label.position.x += (int(selected) * 20 - name_label.position.x) * gain
		i += 1
	
	song_settings_line_length += (1.0 - song_settings_line_length) * gain * 1.3
func reset_when_move_cursor() -> void:
	song_settings_line_length = 0.05
func settings_select_action() -> bool:
	if song_settings_cursor == 0:
		return true
	else:
		if song_settings_indexes[song_settings_cursor] < len(song_settings_array[song_settings_cursor][1]) - 1:
			song_settings_indexes[song_settings_cursor] += 1
		else:
			song_settings_indexes[song_settings_cursor] = 0
	return false
func get_song_setting(key: String) -> String:
	for i:int in range(len(song_settings_array)):
		if song_settings_array[i][0] == key:
			return song_settings_array[i][1][song_settings_indexes[i]]
	print("invalid song settings key: %" % key)
	return ""

var is_in_transition: bool = false
var transition_frame_count: float = 0
@onready var transition_node: Node = self.get_parent().get_node("Transition")

func update_back() -> void:
	var target_x: float = 1304.0 - (bread_crumbs.text.count(">")) * 30.0;
	back_sprite.position.x += (target_x - back_sprite.position.x) * 0.1;

func _ready() -> void:
	Utils.joy_button_load()
	
	make_flowchart()
	for link_name: String in flowchart:
		var array: Array = flowchart[link_name]
		print("# ", link_name)
		for elem: Element in array:
			print(elem.link, " - ", elem.upper_text)
		print()
	
	load_link("main", 0)
	update_rails(0, true)
	apply_highlight()
	
	generate_song_settings_labels()
	update_song_settings(0, true)
	
	check_song()
	update_back()

func _exit_tree() -> void:
	audio_player.stop()
	audio_player.stream = null
	song_settings_label_default.free()

@onready var overlay_key0 = get_parent().get_node("KeyStrokeOverlay").get_node("key0")
@onready var overlay_key1 = get_parent().get_node("KeyStrokeOverlay").get_node("key1")
@onready var overlay_key2 = get_parent().get_node("KeyStrokeOverlay").get_node("key2")
@onready var overlay_key3 = get_parent().get_node("KeyStrokeOverlay").get_node("key3")
func update_keystrokeoverlay():
	overlay_key0.frame_coords.x = int(Utils.gen_pressed(0))
	overlay_key1.frame_coords.x = int(Utils.gen_pressed(1)) + 2
	overlay_key2.frame_coords.x = int(Utils.gen_pressed(2)) + 4
	overlay_key3.frame_coords.x = int(Utils.gen_pressed(3)) + 6

@onready var play_scene_resource: PackedScene = preload("res://play.tscn")
func _process(delta: float) -> void:
	Utils.joy_button_load()
	update_keystrokeoverlay()
	
	if is_in_transition:
		transition_frame_count += 1
		if transition_frame_count >= transition_interval:
			transition_frame_count = 0
			if transition_node.frame_coords.x + 1 == transition_node.hframes:
				var new_scene = play_scene_resource.instantiate()
				var elem: Element = flowchart[current_link][current_cursor]
				var chart_name: String = elem.link.trim_prefix("!")
				new_scene.chart_name = chart_name
				new_scene.song_upper_text = elem.upper_text
				new_scene.song_bottom_text = chart_configs[chart_name]["artist"]
				new_scene.song_color = elem.color
				new_scene.speed_gain = speed_table[get_song_setting("Speed")]
				new_scene.is_sfx_enabled = get_song_setting("SFX") == "ON"
				get_tree().root.add_child(new_scene)
				get_parent().queue_free()
				return
			transition_node.frame_coords.x += 1
		return
	
	update_rails(delta)
	update_song_settings(delta)
	
	
	if Utils.gen_just_pressed(2):
		if is_in_song_settings:
			if song_settings_cursor > 0:
				song_settings_cursor -= 1
			else:
				song_settings_cursor = len(song_settings_labels) - 1
			reset_when_move_cursor()
		else:
			if current_cursor > 0:
				current_cursor -= 1
			else:
				current_cursor = len(flowchart[current_link]) - 1
	if Utils.gen_just_pressed(3):
		if is_in_song_settings:
			if song_settings_cursor < len(song_settings_labels) - 1:
				song_settings_cursor += 1
			else:
				song_settings_cursor = 0
			reset_when_move_cursor()
		else:
			if current_cursor < len(flowchart[current_link]) - 1:
				current_cursor += 1
			else:
				current_cursor = 0
	if Utils.gen_just_pressed(1):
		if is_in_song_settings:
			close_song_settings()
		else:
			if not prev_links.is_empty():
				update_rails(0, true)
				apply_breadcrumbs(" > ".join(prev_links))
				load_link(prev_links.pop_back(), prev_cursors.pop_back())
	if Utils.gen_just_pressed(0):
		if is_in_song_settings:
			if settings_select_action():
				is_in_transition = true
				transition_node.visible = true
				audio_player.stop()
				return
		else:
			select_action()
	
	if not hiding:
		apply_highlight()
	
	check_song()
	update_back()
