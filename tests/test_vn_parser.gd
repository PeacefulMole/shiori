extends TestBase

func test_parse_directives() -> void:
	var r := VNParser.parse("@bg playground\n@music wind\n@pose calm\n@pose none\n@end\n")
	eq(r.error, "", "error")
	eq(r.commands.size(), 5, "count")
	eq(r.commands[0], {"type": "bg", "key": "playground"}, "cmd0")
	eq(r.commands[1], {"type": "music", "key": "wind"}, "cmd1")
	eq(r.commands[2], {"type": "pose", "key": "calm"}, "cmd2")
	eq(r.commands[3], {"type": "pose", "key": "none"}, "cmd3")
	eq(r.commands[4], {"type": "end"}, "cmd4")

func test_directive_requires_key() -> void:
	var r := VNParser.parse("@bg\n")
	check(r.error.contains("line 1"), "error should mention line 1, got: " + r.error)

func test_parse_say_with_pose() -> void:
	var r := VNParser.parse("Ульяна|calm: Привет, Кость.")
	eq(r.error, "", "error")
	eq(r.commands.size(), 2, "count")
	eq(r.commands[0], {"type": "pose", "key": "calm"}, "pose first")
	eq(r.commands[1], {"type": "say", "speaker": "Ульяна", "text": "Привет, Кость."}, "say")

func test_parse_say_plain() -> void:
	var r := VNParser.parse("Костя: Привет, Ульяна.")
	eq(r.commands[0], {"type": "say", "speaker": "Костя", "text": "Привет, Ульяна."}, "cmd0")

func test_parse_narration() -> void:
	var r := VNParser.parse("[Я подошёл к ней.]")
	eq(r.commands[0], {"type": "narrate", "text": "Я подошёл к ней."}, "cmd0")

func test_parse_choice_two_options() -> void:
	var text := ">choice\n  - Вариант А.\n    Костя: Текст А.\n    [Ремарка А.]\n  - Вариант Б.\n    Костя: Текст Б.\n"
	var r := VNParser.parse(text)
	eq(r.error, "", "error")
	eq(r.commands.size(), 1, "count")
	var choice: Dictionary = r.commands[0]
	eq(choice.type, "choice", "type")
	eq(choice.options.size(), 2, "options")
	eq(choice.options[0].text, "Вариант А.", "opt0 text")
	eq(choice.options[0].body.size(), 2, "opt0 body size")
	eq(choice.options[0].body[0], {"type": "say", "speaker": "Костя", "text": "Текст А."}, "opt0 body0")
	eq(choice.options[1].text, "Вариант Б.", "opt1 text")
	eq(choice.options[1].body.size(), 1, "opt1 body size")

func test_multiline_text_escapes() -> void:
	var r := VNParser.parse("Костя: Первая строка.\\nВторая строка.")
	eq(r.commands[0].text, "Первая строка.\nВторая строка.", "text")

func test_error_unknown_line() -> void:
	var r := VNParser.parse("Костя: Ок.\nбред без двоеточия")
	check(r.error.contains("line 2"), "error should mention line 2, got: " + r.error)
	eq(r.commands.size(), 1, "first line still parsed")

func test_error_empty_branch() -> void:
	var r := VNParser.parse(">choice\n- Вариант А.\n- Вариант Б.\n    Костя: Текст.\n")
	check(r.error != "", "expected error, got empty")

func test_comments_and_blank_lines_ignored() -> void:
	var r := VNParser.parse("# комментарий\n\nКостя: Привет.\n\n# ещё\n")
	eq(r.error, "", "error")
	eq(r.commands.size(), 1, "count")
