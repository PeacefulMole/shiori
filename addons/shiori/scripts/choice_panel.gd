class_name ChoicePanel
extends VBoxContainer

signal option_selected(index: int)

var _buttons: Array[Button] = []
var option_texture: Texture2D

func show_options(options: Array) -> void:
	hide_options()
	for i in range(options.size()):
		var button := Button.new()
		button.text = options[i]
		button.custom_minimum_size = Vector2(720, 96)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 28)
		if option_texture != null:
			var normal := StyleBoxTexture.new()
			normal.texture = option_texture
			normal.content_margin_left = 24
			normal.content_margin_right = 24
			normal.content_margin_top = 12
			normal.content_margin_bottom = 12
			var hover := normal.duplicate() as StyleBoxTexture
			hover.modulate_color = Color(1.08, 1.08, 1.08)
			var pressed_style := normal.duplicate() as StyleBoxTexture
			pressed_style.modulate_color = Color(0.9, 0.9, 0.9)
			button.add_theme_stylebox_override("normal", normal)
			button.add_theme_stylebox_override("hover", hover)
			button.add_theme_stylebox_override("pressed", pressed_style)
		button.pressed.connect(func(): option_selected.emit(i))
		_buttons.append(button)
		add_child(button)
	visible = true

func hide_options() -> void:
	for button in _buttons:
		remove_child(button)
		button.queue_free()
	_buttons.clear()
	visible = false
