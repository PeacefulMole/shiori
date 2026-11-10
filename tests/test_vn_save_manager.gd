extends TestBase

const SLOT := 90

func _cleanup() -> void:
	var saves := VNSaveManager.new()
	for slot in [SLOT, 1, 2, 3]:
		saves.delete_slot(slot)
	saves.free()

func test_roundtrip() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	var payload := {
		"scene": "main_scene",
		"stack": [{"i": 3, "opt": -1}],
		"bg": "forest",
		"pose": "calm",
		"music": "theme",
	}
	saves.save_slot(SLOT, payload)
	var loaded := saves.load_slot(SLOT)
	eq(loaded.scene, "main_scene", "scene")
	eq(loaded.stack.size(), 1, "stack size")
	eq(loaded.stack[0].i, 3, "stack index")
	eq(loaded.stack[0].opt, -1, "stack option")
	eq(loaded.bg, "forest", "bg")
	eq(loaded.pose, "calm", "pose")
	eq(loaded.music, "theme", "music")
	_cleanup()
	saves.free()

func test_load_missing_slot() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	eq(saves.load_slot(SLOT), {}, "missing slot returns empty dict")
	saves.free()

func test_version_and_date_added() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "main_scene"})
	var loaded := saves.load_slot(SLOT)
	eq(loaded.version, 1, "version")
	check(loaded.date != "", "date set")
	_cleanup()
	saves.free()

func test_list_slots_sorted() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(3, {"scene": "s"})
	saves.save_slot(1, {"scene": "s"})
	saves.save_slot(2, {"scene": "s"})
	eq(saves.list_slots(), [1, 2, 3], "sorted slots")
	_cleanup()
	saves.free()

func test_get_slot_info() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "main_scene"})
	var info := saves.get_slot_info(SLOT)
	eq(info.scene, "main_scene", "info scene")
	check(info.date != "", "info date")
	_cleanup()
	saves.free()

func test_delete_slot() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "s"})
	saves.delete_slot(SLOT)
	eq(saves.load_slot(SLOT), {}, "deleted slot is empty")
	_cleanup()
	saves.free()

func test_list_slots_ignores_noncanonical_names() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	DirAccess.make_dir_recursive_absolute(VNSaveManager.SAVE_DIR)
	var path := VNSaveManager.SAVE_DIR + "/slot_backup.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	check(not saves.list_slots().has(0), "backup file does not become slot zero")
	DirAccess.remove_absolute(path)
	saves.free()
