extends TestBase

class Recorder:
	var events: Array = []
	var options: Array = []
	var said_count := 0
	var finished := false

	func hook(runner: VNRunner) -> void:
		runner.said.connect(func(s, t): events.append(["said", s, t]); said_count += 1)
		runner.narrated.connect(func(t): events.append(["narrated", t]))
		runner.background_changed.connect(func(k): events.append(["bg", k]))
		runner.music_changed.connect(func(k): events.append(["music", k]))
		runner.pose_changed.connect(func(k): events.append(["pose", k]))
		runner.choice_requested.connect(func(o): options = o)
		runner.finished.connect(func(): finished = true)

func _runner(commands: Array) -> VNRunner:
	var runner := VNRunner.new()
	runner.load_script(commands)
	return runner

func test_linear_script_signals() -> void:
	var runner := _runner([
		{"type": "narrate", "text": "N1"},
		{"type": "say", "speaker": "Костя", "text": "S1"},
		{"type": "bg", "key": "playground"},
		{"type": "music", "key": "wind"},
		{"type": "pose", "key": "calm"},
		{"type": "narrate", "text": "N2"},
	])
	var rec := Recorder.new()
	rec.hook(runner)

	runner.advance()
	eq(rec.events, [["narrated", "N1"]], "step1")
	runner.advance()
	eq(rec.events.size(), 2, "step2 size")
	eq(rec.events[1], ["said", "Костя", "S1"], "step2")
	runner.advance()
	eq(
		rec.events,
		[["narrated", "N1"], ["said", "Костя", "S1"], ["bg", "playground"], ["music", "wind"], ["pose", "calm"], ["narrated", "N2"]],
		"step3"
	)
	check(not rec.finished, "not finished yet")
	runner.advance()
	check(rec.finished, "finished after last advance")

func test_choice_branches() -> void:
	var choice := {
		"type": "choice",
		"options": [
			{"text": "А", "body": [{"type": "say", "speaker": "К", "text": "ответ А"}]},
			{"text": "Б", "body": [{"type": "say", "speaker": "К", "text": "ответ Б"}]},
		],
	}
	for index in range(2):
		var runner := _runner([{"type": "narrate", "text": "N"}, choice])
		var rec := Recorder.new()
		rec.hook(runner)
		runner.advance()
		runner.advance()
		eq(rec.options, ["А", "Б"], "options offered, take %d" % index)
		check(runner.is_waiting_for_choice(), "waiting for choice, take %d" % index)
		runner.select_option(index)
		var expected := [["said", "К", "ответ А"]] if index == 0 else [["said", "К", "ответ Б"]]
		eq(rec.events.slice(1), expected, "branch, take %d" % index)
		runner.advance()
		check(rec.finished, "branch finished, take %d" % index)

func test_select_option_outside_choice_ignored() -> void:
	var runner := _runner([{"type": "say", "speaker": "К", "text": "S"}])
	var rec := Recorder.new()
	rec.hook(runner)
	runner.select_option(0)
	runner.advance()
	eq(rec.said_count, 1, "no extra signals")

func test_state_roundtrip() -> void:
	var runner := _runner([
		{"type": "say", "speaker": "К", "text": "S1"},
		{"type": "say", "speaker": "К", "text": "S2"},
	])
	var rec := Recorder.new()
	rec.hook(runner)
	runner.advance()
	var state := runner.get_state()
	runner.advance()
	eq(rec.events.size(), 2, "both lines before restore")
	runner.restore_state(state)
	runner.advance()
	eq(rec.events.size(), 3, "restore replays from saved point")
	eq(rec.events[2], ["said", "К", "S2"], "replayed line")

func test_restore_inside_choice() -> void:
	var choice := {
		"type": "choice",
		"options": [
			{"text": "А", "body": [{"type": "say", "speaker": "К", "text": "ответ А"}]},
			{"text": "Б", "body": [{"type": "say", "speaker": "К", "text": "ответ Б"}]},
		],
	}
	var runner := _runner([{"type": "narrate", "text": "N"}, choice])
	var rec := Recorder.new()
	rec.hook(runner)
	runner.advance()
	runner.advance()
	var state := runner.get_state()
	runner.restore_state(state)
	check(runner.is_waiting_for_choice(), "back at the choice")
	runner.select_option(1)
	eq(rec.events.filter(func(e): return e[0] == "said"), [["said", "К", "ответ Б"]], "picked second option")
	runner.advance()
	check(rec.finished, "finished")
