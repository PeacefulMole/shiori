extends TestBase

const VNLayoutEditor := preload("res://addons/shiori/scripts/vn_layout_editor.gd")
const LAYOUT_PATH := "user://test_layout_editor.json"

func _cleanup() -> void:
	if FileAccess.file_exists(LAYOUT_PATH):
		DirAccess.remove_absolute(LAYOUT_PATH)

func _editor(tree: SceneTree) -> VNLayoutEditor:
	var editor := VNLayoutEditor.new()
	editor.layout_path = LAYOUT_PATH
	tree.root.add_child(editor)
	await tree.process_frame
	return editor

func _control(tree: SceneTree, rect: Rect2) -> Control:
	var control := Control.new()
	control.position = rect.position
	control.size = rect.size
	tree.root.add_child(control)
	return control

func _texture() -> ImageTexture:
	return ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))

func _write(text: String) -> void:
	var file := FileAccess.open(LAYOUT_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func test_registration_editing_locking_and_english_ui() -> void:
	_cleanup()
	var tree := Engine.get_main_loop() as SceneTree
	var editor := await _editor(tree)
	var control := _control(tree, Rect2(10, 20, 100, 50))
	editor.register_target("panel", control)
	eq(editor.target_rect("panel"), Rect2(10, 20, 100, 50), "registered rect")
	editor.set_target_rect("panel", Rect2(30, 40, 100, 50))
	eq(editor.target_rect("panel"), Rect2(30, 40, 100, 50), "edited rect")
	editor.set_locked("panel", true)
	check(editor.is_locked("panel"), "target locked")
	editor.set_target_rect("panel", Rect2(60, 70, 100, 50))
	editor._resize_target("panel", 2)
	eq(editor.target_rect("panel"), Rect2(30, 40, 100, 50), "locked target unchanged")
	editor.set_locked("panel", false)
	editor._resize_target("panel", 1.5)
	eq(editor.target_rect("panel"), Rect2(30, 40, 150, 75), "unlocked proportional resize")
	eq(editor._inspector.title, "Layout Editor", "English window title")
	check(editor._fields.has("Scale %"), "English scale field")
	eq(editor._lock_check.text, "Lock element", "English lock label")
	eq(editor._add_button.text, "Add icon", "English add label")
	eq(editor._save_button.text, "Save layout", "English save label")
	eq(editor._reset_button.text, "Reset layout", "English reset label")
	control.free()
	editor.free()
	await tree.process_frame

func test_reference_and_icon_extras() -> void:
	_cleanup()
	var tree := Engine.get_main_loop() as SceneTree
	var editor := await _editor(tree)
	editor.reference_texture = _texture()
	eq(editor._mockup.texture, editor.reference_texture, "reference assigned")
	editor._opacity_slider.value = 0.25
	eq(editor._mockup.modulate.a, 0.25, "reference opacity")
	editor.register_icon("neutral", _texture())
	var button := editor.add_extra("neutral")
	check(button != null, "extra created")
	eq(editor._extras.size(), 1, "extra registered")
	if button != null:
		eq(button.size, Vector2(72, 72), "default extra size")
	check(editor.add_extra("missing") == null, "unknown icon rejected")
	editor.free()
	await tree.process_frame

func test_save_and_load_roundtrip() -> void:
	_cleanup()
	var tree := Engine.get_main_loop() as SceneTree
	var first := await _editor(tree)
	var original := _control(tree, Rect2(10, 20, 100, 50))
	first.register_target("panel", original)
	first.set_locked("panel", true)
	first.register_icon("neutral", _texture())
	first.add_extra("neutral")
	eq(first.save_layout(), OK, "layout saved")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	check(parsed is Dictionary, "JSON root")
	if parsed is Dictionary:
		eq(parsed.get("version"), 1, "schema version")
		check(parsed.get("targets", {}).has("panel"), "target serialized")
		eq(parsed.get("extras", []).size(), 1, "extra serialized")
	original.free()
	first.free()
	await tree.process_frame
	var second := await _editor(tree)
	var restored := _control(tree, Rect2(200, 200, 10, 10))
	second.register_target("panel", restored)
	second.register_icon("neutral", _texture())
	eq(second.load_layout(), OK, "layout loaded")
	eq(second.target_rect("panel"), Rect2(10, 20, 100, 50), "target restored")
	check(second.is_locked("panel"), "lock restored")
	eq(second._extras.size(), 1, "extra restored")
	restored.free()
	second.free()
	await tree.process_frame
	_cleanup()

func test_load_rejects_malformed_root_without_changes() -> void:
	_cleanup()
	var tree := Engine.get_main_loop() as SceneTree
	var editor := await _editor(tree)
	var control := _control(tree, Rect2(10, 20, 100, 50))
	editor.register_target("panel", control)
	_write("not json")
	eq(editor.load_layout(), ERR_PARSE_ERROR, "invalid JSON rejected")
	_write("[]")
	eq(editor.load_layout(), ERR_INVALID_DATA, "non-dictionary root rejected")
	eq(editor.target_rect("panel"), Rect2(10, 20, 100, 50), "target unchanged")
	control.free()
	editor.free()
	await tree.process_frame
	_cleanup()

func test_load_skips_invalid_entries() -> void:
	_cleanup()
	_write('{"version":1,"targets":{"panel":[1,2,30,40],"bad":[1,2]},"extras":[{"icon":"neutral","rect":[5,6,20,20]},{"icon":"missing","rect":[0,0,10,10]}],"locked":{}}')
	var tree := Engine.get_main_loop() as SceneTree
	var editor := await _editor(tree)
	var panel := _control(tree, Rect2())
	var bad := _control(tree, Rect2(50, 50, 10, 10))
	editor.register_target("panel", panel)
	editor.register_target("bad", bad)
	editor.register_icon("neutral", _texture())
	eq(editor.load_layout(), OK, "valid entries load")
	eq(editor.target_rect("panel"), Rect2(1, 2, 30, 40), "valid target applied")
	eq(editor.target_rect("bad"), Rect2(50, 50, 10, 10), "invalid target unchanged")
	eq(editor._extras.size(), 1, "valid extra applied")
	panel.free()
	bad.free()
	editor.free()
	await tree.process_frame
	_cleanup()

func test_reset_removes_only_the_layout_and_emits_signal() -> void:
	_cleanup()
	var tree := Engine.get_main_loop() as SceneTree
	var editor := await _editor(tree)
	_write('{"version":1,"targets":{},"extras":[],"locked":{}}')
	var emitted: Array = []
	editor.layout_reset.connect(func(path: String): emitted.append(path))
	editor.reset_layout()
	check(not FileAccess.file_exists(LAYOUT_PATH), "layout removed")
	eq(emitted, [LAYOUT_PATH], "reset signal")
	editor.free()
	await tree.process_frame
