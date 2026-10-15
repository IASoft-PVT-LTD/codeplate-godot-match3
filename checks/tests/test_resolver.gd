extends CheckCase
## Swaps, clears, specials, combos, gravity, refill, cascades and shuffles.

var config := GameConfig.new()


func _resolver(rows: PackedStringArray, colors: int = 6, board_seed: int = 7) -> Resolver:
	return Resolver.new(Board.from_rows(rows, colors, board_seed), config)


func _first(r: Resolver.Result, type: Step.Type) -> Step:
	for s: Step in r.steps:
		if s.type == type:
			return s
	return null


func _cleared_cells(step: Step) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Step.Cleared in step.cleared:
		out.append(c.cell)
	return out


func _expect_stable(r: Resolver, label: String) -> void:
	expect(r.board.is_full(), "%s: board is full" % label)
	expect(MatchFinder.find(r.board).is_empty(), "%s: no matches left after settling" % label)
	expect(Moves.has_any(r.board), "%s: at least one move left" % label)


func test_invalid_swap_swaps_back_and_changes_nothing() -> void:
	var res := _resolver(["0 1 2", "3 4 5", "0 1 2"])
	var before := res.board.dump()
	var r := res.swap(Vector2i(0, 0), Vector2i(1, 0))
	expect(not r.valid, "not valid")
	expect_eq(r.steps.size(), 1, "one step")
	expect_eq(r.steps[0].type, Step.Type.SWAP_BACK, "swap back")
	expect_eq(res.board.dump(), before, "board unchanged")


func test_non_adjacent_swap_does_nothing() -> void:
	var r := _resolver(["0 1 2", "3 4 5", "0 1 2"]).swap(Vector2i(0, 0), Vector2i(2, 2))
	expect(not r.valid, "not valid")
	expect_eq(r.steps.size(), 0, "no steps")


func test_simple_match_clears_three_and_scores() -> void:
	var res := _resolver([
		"1 2 3 4 5",
		"0 0 4 0 2",
		"3 4 0 5 1",
		"2 5 3 1 4",
	])
	var r := res.swap(Vector2i(2, 2), Vector2i(2, 1)) # moves the 0 up into the row
	expect(r.valid, "valid")
	var clear := _first(r, Step.Type.CLEAR)
	if expect(clear != null, "has a CLEAR step"):
		var cells := _cleared_cells(clear)
		cells.sort()
		expect_eq(cells, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)] as Array[Vector2i], "the four 0s cleared")
		expect_eq(clear.created.size(), 1, "four in a row creates a special")
	expect(r.points > 0, "scored points")
	expect(r.collected.get(0, 0) >= 3, "collected color 0")
	expect(res.board.is_full(), "board refilled")


func test_line_h_clears_row() -> void:
	var res := _resolver([
		"1 2 3 4 5",
		"0h 0 4 0 2",
		"3 4 0 5 1",
		"2 5 3 1 4",
	])
	var r := res.swap(Vector2i(2, 2), Vector2i(2, 1))
	var clear := _first(r, Step.Type.CLEAR)
	expect_eq(clear.activations.size(), 1, "one activation")
	expect_eq(clear.activations[0].special, Tile.Special.LINE_H, "LINE_H fired")
	expect_eq(_cleared_cells(clear).size(), 5, "whole row of 5 cleared")


func test_bomb_clears_square() -> void:
	var res := _resolver([
		"1 2 3 4 5",
		"2 3 1 5 4",
		"3 0b 0 4 0",
		"4 5 2 0 1",
		"5 1 4 2 3",
	])
	var r := res.swap(Vector2i(3, 3), Vector2i(3, 2)) # 0 up: 0b 0 0 at row 2
	var clear := _first(r, Step.Type.CLEAR)
	expect_eq(clear.activations[0].special, Tile.Special.BOMB, "bomb fired")
	var cells := _cleared_cells(clear)
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			expect(Vector2i(1 + dx, 2 + dy) in cells, "bomb cleared %s" % Vector2i(1 + dx, 2 + dy))


func test_color_bomb_swap_clears_that_color() -> void:
	var res := _resolver([
		"0 1 2 0",
		"2 * 3 1",
		"0 4 1 0",
	])
	var r := res.swap(Vector2i(1, 1), Vector2i(1, 0)) # color bomb with a 1
	expect(r.valid, "color bomb swap is always valid")
	var clear := _first(r, Step.Type.CLEAR)
	expect_eq(clear.activations[0].special, Tile.Special.COLOR, "color bomb fired")
	expect_eq(clear.activations[0].color, 1, "targeted color 1")
	expect_eq(r.collected.get(1, 0), 3, "all three 1s cleared")


func test_two_color_bombs_clear_everything() -> void:
	var res := _resolver(["0 1 2", "* * 0", "1 2 0"], 3)
	var r := res.swap(Vector2i(0, 1), Vector2i(1, 1))
	expect_eq(_cleared_cells(_first(r, Step.Type.CLEAR)).size(), 9, "whole board cleared")
	expect(res.board.is_full(), "board refilled")


func test_line_plus_line_is_a_cross() -> void:
	var res := _resolver(["0 1 2 3", "1 0h 1v 2", "2 3 0 1", "3 2 1 0"])
	var r := res.swap(Vector2i(1, 1), Vector2i(2, 1))
	var cells := _cleared_cells(_first(r, Step.Type.CLEAR))
	expect_eq(cells.size(), 7, "row + column of a 4x4 board")


