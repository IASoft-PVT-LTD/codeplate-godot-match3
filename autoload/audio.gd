extends Node
## Autoload `Audio`: sound effects by name (`Audio.play(&"match")`) and looping
## music (`Audio.play_music(&"theme")`), at the volumes the player set on the
## settings screen (Game.music_volume, Game.sfx_volume). To add a sound: put the
## file in assets/audio/, list it in assets.json, and add it to SOUNDS or MUSIC.

const SOUNDS: Dictionary[StringName, String] = {
	&"swap": "res://assets/audio/swap.wav",
	&"invalid": "res://assets/audio/invalid.wav",
	&"match": "res://assets/audio/match.wav",
	&"special_create": "res://assets/audio/special_create.wav",
	&"line": "res://assets/audio/line.wav",
	&"bomb": "res://assets/audio/bomb.wav",
	&"color_bomb": "res://assets/audio/color_bomb.wav",
	&"shuffle": "res://assets/audio/shuffle.wav",
	&"win": "res://assets/audio/win.wav",
	&"lose": "res://assets/audio/lose.wav",
	&"star": "res://assets/audio/star.wav",
	&"click": "res://assets/audio/click.wav",
}
## Music tracks by name, for `Audio.play_music(&"name")`.
const MUSIC: Dictionary[StringName, String] = {
	&"theme": "res://assets/audio/music_theme.wav",
}
## How many sounds can play at once.
const VOICES := 10
## Music volume at full volume setting, in dB (music sits under the effects).
const MUSIC_DB := -8.0

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep sounds going while paused
	for sound: StringName in SOUNDS:
		_streams[sound] = load(SOUNDS[sound])
	for i: int in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)


## Plays a sound from SOUNDS. `pitch` 1.0 is normal.
func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not Game.sound_on or Game.sfx_volume <= 0.0:
		return
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_error("Audio.play: unknown sound \"%s\" (add it to SOUNDS in autoload/audio.gd)" % sound)
		return
	var p := _free_player()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db + linear_to_db(Game.sfx_volume)
	p.play()


## Loops a track from MUSIC. Keeps playing if it's already on. &"" stops music.
func play_music(track: StringName) -> void:
	if track == _music_name and _music.playing:
		return
	_music_name = track
	_music.stop()
	if track == &"":
		return
	if not MUSIC.has(track):
		push_error("Audio.play_music: unknown track \"%s\" (add it to MUSIC)" % track)
		return
	var stream: AudioStream = load(MUSIC[track])
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	apply_sound_setting()


## Applies Game.sound_on and the music volume (call after changing them).
func apply_sound_setting() -> void:
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(Game.music_volume, 0.001))
	if Game.sound_on and Game.music_volume > 0.0:
		if _music.stream != null and not _music.playing:
			_music.play()
	else:
		_music.stop()
	if not Game.sound_on:
		for p: AudioStreamPlayer in _players:
			p.stop()


func _free_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	_next = (_next + 1) % _players.size()
	return _players[_next]


## Stops every sound and the music.
func stop_all() -> void:
	for p: AudioStreamPlayer in _players:
		p.stop()
		p.stream = null
	_music.stop()
	_music.stream = null


func _exit_tree() -> void:
	stop_all() # no playback may outlive the game on quit
