extends CheckCase
## Skin, sounds and saved progress. (assets.json and res:// paths are checked by
## the CodePlate add-on: addons/codeplate/checks/builtin/.)


func test_skin_has_a_gem_and_tint_per_color() -> void:
	for c: int in Game.config.max_colors:
		expect(FileAccess.file_exists(TileSkin.GEM_PATH % c), "gem texture for color %d" % c)
	expect(Game.config.tile_tints.size() >= Game.config.max_colors, "config.tile_tints has a tint per color")


func test_every_sound_exists() -> void:
	for sound: StringName in Audio.SOUNDS:
		expect(ResourceLoader.exists(Audio.SOUNDS[sound]), "sound %s: %s" % [sound, Audio.SOUNDS[sound]])


func test_progress_round_trip() -> void:
	var saved_path := Game.save_path
	Game.save_path = "user://check_progress_roundtrip.json"
	Game.reset_progress()
	Game.record_result(1, 2, 1234)
	Game.record_result(1, 1, 99) # worse result must not overwrite the best
	Game.load_progress()
	expect_eq(Game.stars_for(1), 2, "best stars kept")
	expect_eq(Game.best_score(1), 1234, "best score kept")
	expect(Game.is_unlocked(2), "level 2 unlocked by a star on level 1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.save_path = saved_path
	Game.load_progress()