func test_bomb_plus_bomb_is_5x5() -> void:
	var rows: PackedStringArray = []
	for y: int in 7:
		var row := []
		for x: int in 7:
			row.append(str((x + y * 2) % 5))
		rows.append(" ".join(row))
	rows[3] = "0 1 2 3b 4b 0 1"
	var res := _resolver(rows)
	var r := res.swap(Vector2i(3, 3), Vector2i(4, 3))
	var cells := _cleared_cells(_first(r, Step.Type.CLEAR))
	expect_eq(cells.size(), 25, "5x5 around the destination cell")


func test_chain_reaction() -> void:
	# The match clears a LINE_V, which fires and hits a BOMB further down.
	var res := _resolver([
		"1 2 3 4 5",
		"0 0v 4 0 2",
		"3 4 0 5 1",
		"2 5b 3 1 4",
		"4 1 2 3 5",
	])
	var r := res.swap(Vector2i(2, 2), Vector2i(2, 1))
	var clear := _first(r, Step.Type.CLEAR)
	var kinds: Array[int] = []
	for a: Step.Activation in clear.activations:
		kinds.append(a.special)
	expect(Tile.Special.LINE_V in kinds and Tile.Special.BOMB in kinds, "line then bomb fired, got %s" % [kinds])


func test_fall_moves_tiles_down_and_refills() -> void:
	var res := _resolver([
		"1 2 3",
		"4 5 1",
		"0 0 3",
		"2 3 0",
	])
	var r := res.swap(Vector2i(2, 2), Vector2i(2, 3))
	var fall := _first(r, Step.Type.FALL)
	if expect(fall != null, "has a FALL step"):
		var new_tiles := fall.falls.filter(func(f: Step.Fall) -> bool: return f.is_new)
		expect_eq(new_tiles.size(), 3, "three new tiles")
		for f: Step.Fall in new_tiles:
			expect(f.from.y < 0, "new tiles start above the board")
	expect(res.board.is_full(), "board refilled")


func test_holes_stay_empty() -> void:
	var res := _resolver([
		"1 2 3 4",
		"# 0 0 3",
		"2 4 1 0",
		"3 1 2 4",
	])
	var top := res.board.get_tile(Vector2i(0, 0))
	var r := res.swap(Vector2i(3, 1), Vector2i(3, 2)) # row 1 becomes "# 0 0 0"
	expect(r.valid, "valid")
	expect(res.board.get_tile(Vector2i(0, 1)) == null, "hole has no tile")
	expect(res.board.get_tile(Vector2i(0, 0)) == top, "tile above the hole did not move")
	expect(res.board.is_full(), "board refilled")


func test_same_seed_same_result() -> void:
	var a := _resolver(["0 1 0 2", "1 0 1 2", "3 4 5 0", "4 5 3 1"], 6, 99)
	var b := _resolver(["0 1 0 2", "1 0 1 2", "3 4 5 0", "4 5 3 1"], 6, 99)
	a.swap(Vector2i(1, 0), Vector2i(1, 1))
	b.swap(Vector2i(1, 0), Vector2i(1, 1))
	expect_eq(a.board.dump(), b.board.dump(), "deterministic")


func test_cascade_multiplier() -> void:
	config.cascade_multiplier_step = 0.5
	config.points_per_tile = 10
	var res := _resolver(["0 0 1 0", "1 2 3 4", "2 3 4 1"])
	var r := res.swap(Vector2i(2, 0), Vector2i(3, 0))
	var clear := _first(r, Step.Type.CLEAR)
	expect_eq(clear.points, 30, "3 tiles x 10 at cascade 0")


func test_shuffle_when_no_moves() -> void:
	var res := _resolver(["0 1 2", "1 2 0", "2 0 1"], 3)
	expect(not Moves.has_any(res.board), "starts with no moves")
	var ids_before := res.board.positions().keys()
	ids_before.sort()
	var step := res.shuffle()
	expect_eq(step.type, Step.Type.SHUFFLE, "shuffle step")
	var ids_after := step.positions.keys()
	ids_after.sort()
	expect_eq(ids_after, ids_before, "same tiles after shuffle")
	expect(MatchFinder.find(res.board).is_empty(), "no matches after shuffle")


func test_random_play_keeps_invariants() -> void:
	# 300 random valid moves on generated boards: the board must always settle
	# full, match-free and playable.
	for board_seed: int in [1, 2, 3]:
		var board := Board.new(8, 8, 5, board_seed, [Vector2i(0, 0), Vector2i(7, 7), Vector2i(3, 4)])
		board.fill_random()
		var res := Resolver.new(board, config)
		for i: int in 100:
			var moves := Moves.all(board)
			if not expect(not moves.is_empty(), "seed %d move %d: has moves" % [board_seed, i]):
				return
			var m: Array = moves[board.rng.randi_range(0, moves.size() - 1)]
			var r := res.swap(m[0], m[1])
			if not expect(r.valid, "seed %d move %d: listed move is valid" % [board_seed, i]):
				return
		_expect_stable(res, "seed %d" % board_seed)
		expect(board.get_tile(Vector2i(0, 0)) == null and board.get_tile(Vector2i(3, 4)) == null, "holes stay empty")
