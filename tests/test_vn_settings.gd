extends TestBase

class Recorder:
	var changed_count := 0
	func hook(settings: VNSettings) -> void:
		settings.changed.connect(func(): changed_count += 1)

func test_defaults() -> void:
	var settings := VNSettings.new()
	eq(settings.text_speed, 40, "text speed default")
	eq(settings.music_volume, 70, "volume default")
	eq(settings.fullscreen, false, "fullscreen default")

func test_setter_emits_changed() -> void:
	var settings := VNSettings.new()
	var rec := Recorder.new()
	rec.hook(settings)
	settings.text_speed = 80
	eq(rec.changed_count, 1, "one emit per set")
	eq(settings.text_speed, 80, "value set")

func test_save_load_roundtrip() -> void:
	var settings := VNSettings.new()
	settings.text_speed = 20
	settings.music_volume = 35
	settings.fullscreen = true
	settings.save_settings()
	var restored := VNSettings.new()
	restored.load_settings()
	eq(restored.text_speed, 20, "text speed restored")
	eq(restored.music_volume, 35, "volume restored")
	eq(restored.fullscreen, true, "fullscreen restored")
