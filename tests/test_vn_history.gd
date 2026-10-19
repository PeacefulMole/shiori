extends TestBase

class Recorder:
	var added: Array = []
	func hook(history: VNHistory) -> void:
		history.entry_added.connect(func(e): added.append(e))

func test_add_and_order() -> void:
	var history := VNHistory.new()
	history.add_say("Ульяна", "Привет.")
	history.add_narration("ремарка")
	var entries := history.get_entries()
	eq(entries.size(), 2, "size")
	eq(entries[0], {"kind": "say", "speaker": "Ульяна", "text": "Привет."}, "entry0")
	eq(entries[1], {"kind": "narration", "text": "ремарка"}, "entry1")

func test_entry_added_signal() -> void:
	var history := VNHistory.new()
	var rec := Recorder.new()
	rec.hook(history)
	history.add_say("К", "Привет.")
	eq(rec.added.size(), 1, "signal count")
	eq(rec.added[0].speaker, "К", "signal payload")

func test_cap_keeps_newest() -> void:
	var history := VNHistory.new()
	for i in range(VNHistory.MAX_ENTRIES + 2):
		history.add_say("К", "line %d" % i)
	var entries := history.get_entries()
	eq(entries.size(), VNHistory.MAX_ENTRIES, "capped size")
	eq(entries[0].text, "line 2", "oldest dropped")
	eq(entries.back().text, "line %d" % (VNHistory.MAX_ENTRIES + 1), "newest kept")

func test_clear() -> void:
	var history := VNHistory.new()
	history.add_say("К", "Привет.")
	history.clear()
	eq(history.get_entries().size(), 0, "empty after clear")
