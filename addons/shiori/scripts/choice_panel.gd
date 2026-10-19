class_name ChoicePanel
extends PanelContainer

signal option_selected(index: int)

var _buttons: Array[Button] = []

func show_options(options: Array) -> void:
	hide_options()
	for i in range(options.size()):
		var button := Button.new()
		button.text = options[i]
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
