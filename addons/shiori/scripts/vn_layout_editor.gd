class_name VNLayoutEditor
extends Control

signal layout_saved(path: String)
signal layout_reset(path: String)

const VNLayoutTarget := preload("res://addons/shiori/scripts/vn_layout_target.gd")

var layout_path := "user://layout.json"
var reference_texture: Texture2D:
	set(value):
		reference_texture = value
		if is_instance_valid(_mockup):
			_mockup.texture = value
			_mockup.visible = value != null

var _mockup: TextureRect
var _outline: ReferenceRect
var _inspector: Window
var _list: ItemList
var _fields := {}
var _opacity_slider: HSlider
var _lock_check: CheckBox
var _add_popup: PopupMenu
var _add_button: Button
var _save_button: Button
var _reset_button: Button
var _status: Label
var _targets := {}
var _default_sizes := {}
var _icons := {}
var _extras: Array = []
var _locks := {}
var _selected := ""
var _extra_serial := 0
var _dragging := false
var _drag_offset := Vector2.ZERO
var _updating := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_reference()
	_build_outline()
	_build_inspector()
	call_deferred("_position_inspector")

func register_target(id: String, node: CanvasItem, getter: Callable = Callable(), setter: Callable = Callable()) -> void:
	if id.is_empty() or node == null:
		return
	var target := VNLayoutTarget.new(id, node, getter, setter)
	_targets[id] = target
	_default_sizes[id] = target.get_rect().size
	_refresh_list()

func register_icon(id: String, texture: Texture2D) -> void:
	if id.is_empty() or texture == null:
		return
	_icons[id] = texture
	_rebuild_icons()

func target_rect(id: String) -> Rect2:
	var target = _targets.get(id)
	return target.get_rect() if target != null else Rect2()

func set_target_rect(id: String, rect: Rect2) -> void:
	if not _targets.has(id) or is_locked(id):
		return
	_targets[id].set_rect(rect)
	_sync_fields()

func set_locked(id: String, locked: bool) -> void:
	if not _targets.has(id):
		return
	_locks[id] = locked
	_sync_fields()

func is_locked(id: String) -> bool:
	return _locks.get(id, false)

func add_extra(id: String) -> TextureButton:
	if not _icons.has(id):
		return null
	var button := TextureButton.new()
	button.texture_normal = _icons[id]
	button.ignore_texture_size = true
	button.custom_minimum_size = Vector2(72, 72)
	button.size = Vector2(72, 72)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = get_viewport_rect().size * 0.5
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(button)
	var name := "extra:%s:%d" % [id, _extra_serial]
	_extra_serial += 1
	register_target(name, button)
	_extras.append({"name": name, "icon": id, "node": button})
	_refresh_list()
	_select_id(name)
	return button

func save_layout() -> Error:
	var targets := {}
	for id in _targets:
		targets[id] = _targets[id].to_array()
	var extras := []
	for entry in _extras:
		extras.append({"icon": entry.icon, "rect": _targets[entry.name].to_array()})
	var layout := {
		"version": 1,
		"targets": targets,
		"extras": extras,
		"locked": _locks,
	}
	var file := FileAccess.open(layout_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(layout, "  "))
	file.close()
	if is_instance_valid(_status):
		_status.text = "Saved to:\n" + ProjectSettings.globalize_path(layout_path)
	layout_saved.emit(layout_path)
	return OK

func load_layout() -> Error:
	if not FileAccess.file_exists(layout_path):
		return ERR_FILE_NOT_FOUND
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(layout_path)) != OK:
		return ERR_PARSE_ERROR
	var data: Variant = json.data
	if not data is Dictionary:
		return ERR_INVALID_DATA
	if not [TYPE_INT, TYPE_FLOAT].has(typeof(data.get("version"))) or data.version != 1:
		return ERR_INVALID_DATA
	if not data.get("targets") is Dictionary:
		return ERR_INVALID_DATA
	if data.has("extras") and not data.extras is Array:
		return ERR_INVALID_DATA
	if data.has("locked") and not data.locked is Dictionary:
		return ERR_INVALID_DATA
	_clear_extras()
	_locks.clear()
	for id in data.targets:
		if not _targets.has(id):
			continue
		if not _valid_rect(data.targets[id]):
			push_warning("invalid layout target: " + id)
			continue
		_targets[id].set_rect(_rect_from(data.targets[id]))
	for entry in data.get("extras", []):
		if not entry is Dictionary or not entry.get("icon") is String or not _valid_rect(entry.get("rect")):
			push_warning("invalid layout extra")
			continue
		if add_extra(entry.icon) == null:
			continue
		var id: String = _extras.back().name
		_targets[id].set_rect(_rect_from(entry.rect))
	for id in data.get("locked", {}):
		if _targets.has(id) and data.locked[id] is bool:
			_locks[id] = data.locked[id]
	_refresh_list()
	if is_instance_valid(_status):
		_status.text = "Layout loaded"
	return OK

