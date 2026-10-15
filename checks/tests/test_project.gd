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


func test_background_comes_from_the_config() -> void:
	var path := Game.config.background_path
	expect(ResourceLoader.exists(path), "background_path in config/game_config.tres exists: %s" % path)
	var listed := false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets.json"))
	if data is Dictionary:
		for entry: Variant in (data as Dictionary).get("assets", []):
			if entry is Dictionary and "res://" + str((entry as Dictionary).get("path", "")) == path:
				listed = true
	expect(listed, "background_path is listed in assets.json: %s" % path)
	var bg: TextureRect = load("res://ui/background.tscn").instantiate()
	tree.root.add_child(bg)
	await frames(1)
	expect(bg.texture != null and bg.texture.resource_path == path, "ui/background.tscn shows background_path")
	bg.queue_free()
	await frames(1)


func test_the_save_keeps_the_language() -> void:
	var saved_path := Game.save_path
	Game.save_path = "user://check_progress_language.json"
	Game.reset_progress()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Game.save_path))
	expect(data is Dictionary and (data as Dictionary).get("language", "") == Game.language, "the save file has the language")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.save_path = saved_path
	Game.load_progress()
