class_name VNSaveManager
extends Node

signal slots_changed

const SAVE_DIR := "user://saves"

func save_slot(slot: int, payload: Dictionary) -> void:
	var data := payload.duplicate()
	data.version = 1
	data.date = Time.get_datetime_string_from_system()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("cannot write save slot %d" % slot)
		return
	file.store_string(JSON.stringify(data, "  "))
	slots_changed.emit()

func load_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(_slot_path(slot)):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error("corrupt save slot %d" % slot)
		return {}
	return parsed

func get_slot_info(slot: int) -> Dictionary:
	var data := load_slot(slot)
	if data.is_empty():
		return {}
	return {"date": data.get("date", ""), "scene": data.get("scene", "")}

func delete_slot(slot: int) -> void:
	if FileAccess.file_exists(_slot_path(slot)):
		DirAccess.remove_absolute(_slot_path(slot))
		slots_changed.emit()

func list_slots() -> Array:
	var slots: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return slots
	for name in dir.get_files():
		if name.begins_with("slot_") and name.ends_with(".json"):
			slots.append(int(name.trim_prefix("slot_").trim_suffix(".json")))
	slots.sort()
	return slots

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]