func reset_layout() -> void:
	if FileAccess.file_exists(layout_path):
		DirAccess.remove_absolute(layout_path)
	if is_instance_valid(_status):
		_status.text = "Layout reset"
	layout_reset.emit(layout_path)

func _build_reference() -> void:
	_mockup = TextureRect.new()
	_mockup.texture = reference_texture
	_mockup.visible = reference_texture != null
	_mockup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mockup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mockup.stretch_mode = TextureRect.STRETCH_SCALE
	_mockup.modulate.a = 0.5
	_mockup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mockup)

func _build_outline() -> void:
	_outline = ReferenceRect.new()
	_outline.border_color = Color(1, 0.3, 0.3, 0.9)
	_outline.border_width = 2.0
	_outline.editor_only = false
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.visible = false
	add_child(_outline)

func _build_inspector() -> void:
	_inspector = Window.new()
	_inspector.title = "Layout Editor"
	_inspector.size = Vector2i(420, 760)
	_inspector.always_on_top = true
	_inspector.close_requested.connect(func(): get_tree().quit())
	add_child(_inspector)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.position = Vector2(8, 8)
	box.add_theme_constant_override("separation", 10)
	_inspector.add_child(box)
	var hint := Label.new()
	hint.text = "Drag elements in the preview. Mouse wheel: scale."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var opacity_label := Label.new()
	opacity_label.text = "Reference opacity"
	box.add_child(opacity_label)
	_opacity_slider = HSlider.new()
	_opacity_slider.min_value = 0.0
	_opacity_slider.max_value = 1.0
	_opacity_slider.step = 0.05
	_opacity_slider.value = 0.5
	_opacity_slider.value_changed.connect(func(value): _mockup.modulate.a = value)
	box.add_child(_opacity_slider)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 260)
	_list.item_selected.connect(func(_index): _sync_fields())
	box.add_child(_list)
	for axis in ["x", "y", "Scale %"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := Label.new()
		label.text = axis
		label.custom_minimum_size = Vector2(80, 0)
		row.add_child(label)
		var field := SpinBox.new()
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if axis == "Scale %":
			field.min_value = 1.0
			field.max_value = 500.0
		else:
			field.min_value = -2500.0
			field.max_value = 3500.0
		field.step = 1.0
		field.value_changed.connect(func(value): _on_field_changed(axis, value))
		row.add_child(field)
		_fields[axis] = field
	_lock_check = CheckBox.new()
	_lock_check.text = "Lock element"
	_lock_check.toggled.connect(func(on): set_locked(_selected_name(), on))
	box.add_child(_lock_check)
	_add_button = Button.new()
	_add_button.text = "Add icon"
	_add_button.pressed.connect(func(): _add_popup.popup(Rect2i(200, 300, 260, 400)))
	box.add_child(_add_button)
	_add_popup = PopupMenu.new()
	_add_popup.index_pressed.connect(_on_add_element)
	_inspector.add_child(_add_popup)
	_save_button = Button.new()
	_save_button.text = "Save layout"
	_save_button.pressed.connect(save_layout)
	box.add_child(_save_button)
	_reset_button = Button.new()
	_reset_button.text = "Reset layout"
	_reset_button.pressed.connect(reset_layout)
	box.add_child(_reset_button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_rebuild_icons()
	_inspector.show()
	_inspector.grab_focus()

func _position_inspector() -> void:
	var window_position := DisplayServer.window_get_position()
	var window_size := DisplayServer.window_get_size()
	_inspector.position = window_position + Vector2i(window_size.x + 12, 0)

func _rebuild_icons() -> void:
	if not is_instance_valid(_add_popup):
		return
	_add_popup.clear()
	for id in _icons:
		_add_popup.add_item(id)

func _refresh_list() -> void:
	if not is_instance_valid(_list):
		return
	var selected := _selected_name()
	_list.clear()
	for id in _targets:
		_list.add_item(id)
	if _targets.has(selected):
		_select_id(selected)
	elif _list.item_count > 0:
		_list.select(0)
	_sync_fields()

func _select_id(id: String) -> void:
	for index in range(_list.item_count):
		if _list.get_item_text(index) == id:
			_list.select(index)
			_selected = id
			_sync_fields()
			return

func _selected_name() -> String:
	if not is_instance_valid(_list) or _list.get_selected_items().is_empty():
		return ""
	return _list.get_item_text(_list.get_selected_items()[0])

func _sync_fields() -> void:
	if not is_instance_valid(_list):
		return
	_selected = _selected_name()
	if _selected.is_empty() or not _targets.has(_selected):
		_outline.visible = false
		return
	var rect: Rect2 = _targets[_selected].get_rect()
	var base: Vector2 = _default_sizes.get(_selected, rect.size)
	_updating = true
	_fields.x.value = rect.position.x
	_fields.y.value = rect.position.y
	_fields["Scale %"].value = 100.0 * rect.size.x / base.x if base.x != 0 else 100.0
	_updating = false
	var locked := is_locked(_selected)
	_lock_check.set_pressed_no_signal(locked)
	for field in _fields.values():
		field.editable = not locked
	_outline.position = rect.position
	_outline.size = rect.size
	_outline.visible = true

func _on_field_changed(axis: String, value: float) -> void:
	if _updating:
		return
	var id := _selected_name()
	if id.is_empty() or is_locked(id):
		return
	var rect := target_rect(id)
	match axis:
		"x":
			rect.position.x = value
			set_target_rect(id, rect)
		"y":
			rect.position.y = value
			set_target_rect(id, rect)
		"Scale %":
			_resize_target(id, value / 100.0)

func _resize_target(id: String, factor: float) -> void:
	if not _targets.has(id) or is_locked(id):
		return
	_targets[id].resize(factor)
	_sync_fields()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.window_id != DisplayServer.MAIN_WINDOW_ID:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.pressed:
				_pick_at(event.position)
				if not _selected.is_empty():
					_drag_offset = event.position - target_rect(_selected).position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed and not _selected.is_empty():
			_resize_target(_selected, _scale_factor_of(_selected) * 1.02)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed and not _selected.is_empty():
			_resize_target(_selected, _scale_factor_of(_selected) / 1.02)
	elif event is InputEventMouseMotion and _dragging:
		if not _selected.is_empty() and not is_locked(_selected):
			var rect := target_rect(_selected)
			rect.position = event.position - _drag_offset
			set_target_rect(_selected, rect)

func _scale_factor_of(id: String) -> float:
	var rect := target_rect(id)
	var base: Vector2 = _default_sizes.get(id, rect.size)
	return rect.size.x / base.x if base.x != 0 else 1.0

func _pick_at(pos: Vector2) -> void:
	var best := ""
	var best_area := INF
	for id in _targets:
		var rect: Rect2 = _targets[id].get_rect()
		if rect.has_point(pos) and rect.get_area() < best_area:
			best = id
			best_area = rect.get_area()
	if not best.is_empty() and not is_locked(best):
		_select_id(best)

func _on_add_element(index: int) -> void:
	add_extra(_add_popup.get_item_text(index))

func _clear_extras() -> void:
	for entry in _extras:
		var id: String = entry.name
		if is_instance_valid(entry.node):
			entry.node.queue_free()
		_targets.erase(id)
		_default_sizes.erase(id)
		_locks.erase(id)
	_extras.clear()

func _valid_rect(value: Variant) -> bool:
	if not value is Array or value.size() != 4:
		return false
	for number in value:
		if not [TYPE_INT, TYPE_FLOAT].has(typeof(number)) or not is_finite(float(number)):
			return false
	return value[2] >= 0 and value[3] >= 0

func _rect_from(value: Array) -> Rect2:
	return Rect2(value[0], value[1], value[2], value[3])
