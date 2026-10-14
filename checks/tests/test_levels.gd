extends CheckCase
## Every level file is valid and plays. See docs/levels.md for the format.


func test_level_files_are_valid() -> void:
	var errors: PackedStringArray = []
	var paths := LevelData.list_paths()
	expect(paths.size() > 0, "there are level files in levels/")
	for path: String in paths:
		LevelData.load_file(path, Game.config.max_colors, errors)
	expect(errors.is_empty(), "level errors:\n       " + "\n       ".join(errors))


func test_levels_are_numbered_without_gaps() -> void:
	var n := 1
	for l: LevelData in Game.levels:
		expect_eq(l.number, n, "level files must be level_01.json, level_02.json, ... in order")
		n += 1


func test_every_level_generates_playable_boards() -> void:
	for l: LevelData in Game.levels:
		for board_seed: int in range(1, 21):
			var s := LevelSession.new(l, Game.config, board_seed)
			if not expect(s.board.is_full() and Moves.has_any(s.board) and MatchFinder.find(s.board).is_empty(),
					"level %d seed %d: board is full, has a move and no ready-made match" % [l.number, board_seed]):
				break


func test_every_level_is_winnable_by_a_simple_bot() -> void:
	# A bot that plays the hint move every turn must win each level at least
	# once in a few tries. If this fails after you edit a level, the level is
	# probably too hard: add moves, lower goals, or use fewer colors.
	# Run tools/balance.gd for win rates and scores.
	for l: LevelData in Game.levels:
		var wins := 0
		for board_seed: int in [11, 22, 33]:
			if Balance.play(l, Game.config, board_seed).won:
				wins += 1
		expect(wins > 0, "level %d (%s): the hint bot lost all 3 tries" % [l.number, l.title])


func test_from_dict_reports_problems() -> void:
	var errors: PackedStringArray = []
	var l := LevelData.from_dict({"width": 2, "colors": 9, "moves": 0, "stars": [3, 2, 1],
		"goals": [{"kind": "collect", "color": 12, "amount": 5}], "typo": 1}, 6, errors)
	expect(l == null, "invalid level returns null")
	for needle: String in ["width and height", "colors must be", "moves must", "stars must", "collect goal color", "unknown key"]:
		expect(Array(errors).any(func(e: String) -> bool: return e.contains(needle)), "reports: %s" % needle)
