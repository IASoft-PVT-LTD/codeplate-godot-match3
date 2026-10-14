extends CheckCase
## Match detection and which special each shape creates.


func _groups(rows: PackedStringArray, prefer: Array[Vector2i] = []) -> Array[MatchFinder.Group]:
	return MatchFinder.find(Board.from_rows(rows, 6), prefer)


func test_no_match() -> void:
	expect_eq(_groups(["0 1 0", "1 0 1", "0 1 0"]).size(), 0, "checkerboard has no matches")


func test_three_in_a_row_creates_nothing() -> void:
	var g := _groups(["0 0 0 1", "1 2 3 4"])
	if expect_eq(g.size(), 1, "groups"):
		expect_eq(g[0].cells.size(), 3, "cells")
		expect_eq(g[0].color, 0, "color")
		expect_eq(g[0].create, Tile.Special.NONE, "special")


func test_four_horizontal_creates_line_h() -> void:
	var g := _groups(["2 2 2 2 1", "0 1 0 1 0"])
	if expect_eq(g.size(), 1, "groups"):
		expect_eq(g[0].create, Tile.Special.LINE_H, "special")


func test_four_vertical_creates_line_v() -> void:
	var g := _groups(["3 0", "3 1", "3 0", "3 1"])
	if expect_eq(g.size(), 1, "groups"):
		expect_eq(g[0].create, Tile.Special.LINE_V, "special")


func test_five_creates_color_bomb() -> void:
	var g := _groups(["4 4 4 4 4", "0 1 0 1 0"])
	if expect_eq(g.size(), 1, "groups"):
		expect_eq(g[0].create, Tile.Special.COLOR, "special")


func test_l_shape_creates_bomb_at_corner() -> void:
	var g := _groups(["1 0 0", "1 0 2", "1 1 1"])
	if expect_eq(g.size(), 1, "groups"):
		expect_eq(g[0].cells.size(), 5, "cells")
		expect_eq(g[0].create, Tile.Special.BOMB, "special")
		expect_eq(g[0].spawn_cell, Vector2i(0, 2), "spawn at the corner")


func test_spawn_prefers_swapped_cell() -> void:
	var g := _groups(["2 2 2 2"], [Vector2i(1, 0)])
	expect_eq(g[0].spawn_cell, Vector2i(1, 0), "spawn cell")


func test_two_separate_matches() -> void:
	expect_eq(_groups(["0 0 0", "1 2 3", "4 4 4"]).size(), 2, "groups")


func test_holes_break_runs() -> void:
	expect_eq(_groups(["0 0 # 0 0"]).size(), 0, "a hole splits the run")


func test_color_bombs_never_match() -> void:
	expect_eq(_groups(["* * * 1"]).size(), 0, "color bombs have no color")


func test_specials_match_by_color() -> void:
	var g := _groups(["2h 2 2v 1"])
	expect_eq(g.size(), 1, "specials still match by their color")


func test_has_match_at() -> void:
	var b := Board.from_rows(["0 1 1 1", "0 2 3 4", "0 3 4 5"], 6)
	expect(MatchFinder.has_match_at(b, Vector2i(0, 0)), "vertical run through (0,0)")
	expect(MatchFinder.has_match_at(b, Vector2i(2, 0)), "horizontal run through (2,0)")
	expect(not MatchFinder.has_match_at(b, Vector2i(1, 1)), "no run through (1,1)")
