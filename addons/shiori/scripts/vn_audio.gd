class_name VNAudio
extends Node

const FADE_TIME := 1.5

var _players: Array[AudioStreamPlayer] = []
var _active: AudioStreamPlayer
var _current := ""

func _ready() -> void:
	_ensure_players()

func play_music(stream: AudioStream, key: String) -> void:
	if stream == null:
		push_error("play_music: null stream for key " + key)
		return
	if key == _current:
		return
	_current = key
	if not is_inside_tree():
		return
	_ensure_players()
	var next: AudioStreamPlayer = _players[1] if _active == _players[0] else _players[0]
	if next.playing:
		next.stop()
	next.stream = stream
	next.volume_db = 0.0
	next.play()
	if _active != null and _active.playing:
		var fading := _active
		var fade := create_tween()
		fade.tween_property(fading, "volume_db", -40.0, FADE_TIME)
		fade.tween_callback(fading.stop)
	_active = next

func current_track() -> String:
	return _current

func stop_music() -> void:
	_current = ""
	if not is_inside_tree():
		return
	for player in _players:
		if player.playing:
			var fade := create_tween()
			fade.tween_property(player, "volume_db", -40.0, FADE_TIME)
			fade.tween_callback(player.stop)
	_active = null

func _ensure_players() -> void:
	if _players.size() == 2:
		return
	_players = [AudioStreamPlayer.new(), AudioStreamPlayer.new()]
	for player in _players:
		add_child(player)
