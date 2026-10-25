extends TestBase

class Recorder:
	var picked: Array = []
	func hook(panel: ChoicePanel) -> void:
		panel.option_selected.connect(func(i): picked.append(i))

func _buttons(panel: ChoicePanel) -> Array:
	var found: Array = []
	for child in panel.get_children():
		if child is Button:
			found.append(child)
	return found

func test_show_options() -> void:
	var panel := ChoicePanel.new()
	panel.show_options(["А", "Б"])
	var buttons := _buttons(panel)
	eq(buttons.size(), 2, "two buttons")
	eq(buttons[0].text, "А", "first label")
	eq(buttons[1].text, "Б", "second label")
	check(panel.visible, "panel visible")
	panel.free()

func test_click_emits_index() -> void:
	var panel := ChoicePanel.new()
	var rec := Recorder.new()
	rec.hook(panel)
	panel.show_options(["А", "Б", "В"])
	_buttons(panel)[2].pressed.emit()
	eq(rec.picked, [2], "third option emitted")
	panel.free()

func test_hide_options() -> void:
	var panel := ChoicePanel.new()
	panel.show_options(["А"])
	panel.hide_options()
	eq(_buttons(panel).size(), 0, "buttons cleared")
	check(not panel.visible, "panel hidden")
	panel.free()

func test_show_twice_replaces_buttons() -> void:
	var panel := ChoicePanel.new()
	panel.show_options(["А", "Б"])
	panel.show_options(["В"])
	eq(_buttons(panel).size(), 1, "old buttons replaced")
	panel.free()

func test_buttons_are_readable_and_styled() -> void:
	var panel := ChoicePanel.new()
	panel.set("option_texture", ImageTexture.new())
	panel.show_options(["Длинный вариант, который должен переноситься на несколько строк"])
	var button: Button = _buttons(panel)[0]
	eq(button.custom_minimum_size, Vector2(720, 96), "choice button size")
	eq(button.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "long choice wraps")
	eq(button.get_theme_font_size("font_size"), 28, "choice font size")
	check(button.has_theme_stylebox_override("normal"), "choice uses the supplied artwork")
	panel.free()
