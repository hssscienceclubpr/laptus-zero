class_name MyParser
extends Node

const color_dict: Dictionary[String, Color] = {
	"green": Color("#4bc43b"),
	"pink": Color("#ff43a4"),
	"yellow": Color("#eec843"),
	"red": Color("#ff3600"),
	"orange": Color("#ff6b00"),
	"brown": Color("#bb9a72"),
	"violet": Color("#8c00bd"),
	"insane": Color("#c56eff"),
	"cyan": Color("#1ca6e3"),
	"gray": Color("#82677a"),
	"blue": Color("#183ce7"),
}
const color_sub_dict: Dictionary[String, String] = {
	"easy": "green",
	"normal": "yellow",
	"hard": "red",
	"AP": "yellow",
	"FC": "cyan",
	"SS": "cyan",
	"S": "blue",
	"A": "red",
	"B": "orange",
	"C": "brown",
	"D": "violet",
	"E": "insane",
	"F": "gray",
}
static func color_parse(text: String) -> Color:
	if text in color_sub_dict:
		return color_dict[color_sub_dict[text]]
	elif text in color_dict:
		return color_dict[text]
	else:
		return Color(text)

# song_configs: Dictionary[song name, {props}]
static func load_a_chart_config(folder_name: String) -> Dictionary[String, String]:
	var text:String = FileAccess.open(
		"res://content/charts/"
		+ folder_name
		+ "/config.md",
		FileAccess.READ).get_as_text()
	
	var dict: Dictionary[String, String] = {}
	var current_key: String = ""
	var data: String = ""
	for line: String in text.split("\n"):
		if line.is_empty(): continue
		if line.begins_with("# "):
			if not current_key.is_empty():
				dict[current_key] = data
				data = ""
			var key: String = line.trim_prefix("# ")
			current_key = key
		else:
			if data.is_empty():
				data = line
			else:
				data += "\n" + line
	if not current_key.is_empty():
		dict[current_key] = data
	
	return dict

static func load_chart_configs() -> Dictionary[String, Dictionary]:
	var dir: DirAccess = DirAccess.open("res://content/charts")
	
	var configs: Dictionary[String, Dictionary] = {}
	
	dir.list_dir_begin()
	
	while true:
		var folder_name := dir.get_next()
		if folder_name.is_empty():
			break
		if dir.current_is_dir():
			configs[folder_name] = load_a_chart_config(folder_name)
	
	dir.list_dir_end()
	
	return configs

static func load_chart(chart_name: String) -> Dictionary:
	var text: String = FileAccess.open("res://content/charts/" + chart_name + "/chart.chart", FileAccess.READ).get_as_text()
	return JSON.parse_string(text.trim_prefix("%"))

static func get_initial_speed(chart: Dictionary) -> float:
	for note:Dictionary in chart["objs"]:
		if note["time"] > 0:
			break
		if note["kind"] == "speed":
			return note["ratio"]
	return 1.0

static func load_volume() -> Dictionary[String, float]:
	var dict: Dictionary[String, float] = {}
	
	var key: String = ""
	
	var text:String = FileAccess.open("res://content/volume.md", FileAccess.READ).get_as_text()
	for line: String in text.split("\n"):
		if line.begins_with("# "):
			key = line.trim_prefix("# ")
		elif key != "" && line.is_valid_float():
			dict[key] = float(line)
		else:
			key = ""
	
	return dict
