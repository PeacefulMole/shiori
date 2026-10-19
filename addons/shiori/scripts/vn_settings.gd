class_name VNSettings
extends Node

signal changed

const PATH := "user://settings.json"

var text_speed := 40:
	set(value):
		text_speed = value
		changed.emit()
var music_volume := 70:
	set(value):
		music_volume = value
		changed.emit()
var fullscreen := false:
	set(value):
		fullscreen = value
		changed.emit()

func _ready() -> void:
	load()
	apply()

func save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("cannot write settings")
		return
	file.store_string(JSON.stringify({"text_speed": text_speed, "music_volume": music_volume, "fullscreen": fullscreen}))

func load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed == null or not parsed is Dictionary:
		push_error("corrupt settings file")
		return
	text_speed = int(parsed.get("text_speed", text_speed))
	music_volume = int(parsed.get("music_volume", music_volume))
	fullscreen = bool(parsed.get("fullscreen", fullscreen))

func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(music_volume / 100.0))
	if DisplayServer.get_name() != "headless":
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
