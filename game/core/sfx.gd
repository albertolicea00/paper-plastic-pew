class_name Sfx
extends Node
## Sound by event name. Files are optional and found by convention:
## res://dimensions/<id>/audio/<event>.(wav|ogg) overrides
## res://assets/audio/<event>.(wav|ogg). Music is the event "music"; the menu
## and the low-health pulse use shared-only events ("menu", "heartbeat").

const VOICES = 14
var effects_volume = 0.8
var music_volume = 0.6
var cache: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var decks: Array[AudioStreamPlayer] = []
var pulse: AudioStreamPlayer
var _next = 0
var _deck = 0
var _playing = ""
var _duck = 1.0
var _target_duck = 1.0
# How close to death, 0..1; drives the heartbeat layer.
var danger = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for i in 2:
		var deck = AudioStreamPlayer.new()
		deck.volume_db = -80.0
		add_child(deck)
		decks.append(deck)
	pulse = AudioStreamPlayer.new()
	pulse.volume_db = -80.0
	add_child(pulse)

# `shared` skips the active dimension's folder, for tracks that are not themed
# per dimension (the menu tune, the heartbeat).
func find(event: String, shared: bool = false) -> AudioStream:
	var pack = Dimensions.hub.active
	var key = ("" if shared else pack.id) + "/" + event
	if not cache.has(key):
		cache[key] = null
		var folders = ["res://assets/audio"] if shared else [pack.dir.path_join("audio"), "res://assets/audio"]
		for folder in folders:
			for extension in ["ogg", "wav"]:
				var file = "%s/%s.%s" % [folder, event, extension]
				if cache[key] == null and ResourceLoader.exists(file):
					cache[key] = load(file)
	return cache[key]

func play(event: String, _at: Vector3 = Vector3.ZERO) -> void:
	var stream = find(event)
	if stream == null or effects_volume <= 0.0:
		return
	var voice = voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = stream
	voice.volume_db = linear_to_db(effects_volume)
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()

## Crossfade the music to an event. "music" is the active dimension's track;
## pass a shared event like "menu" for a tune that is the same everywhere.
func music(event: String = "music", shared: bool = false) -> void:
	var stream = find(event, shared)
	var path = stream.resource_path if stream != null else ""
	if path == _playing:
		return
	_playing = path
	_deck = 1 - _deck
	decks[_deck].stream = stream
	if stream != null:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		decks[_deck].play()

## Dip the music, e.g. while paused. 1.0 = full, 0.0 = silent.
func duck(factor: float) -> void:
	_target_duck = clampf(factor, 0.0, 1.0)

func silence() -> void:
	_playing = ""
	_deck = 1 - _deck
	decks[_deck].stream = null

## Release every stream, so a headless run can quit without leaked resources.
func stop_all() -> void:
	for player in voices + decks + [pulse]:
		player.stop()
		player.stream = null
	cache.clear()
	_playing = ""
	danger = 0.0

func _process(delta: float) -> void:
	_duck = move_toward(_duck, _target_duck, delta * 4.0)
	for i in 2:
		var target = linear_to_db(maxf(0.0001, music_volume * _duck)) if i == _deck and decks[i].stream != null else -80.0
		decks[i].volume_db = move_toward(decks[i].volume_db, target, delta * 90.0)
		if i != _deck and decks[i].volume_db <= -79.0 and decks[i].playing:
			decks[i].stop()
	_heartbeat(delta)

# Low-health heartbeat: louder and faster the closer to death. Silent above the
# danger threshold, and does nothing if no heartbeat file ships.
func _heartbeat(delta: float) -> void:
	if danger > 0.01 and music_volume > 0.0:
		var stream = find("heartbeat", true)
		if stream == null:
			return
		if pulse.stream != stream:
			pulse.stream = stream
			if stream is AudioStreamOggVorbis:
				stream.loop = true
		if not pulse.playing:
			pulse.play()
		pulse.pitch_scale = 0.9 + danger * 0.5
		pulse.volume_db = move_toward(pulse.volume_db, linear_to_db(maxf(0.0001, 0.5 * danger)), delta * 30.0)
	elif pulse.playing:
		pulse.volume_db = move_toward(pulse.volume_db, -80.0, delta * 30.0)
		if pulse.volume_db <= -79.0:
			pulse.stop()
