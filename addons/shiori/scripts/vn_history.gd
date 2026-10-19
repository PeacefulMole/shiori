class_name VNHistory
extends Node

signal entry_added(entry: Dictionary)

const MAX_ENTRIES := 300

var _entries: Array = []

func add_say(speaker: String, text: String) -> void:
	_append({"kind": "say", "speaker": speaker, "text": text})

func add_narration(text: String) -> void:
	_append({"kind": "narration", "text": text})

func get_entries() -> Array:
	return _entries.duplicate()

func clear() -> void:
	_entries.clear()

func _append(entry: Dictionary) -> void:
	if _entries.size() == MAX_ENTRIES:
		_entries.pop_front()
	_entries.append(entry)
	entry_added.emit(entry)
