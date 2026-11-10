extends TestBase

func test_parse_directives() -> void:
	var r := VNParser.parse("@bg forest\n@music theme\n@pose calm\n@pose none\n@end\n")
	eq(r.error, "", "error")
	eq(r.commands.size(), 5, "count")
	eq(r.commands[0], {"type": "bg", "key": "forest"}, "cmd0")
	eq(r.commands[1], {"type": "music", "key": "theme"}, "cmd1")
	eq(r.commands[2], {"type": "pose", "key": "calm"}, "cmd2")
	eq(r.commands[3], {"type": "pose", "key": "none"}, "cmd3")
	eq(r.commands[4], {"type": "end"}, "cmd4")

func test_directive_requires_key() -> void:
	var r := VNParser.parse("@bg\n")
	check(r.error.contains("line 1"), "error should mention line 1, got: " + r.error)

func test_parse_say_with_pose() -> void:
	var r := VNParser.parse("Alice|calm: Привет, Bob.")
	eq(r.error, "", "error")
	eq(r.commands.size(), 2, "count")
	eq(r.commands[0], {"type": "pose", "key": "calm"}, "pose first")
	eq(r.commands[1], {"type": "say", "speaker": "Alice", "text": "Привет, Bob."}, "say")

func test_parse_say_plain() -> void:
	var r := VNParser.parse("Bob: Привет, Alice.")
	eq(r.commands[0], {"type": "say", "speaker": "Bob", "text": "Привет, Alice."}, "cmd0")

func test_parse_narration() -> void:
	var r := VNParser.parse("[Я подошёл к ней.]")
	eq(r.commands[0], {"type": "narrate", "text": "Я подошёл к ней."}, "cmd0")

func test_parse_choice_two_options() -> void:
	var text := ">choice\n  - Вариант А.\n    Bob: Текст А.\n    [Ремарка А.]\n  - Вариант Б.\n    Bob: Текст Б.\n"
	var r := VNParser.parse(text)
	eq(r.error, "", "error")
	eq(r.commands.size(), 1, "count")
	var choice: Dictionary = r.commands[0]
	eq(choice.type, "choice", "type")
	eq(choice.options.size(), 2, "options")
	eq(choice.options[0].text, "Вариант А.", "opt0 text")
	eq(choice.options[0].body.size(), 2, "opt0 body size")
	eq(choice.options[0].body[0], {"type": "say", "speaker": "Bob", "text": "Текст А."}, "opt0 body0")
	eq(choice.options[1].text, "Вариант Б.", "opt1 text")
	eq(choice.options[1].body.size(), 1, "opt1 body size")

func test_multiline_text_escapes() -> void:
	var r := VNParser.parse("Bob: Первая строка.\\nВторая строка.")
	eq(r.commands[0].text, "Первая строка.\nВторая строка.", "text")

func test_error_unknown_line() -> void:
	var r := VNParser.parse("Bob: Ок.\nбред без двоеточия")
	check(r.error.contains("line 2"), "error should mention line 2, got: " + r.error)
	eq(r.commands.size(), 1, "first line still parsed")

func test_error_empty_branch() -> void:
	var r := VNParser.parse(">choice\n- Вариант А.\n- Вариант Б.\n    Bob: Текст.\n")
	check(r.error != "", "expected error, got empty")

func test_comments_and_blank_lines_ignored() -> void:
	var r := VNParser.parse("# комментарий\n\nBob: Привет.\n\n# ещё\n")
	eq(r.error, "", "error")
	eq(r.commands.size(), 1, "count")

func test_parse_crlf() -> void:
	var r := VNParser.parse("@bg forest\r\n\r\n[Наррация]\r\nBob: Привет\r\n")
	eq(r.error, "", "CRLF parses cleanly")
	eq(r.commands.size(), 3, "CRLF command count")
	eq(r.commands[0].key, "forest", "directive has no carriage return")
	eq(r.commands[1].text, "Наррация", "narration has no carriage return")
	eq(r.commands[2].text, "Привет", "dialogue has no carriage return")

func test_speaker_and_pose_are_trimmed() -> void:
	var r := VNParser.parse("Alice|calm : Привет\nBob : Да")
	eq(r.error, "", "spaced heads parse cleanly")
	eq(r.commands[0].key, "calm", "pose is trimmed")
	eq(r.commands[1].speaker, "Alice", "posed speaker is trimmed")
	eq(r.commands[2].speaker, "Bob", "plain speaker is trimmed")
