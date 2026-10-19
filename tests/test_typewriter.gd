extends TestBase

func test_prints_to_completion() -> void:
	var tw := Typewriter.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(tw)
	var rec := Recorder.new()
	tw.text_completed.connect(func(): rec.done = true)
	tw.start_text("abc", 100000)
	check(tw.is_typing(), "typing right after start")
	await tree.process_frame
	await tree.process_frame
	eq(tw.visible_characters, 3, "all characters visible")
	check(rec.done, "completed signal emitted")
	check(not tw.is_typing(), "typing done")
	tw.free()

func test_skip_to_end() -> void:
	var tw := Typewriter.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(tw)
	var rec := Recorder.new()
	tw.text_completed.connect(func(): rec.done = true)
	tw.start_text("long text here", 1)
	tw.skip_to_end()
	eq(tw.visible_characters, tw.get_total_character_count(), "skipped to end")
	check(rec.done, "completed on skip")
	check(not tw.is_typing(), "no longer typing")
	tw.free()

func test_idle_by_default() -> void:
	var tw := Typewriter.new()
	check(not tw.is_typing(), "not typing before start")
	tw.skip_to_end()
	eq(tw.visible_characters, -1, "skip on idle changes nothing")
	tw.free()

class Recorder:
	var done := false
