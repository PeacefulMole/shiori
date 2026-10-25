class_name VNAudio
extends Node

const FADE_TIME := 1.5

var _players: Array[AudioStreamPlayer] = []
var _active: AudioStreamPlayer
var _current := ""
var _fades := {}
var _pending_stream: AudioStream
var _pending_key := ""

func _ready() -> void:
	_ensure_players()
	if _pending_stream != null:
		var stream := _pending_stream
		var key := _pending_key
		_pending_stream = null
		_pending_key = ""
		_current = ""
		play_music(stream, key)

func play_music(stream: AudioStream, key: String) -> void:
	if stream == null:
		push_error("play_music: null stream for key " + key)
		return
	if key == _current:
		return
	_current = key
	if not is_inside_tree():
		_pending_stream = stream
		_pending_key = key
		return
	_pending_stream = null
	_pending_key = ""
	_ensure_players()
	var next: AudioStreamPlayer = _players[1] if _active == _players[0] else _players[0]
	_kill_fade(next)
	if next.playing:
		next.stop()
	next.stream = stream
	next.volume_db = 0.0
	next.play()
	if _active != null and _active.playing:
		_fade_out(_active)
	_active = next

func current_track() -> String:
	return _current

func stop_music() -> void:
	_current = ""
	_pending_stream = null
	_pending_key = ""
	if not is_inside_tree():
		return
	for player in _players:
		if player.playing:
			_fade_out(player)
	_active = null

func _fade_out(player: AudioStreamPlayer) -> void:
	_kill_fade(player)
	var fade := create_tween()
	_fades[player] = fade
	fade.tween_property(player, "volume_db", -40.0, FADE_TIME)
	fade.tween_callback(player.stop)
	fade.finished.connect(func(): _fades.erase(player))

func _kill_fade(player: AudioStreamPlayer) -> void:
	if not _fades.has(player):
		return
	_fades[player].kill()
	_fades.erase(player)

func _ensure_players() -> void:
	if _players.size() == 2:
		return
	_players = [AudioStreamPlayer.new(), AudioStreamPlayer.new()]
	for player in _players:
		add_child(player)
