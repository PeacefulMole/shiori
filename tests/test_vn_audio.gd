extends TestBase

func _dummy() -> AudioStream:
	return AudioStreamMP3.new()

func test_current_track() -> void:
	var audio := VNAudio.new()
	eq(audio.current_track(), "", "silent at start")
	audio.play_music(_dummy(), "wind")
	eq(audio.current_track(), "wind", "track set")
	audio.play_music(_dummy(), "beast")
	eq(audio.current_track(), "beast", "track switched")
	audio.free()

func test_same_key_is_noop() -> void:
	var audio := VNAudio.new()
	audio.play_music(_dummy(), "wind")
	audio.play_music(_dummy(), "wind")
	eq(audio.current_track(), "wind", "same key keeps track")
	audio.free()

func test_null_stream_rejected() -> void:
	var audio := VNAudio.new()
	audio.play_music(null, "wind")
	eq(audio.current_track(), "", "null stream does not start a track")
	audio.free()

func test_stop_music() -> void:
	var audio := VNAudio.new()
	audio.play_music(_dummy(), "wind")
	audio.stop_music()
	eq(audio.current_track(), "", "cleared after stop")
	audio.free()

func test_rapid_switches_do_not_stop_new_track() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var audio := VNAudio.new()
	tree.root.add_child(audio)
	await tree.process_frame
	audio.play_music(_wav(), "A")
	await tree.create_timer(0.1).timeout
	audio.play_music(_wav(), "B")
	await tree.create_timer(0.1).timeout
	audio.play_music(_wav(), "C")
	await tree.create_timer(1.6).timeout
	eq(audio.current_track(), "C", "latest track remains selected")
	check(audio._active.playing, "latest track is still playing")
	eq(audio._active.volume_db, 0.0, "latest track keeps full volume")
	audio.free()
	await tree.process_frame

func test_play_after_stop_cancels_old_fade() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var audio := VNAudio.new()
	tree.root.add_child(audio)
	await tree.process_frame
	audio.play_music(_wav(), "A")
	audio.stop_music()
	await tree.create_timer(0.1).timeout
	audio.play_music(_wav(), "B")
	await tree.create_timer(1.6).timeout
	check(audio._active.playing, "new track survives the old stop callback")
	eq(audio._active.volume_db, 0.0, "new track is audible")
	audio.free()
	await tree.process_frame

func test_pending_track_starts_when_added_to_tree() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var audio := VNAudio.new()
	audio.play_music(_wav(), "wind")
	tree.root.add_child(audio)
	await tree.process_frame
	eq(audio.current_track(), "wind", "pending key is preserved")
	check(audio._active != null and audio._active.playing, "pending track starts on ready")
	audio.free()
	await tree.process_frame

func _wav() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 8000
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 8000
	var data := PackedByteArray()
	data.resize(8000)
	stream.data = data
	return stream
