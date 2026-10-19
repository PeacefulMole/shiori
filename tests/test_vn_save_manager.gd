extends TestBase

const SLOT := 90

func _cleanup() -> void:
	for slot in [SLOT, 1, 2, 3]:
		VNSaveManager.new().delete_slot(slot)

func test_roundtrip() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	var payload := {
		"scene": "scene1",
		"stack": [{"i": 3, "opt": -1}],
		"bg": "playground",
		"pose": "calm",
		"music": "wind",
	}
	saves.save_slot(SLOT, payload)
	var loaded := saves.load_slot(SLOT)
	eq(loaded.scene, "scene1", "scene")
	eq(loaded.stack.size(), 1, "stack size")
	eq(loaded.stack[0].i, 3, "stack index")
	eq(loaded.stack[0].opt, -1, "stack option")
	eq(loaded.bg, "playground", "bg")
	eq(loaded.pose, "calm", "pose")
	eq(loaded.music, "wind", "music")
	_cleanup()

func test_load_missing_slot() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	eq(saves.load_slot(SLOT), {}, "missing slot returns empty dict")

func test_version_and_date_added() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "scene1"})
	var loaded := saves.load_slot(SLOT)
	eq(loaded.version, 1, "version")
	check(loaded.date != "", "date set")
	_cleanup()

func test_list_slots_sorted() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(3, {"scene": "s"})
	saves.save_slot(1, {"scene": "s"})
	saves.save_slot(2, {"scene": "s"})
	eq(saves.list_slots(), [1, 2, 3], "sorted slots")
	_cleanup()

func test_get_slot_info() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "scene1"})
	var info := saves.get_slot_info(SLOT)
	eq(info.scene, "scene1", "info scene")
	check(info.date != "", "info date")
	_cleanup()

func test_delete_slot() -> void:
	_cleanup()
	var saves := VNSaveManager.new()
	saves.save_slot(SLOT, {"scene": "s"})
	saves.delete_slot(SLOT)
	eq(saves.load_slot(SLOT), {}, "deleted slot is empty")
	_cleanup()
