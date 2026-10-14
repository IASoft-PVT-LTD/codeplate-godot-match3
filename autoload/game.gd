extends Node
## Autoload `Game`: the config, the level list, saved progress, settings and
## scene changes.

const CONFIG_PATH := "res://config/game_config.tres"
const SCENE_TITLE := "res://ui/title.tscn"
const SCENE_LEVEL_SELECT := "res://ui/level_select.tscn"
const SCENE_LEVEL := "res://game/level.tscn"

## Where progress is saved. Checks point this at a throwaway file.
var save_path := "user://progress.json"
var config: GameConfig
## Every level, in play order.
var levels: Array[LevelData] = []
## The level that game/level.tscn plays when it opens.
var current_level: int = 1
var sound_on: bool = true
## Settings (the shared settings screen, addons/codeplate/ui/settings_screen.gd,
## reads and sets these). Volumes are 0..1; Audio applies them.
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false

## level number (as a String, because JSON keys are strings) -> best stars / best score
var _stars: Dictionary = {}
var _best: Dictionary = {}


func _ready() -> void:
	config = load(CONFIG_PATH)
	load_levels()
	load_progress()
	apply_fullscreen.call_deferred()


func load_levels() -> void:
	levels.clear()
	var errors: PackedStringArray = []
	for path: String in LevelData.list_paths():
		var l := LevelData.load_file(path, config.max_colors, errors)
		if l != null:
			levels.append(l)
	for e: String in errors:
		push_error("Bad level file: " + e)
	if levels.is_empty():
		push_error("No levels found in " + LevelData.LEVELS_DIR)


func level(number: int) -> LevelData:
	for l: LevelData in levels:
		if l.number == number:
			return l
	return null


## The level after `number`, or 0 if it was the last.
func next_level(number: int) -> int:
	for i: int in levels.size() - 1:
		if levels[i].number == number:
			return levels[i + 1].number
	return 0


## The first level is always open; each later one opens once the one before has a star.
func is_unlocked(number: int) -> bool:
	for i: int in levels.size():
		if levels[i].number == number:
			return i == 0 or stars_for(levels[i - 1].number) > 0
	return false


func stars_for(number: int) -> int:
	return int(_stars.get(str(number), 0))


func best_score(number: int) -> int:
	return int(_best.get(str(number), 0))


## Records a finished level; keeps the best stars and score.
func record_result(number: int, stars: int, score: int) -> void:
	var key := str(number)
	_stars[key] = maxi(stars, stars_for(number))
	_best[key] = maxi(score, best_score(number))
	save_progress()


func set_sound(on: bool) -> void:
	sound_on = on
	save_progress()


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	Audio.apply_sound_setting()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_fullscreen()


## Fullscreen on desktop; mobile and web builds decide this themselves.
func apply_fullscreen() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## Settings live in the progress file; reset_progress() keeps them.
func save_settings() -> void:
	save_progress()


func save_progress() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save progress to %s" % save_path)
		return
	f.store_string(JSON.stringify({"version": 1, "stars": _stars, "best": _best, "sound_on": sound_on,
		"music_volume": music_volume, "sfx_volume": sfx_volume, "fullscreen": fullscreen}, "  "))


func load_progress() -> void:
	_stars = {}
	_best = {}
	sound_on = true
	music_volume = 1.0
	sfx_volume = 1.0
	fullscreen = false
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		push_warning("Ignoring unreadable progress file %s" % save_path)
		return
	_stars = data.get("stars", {})
	_best = data.get("best", {})
	sound_on = bool(data.get("sound_on", true))
	music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
	fullscreen = bool(data.get("fullscreen", false))


func reset_progress() -> void:
	_stars = {}
	_best = {}
	save_progress()


func goto_title() -> void:
	get_tree().change_scene_to_file(SCENE_TITLE)


func goto_level_select() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_SELECT)


func play_level(number: int) -> void:
	current_level = number
	get_tree().change_scene_to_file(SCENE_LEVEL)
