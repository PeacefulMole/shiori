class_name VNRunner
extends Node

signal said(speaker: String, text: String)
signal narrated(text: String)
signal choice_requested(options: Array)
signal background_changed(key: String)
signal pose_changed(key: String)
signal music_changed(key: String)
signal finished()

var _root_commands: Array = []
var _stack: Array = []
var _waiting_choice := false
var _done := false

func load_script(commands: Array) -> void:
	_root_commands = commands
	_stack = [_make_frame(commands)]
	_waiting_choice = false
	_done = false

func advance() -> void:
	if _done or _waiting_choice:
		return
	_step()

func select_option(index: int) -> void:
	if not _waiting_choice or _stack.is_empty():
		return
	var frame: Dictionary = _stack.back()
	var choice: Dictionary = frame.commands[frame.index - 1]
	if index < 0 or index >= choice.options.size():
		push_error("select_option: index out of range")
		return
	_waiting_choice = false
	frame.opt = index
	_stack.append(_make_frame(choice.options[index].body))
	_step()

func is_waiting_for_choice() -> bool:
	return _waiting_choice

func get_state() -> Dictionary:
	var stack: Array = []
	for frame in _stack:
		stack.append({"i": frame.index, "opt": frame.opt})
	return {"stack": stack}

func restore_state(state: Dictionary) -> void:
	_stack.clear()
	var commands := _root_commands
	for entry in state.stack:
		_stack.append({"commands": commands, "index": entry.i, "opt": entry.opt})
		if entry.opt >= 0:
			var choice: Dictionary = commands[entry.i - 1]
			commands = choice.options[entry.opt].body
	_waiting_choice = false
	_done = false
	if not _stack.is_empty():
		var top: Dictionary = _stack.back()
		if top.index > 0 and top.commands[top.index - 1].type == "choice":
			_waiting_choice = true

func _step() -> void:
	while not _stack.is_empty():
		var frame: Dictionary = _stack.back()
		if frame.index >= frame.commands.size():
			_stack.pop_back()
			continue
		var cmd: Dictionary = frame.commands[frame.index]
		frame.index += 1
		match cmd.type:
			"bg":
				background_changed.emit(cmd.key)
			"music":
				music_changed.emit(cmd.key)
			"pose":
				pose_changed.emit(cmd.key)
			"narrate":
				narrated.emit(cmd.text)
				return
			"say":
				said.emit(cmd.speaker, cmd.text)
				return
			"choice":
				var options: Array = []
				for option in cmd.options:
					options.append(option.text)
				choice_requested.emit(options)
				_waiting_choice = true
				return
			"end":
				_stack.pop_back()
			_:
				push_error("unknown command type: " + str(cmd.type))
	_done = true
	finished.emit()

func _make_frame(commands: Array) -> Dictionary:
	return {"commands": commands, "index": 0, "opt": -1}
