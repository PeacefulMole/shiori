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

func test_same_key_is_noop() -> void:
	var audio := VNAudio.new()
	audio.play_music(_dummy(), "wind")
	audio.play_music(_dummy(), "wind")
	eq(audio.current_track(), "wind", "same key keeps track")

func test_null_stream_rejected() -> void:
	var audio := VNAudio.new()
	audio.play_music(null, "wind")
	eq(audio.current_track(), "", "null stream does not start a track")

func test_stop_music() -> void:
	var audio := VNAudio.new()
	audio.play_music(_dummy(), "wind")
	audio.stop_music()
	eq(audio.current_track(), "", "cleared after stop")
