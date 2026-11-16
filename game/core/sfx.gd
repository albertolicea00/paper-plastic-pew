class_name Sfx
extends Node
## Sound by event name. Files are optional and found by convention:
## res://dimensions/<id>/audio/<event>.(wav|ogg) overrides
## res://assets/audio/<event>.(wav|ogg). Music is the event "music".

const VOICES = 14
var effects_volume = 0.8
var music_volume = 0.6
var cache: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var decks: Array[AudioStreamPlayer] = []
var _next = 0
var _deck = 0
var _playing = ""

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

func find(event: String) -> AudioStream:
	var pack = Dimensions.hub.active
	var key = pack.id + "/" + event
	if not cache.has(key):
		cache[key] = null
		for folder in [pack.dir.path_join("audio"), "res://assets/audio"]:
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

## Crossfade to the active dimension's music.
func music() -> void:
	var stream = find("music")
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

func silence() -> void:
	_playing = ""
	_deck = 1 - _deck
	decks[_deck].stream = null

## Release every stream, so a headless run can quit without leaked resources.
func stop_all() -> void:
	for player in voices + decks:
		player.stop()
		player.stream = null
	cache.clear()
	_playing = ""

func _process(delta: float) -> void:
	for i in 2:
		var target = linear_to_db(maxf(0.0001, music_volume)) if i == _deck and decks[i].stream != null else -80.0
		decks[i].volume_db = move_toward(decks[i].volume_db, target, delta * 90.0)
		if i != _deck and decks[i].volume_db <= -79.0 and decks[i].playing:
			decks[i].stop()
