extends CheckCase
## Loads every screen and plays real moves through the level scene, using the
## same code paths as a player (including a simulated swipe).

const LEVEL_SCENE := "res://game/level.tscn"


func _fast() -> void:
	Game.config.animation_speed = 200.0
	Game.save_path = "user://check_progress.json"
	Game.reset_progress()


func _restore() -> void:
	Game.config.animation_speed = 1.0
	Game.reset_progress()
	Game.save_path = "user://progress.json"
	Game.load_progress()
	tree.paused = false


func _open_level(number: int, board_seed: int = 4242) -> LevelScreen:
	Game.current_level = number
	var level: LevelScreen = load(LEVEL_SCENE).instantiate()
	level.board_seed = board_seed
	tree.root.add_child(level)
	await frames(2)
	expect(await until(func() -> bool: return not level.board_view.busy), "intro animation finishes")
	return level


func _with_test_level(number: int, data: Dictionary) -> LevelData:
	var errors: PackedStringArray = []
	var l := LevelData.from_dict(data, Game.config.max_colors, errors)
	expect(errors.is_empty(), "test level is valid: %s" % [errors])
	l.number = number
	Game.levels.append(l)
	return l


func _drop_test_levels() -> void:
	Game.levels = Game.levels.filter(func(l: LevelData) -> bool: return l.number < 900)


func test_title_screen() -> void:
	var title: Control = load("res://ui/title.tscn").instantiate()
	tree.root.add_child(title)
	await frames(3)
	var play := title.get_node_or_null("%PlayButton") as Button
	expect(play != null and play.is_visible_in_tree(), "Play button visible")


func test_level_select_lists_every_level() -> void:
	_fast()
	var select: Control = load("res://ui/level_select.tscn").instantiate()
	tree.root.add_child(select)
	await frames(2)
	var grid := select.get_node("%Grid") as GridContainer
	expect_eq(grid.get_child_count(), Game.levels.size(), "one button per level")
	var first := grid.get_child(0) as Button
	expect(not first.disabled, "level 1 is unlocked")
	if grid.get_child_count() > 1:
		expect((grid.get_child(1) as Button).disabled, "level 2 is locked on a fresh save")
	_restore()


func test_level_plays_moves() -> void:
	_fast()
	var level := await _open_level(1)
	var board := level.session.board
	var moves_at_start := level.session.moves_left
	for i: int in 6:
		if level.session.state != LevelSession.State.PLAYING:
			break
		var m := Moves.best(board)
		if not expect(not m.is_empty(), "a move is available"):
			break
		await level.request_swap(m[0], m[1])
		expect(board.is_full(), "board full after move %d" % i)
		expect(MatchFinder.find(board).is_empty(), "board settled after move %d" % i)
	expect(level.session.moves_left < moves_at_start, "moves were used")
	expect_eq((level.hud.get_node("%MovesLabel") as Label).text, str(level.session.moves_left), "HUD shows moves left")
	expect_eq(level.session.board.positions().size(), _count_tile_views(level), "one TileView per tile")
	_restore()


func test_swipe_input_swaps() -> void:
	_fast()
	var level := await _open_level(1)
	var m := Moves.best(level.session.board)
	var a: Vector2i = m[0]
	var b: Vector2i = m[1]
	var from := level.board_view.cell_to_screen(a)
	var to := level.board_view.cell_to_screen(b)
	var moves_before := level.session.moves_left
	mouse_button(from, true)
	mouse_drag_to(from.lerp(to, 0.5))
	mouse_drag_to(to)
	mouse_button(to, false)
	await frames(2)
	expect(await until(func() -> bool: return not level.board_view.busy), "swap animation finishes")
	expect_eq(level.session.moves_left, moves_before - 1, "the swipe used one move")
	_restore()


func test_tap_tap_swaps() -> void:
	_fast()
	var level := await _open_level(1)
	var m := Moves.best(level.session.board)
	var moves_before := level.session.moves_left
	for cell: Vector2i in m:
		var p := level.board_view.cell_to_screen(cell)
		mouse_button(p, true)
		mouse_button(p, false)
	await frames(2)
	expect(await until(func() -> bool: return not level.board_view.busy), "swap animation finishes")
	expect_eq(level.session.moves_left, moves_before - 1, "tap, tap used one move")
	_restore()


func test_win_shows_result_and_saves_stars() -> void:
	_fast()
	_with_test_level(901, {"title": "Check win", "colors": 5, "moves": 5,
		"goals": [{"kind": "score", "amount": 1}], "stars": [1, 2, 3]})
	var level := await _open_level(901)
	var m := Moves.best(level.session.board)
	await level.request_swap(m[0], m[1])
	expect_eq(level.session.state, LevelSession.State.WON, "won after one move")
	expect(level.result_panel.visible, "result panel shown")
	expect_eq(Game.stars_for(901), 3, "three stars saved")
	expect(level.session.bonus == 4 * Game.config.points_per_move_left, "bonus for 4 moves left")
	_drop_test_levels()
	_restore()


func test_lose_shows_result() -> void:
	_fast()
	_with_test_level(902, {"title": "Check lose", "colors": 5, "moves": 1,
		"goals": [{"kind": "score", "amount": 999999}], "stars": [999999, 1000000, 1000001]})
	var level := await _open_level(902)
	var m := Moves.best(level.session.board)
	await level.request_swap(m[0], m[1])
	expect_eq(level.session.state, LevelSession.State.LOST, "lost when out of moves")
	expect(level.result_panel.visible, "result panel shown")
	expect_eq((level.result_panel.get_node("%Title") as Label).text, "Out of moves", "lose title")
	expect_eq(Game.stars_for(902), 0, "no stars saved")
	_drop_test_levels()
	_restore()


func test_pause_menu_pauses() -> void:
	_fast()
	var level := await _open_level(1)
	level.pause_menu.open()
	expect(tree.paused, "tree paused")
	level.pause_menu.close()
	expect(not tree.paused, "tree resumed")
	_restore()


func test_every_level_opens() -> void:
	_fast()
	for l: LevelData in Game.levels:
		var level := await _open_level(l.number)
		expect(level.session != null and level.session.board.is_full(), "level %d opens with a full board" % l.number)
		var px := level.board_view.pixel_size() * level.board_view.scale
		expect(px.x <= level.size.x, "level %d board fits the screen width" % l.number)
		level.queue_free()
		await frames(1)
	_restore()


func _count_tile_views(level: LevelScreen) -> int:
	var n := 0
	for node: Node in level.board_view.find_children("*", "TileView", true, false):
		if not node.is_queued_for_deletion():
			n += 1
	return n
