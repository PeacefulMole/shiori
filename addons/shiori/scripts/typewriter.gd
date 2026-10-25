class_name Typewriter
extends Label

signal text_completed

var _chars_per_sec := 40.0
var _elapsed := 0.0
var _typing := false

func start_text(text: String, chars_per_sec: int) -> void:
	self.text = text
	visible_characters = 0
	_chars_per_sec = max(chars_per_sec, 1)
	_elapsed = 0.0
	_typing = true
	set_process(true)

func get_state() -> Dictionary:
	return {
		"text": text,
		"visible_characters": visible_characters,
		"chars_per_sec": _chars_per_sec,
		"elapsed": _elapsed,
		"typing": _typing,
	}

func restore_state(state: Dictionary) -> void:
	text = state.text
	visible_characters = int(state.visible_characters)
	_chars_per_sec = float(state.chars_per_sec)
	_elapsed = float(state.elapsed)
	_typing = bool(state.typing)
	set_process(_typing)

func is_typing() -> bool:
	return _typing

func skip_to_end() -> void:
	if not _typing:
		return
	_typing = false
	set_process(false)
	visible_characters = get_total_character_count()
	text_completed.emit()

func _ready() -> void:
	set_process(_typing)

func _process(delta: float) -> void:
	if not _typing:
		return
	_elapsed += delta
	var total := get_total_character_count()
	var count := int(_elapsed * _chars_per_sec)
	if count >= total:
		visible_characters = total
		_typing = false
		set_process(false)
		text_completed.emit()
	else:
		visible_characters = count
