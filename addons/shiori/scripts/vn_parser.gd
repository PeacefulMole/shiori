class_name VNParser
extends RefCounted

# Script format (.vn, UTF-8):
#   blank lines and "#" comments are ignored
#   @bg <key> / @music <key> / @pose <key> / @end
#   Speaker: line of dialogue
#   Speaker|pose: line of dialogue (also switches the pose)
#   [narration text]
#   >choice
#   - option text        (indented 2 spaces relative to >choice)
#       branch lines     (indented 4 spaces; no nested >choice)
# Literal "\n" inside dialogue text becomes a newline.

static func parse(text: String) -> Dictionary:
	var lines := text.split("\n")
	return _parse_block(lines, 0, 0)

static func _parse_block(lines: PackedStringArray, start: int, indent: int) -> Dictionary:
	var commands: Array = []
	var pos := start
	while pos < lines.size():
		var line: String = lines[pos]
		var content := line.strip_edges(true, false)
		if content.is_empty() or content.begins_with("#"):
			pos += 1
			continue
		var cur_indent := line.length() - content.length()
		if cur_indent < indent:
			break
		if cur_indent > indent:
			return {"commands": [], "error": "line %d: unexpected indent" % (pos + 1), "pos": pos}
		if content == ">choice":
			if indent > 0:
				return {"commands": [], "error": "line %d: nested choices are not supported" % (pos + 1), "pos": pos}
			var choice := _parse_choice(lines, pos, indent)
			if choice.error != "":
				return choice
			commands.append_array(choice.commands)
			pos = choice.pos
			continue
		var parsed := _parse_line(content, pos)
		if parsed.error != "":
			return {"commands": commands, "error": parsed.error, "pos": pos}
		commands.append_array(parsed.commands)
		pos += 1
	return {"commands": commands, "error": "", "pos": pos}

static func _parse_line(content: String, pos: int) -> Dictionary:
	var line_no := pos + 1
	if content.begins_with("@"):
		var tokens := content.split(" ", false)
		var keyword: String = tokens[0]
		if not ["@bg", "@music", "@pose", "@end"].has(keyword):
			return {"commands": [], "error": "line %d: unknown directive" % line_no}
		if keyword == "@end":
			if tokens.size() != 1:
				return {"commands": [], "error": "line %d: @end takes no arguments" % line_no}
			return {"commands": [{"type": "end"}], "error": ""}
		if tokens.size() != 2:
			return {"commands": [], "error": "line %d: %s needs exactly one key" % [line_no, keyword]}
		return {"commands": [{"type": keyword.substr(1), "key": tokens[1]}], "error": ""}
	if content.begins_with("[") and content.ends_with("]") and content.length() >= 2:
		return {"commands": [{"type": "narrate", "text": content.substr(1, content.length() - 2)}], "error": ""}
	var colon := content.find(":")
	if colon == -1:
		return {"commands": [], "error": "line %d: cannot parse" % line_no}
	var head := content.substr(0, colon)
	var text := content.substr(colon + 1).strip_edges().replace("\\n", "\n")
	var speaker := head
	var commands: Array = []
	if head.contains("|"):
		var parts := head.split("|")
		speaker = parts[0]
		var pose: String = parts[1]
		if speaker.is_empty() or pose.is_empty():
			return {"commands": [], "error": "line %d: empty speaker or pose" % line_no}
		commands.append({"type": "pose", "key": pose})
	if speaker.is_empty() or text.is_empty():
		return {"commands": [], "error": "line %d: empty speaker or text" % line_no}
	commands.append({"type": "say", "speaker": speaker, "text": text})
	return {"commands": commands, "error": ""}

static func _parse_choice(lines: PackedStringArray, start: int, indent: int) -> Dictionary:
	var options: Array = []
	var pos := start + 1
	while pos < lines.size():
		var line: String = lines[pos]
		var content := line.strip_edges(true, false)
		if content.is_empty() or content.begins_with("#"):
			pos += 1
			continue
		var cur_indent := line.length() - content.length()
		if cur_indent < indent + 2:
			break
		if cur_indent != indent + 2 or not content.begins_with("- "):
			return {"commands": [], "error": "line %d: expected '- ' option" % (pos + 1), "pos": pos}
		var option_text := content.substr(2).strip_edges()
		if option_text.is_empty():
			return {"commands": [], "error": "line %d: empty option text" % (pos + 1), "pos": pos}
		var body := _parse_block(lines, pos + 1, indent + 4)
		if body.error != "":
			return body
		if body.commands.is_empty():
			return {"commands": [], "error": "line %d: empty choice branch" % (pos + 2), "pos": pos}
		options.append({"text": option_text, "body": body.commands})
		pos = body.pos
	if options.is_empty():
		return {"commands": [], "error": "line %d: choice without options" % (start + 1), "pos": pos}
	return {"commands": [{"type": "choice", "options": options}], "error": "", "pos": pos}
