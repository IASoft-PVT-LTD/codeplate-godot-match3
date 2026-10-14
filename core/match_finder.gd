class_name MatchFinder
extends RefCounted
## Finds matches (3+ same-color tiles in a row or column) and decides which
## special each match creates. Pure logic.
##
## Special rules (change them here):
##   5+ in a line                      -> COLOR bomb
##   a horizontal and a vertical run
##   sharing a tile (L, T or + shape)  -> BOMB
##   4 in a horizontal line            -> LINE_H
##   4 in a vertical line              -> LINE_V
##   3                                 -> nothing


class Group:
	extends RefCounted
	var color: int
	var cells: Array[Vector2i] = []
	## The special this match creates, or NONE.
	var create: Tile.Special = Tile.Special.NONE
	## Where the new special appears (only meaningful when `create` isn't NONE).
	var spawn_cell: Vector2i


class _Run:
	var cells: Array[Vector2i] = []
	var horizontal: bool


## Every match on the board, merged into groups. `prefer` lists cells where a
## new special should appear if the group contains them (the swapped cells).
static func find(board: Board, prefer: Array[Vector2i] = []) -> Array[Group]:
	var runs := _runs(board)
	if runs.is_empty():
		return []

	# Merge runs that share a cell (L/T/+ shapes) using union-find over run indices.
	var parent: Array[int] = []
	for i: int in runs.size():
		parent.append(i)
	var owner: Dictionary[Vector2i, int] = {}
	for i: int in runs.size():
		for cell: Vector2i in runs[i].cells:
			if owner.has(cell):
				_union(parent, owner[cell], i)
			else:
				owner[cell] = i

	var by_root: Dictionary[int, Array] = {}
	for i: int in runs.size():
		var root := _find_root(parent, i)
		if not by_root.has(root):
			by_root[root] = []
		by_root[root].append(runs[i])

	var groups: Array[Group] = []
	for root: int in by_root.keys():
		groups.append(_make_group(board, by_root[root], prefer))
	return groups


## True if the tile at `cell` is part of a 3+ run. Fast local check for move search.
static func has_match_at(board: Board, cell: Vector2i) -> bool:
	var c := board.color_at(cell)
	if c == Tile.NO_COLOR:
		return false
	for axis: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
		var n := 1
		var p := cell + axis
		while board.color_at(p) == c:
			n += 1
			p += axis
		p = cell - axis
		while board.color_at(p) == c:
			n += 1
			p -= axis
		if n >= 3:
			return true
	return false


static func _runs(board: Board) -> Array[_Run]:
	var out: Array[_Run] = []
	for horizontal: bool in [true, false]:
		var outer := board.height if horizontal else board.width
		var inner := board.width if horizontal else board.height
		for o: int in outer:
			var i := 0
			while i < inner:
				var start := Vector2i(i, o) if horizontal else Vector2i(o, i)
				var c := board.color_at(start)
				var j := i + 1
				if c != Tile.NO_COLOR:
					while j < inner and board.color_at(Vector2i(j, o) if horizontal else Vector2i(o, j)) == c:
						j += 1
					if j - i >= 3:
						var run := _Run.new()
						run.horizontal = horizontal
						for k: int in range(i, j):
							run.cells.append(Vector2i(k, o) if horizontal else Vector2i(o, k))
						out.append(run)
				i = j
	return out


static func _make_group(board: Board, runs: Array, prefer: Array[Vector2i]) -> Group:
	var g := Group.new()
	var longest: _Run = runs[0]
	var has_h := false
	var has_v := false
	for run: _Run in runs:
		for cell: Vector2i in run.cells:
			if cell not in g.cells:
				g.cells.append(cell)
		if run.cells.size() > longest.cells.size():
			longest = run
		has_h = has_h or run.horizontal
		has_v = has_v or not run.horizontal
	g.color = board.color_at(g.cells[0])

	if longest.cells.size() >= 5:
		g.create = Tile.Special.COLOR
	elif has_h and has_v:
		g.create = Tile.Special.BOMB
	elif longest.cells.size() == 4:
		g.create = Tile.Special.LINE_H if longest.horizontal else Tile.Special.LINE_V

	if g.create != Tile.Special.NONE:
		g.spawn_cell = _spawn_cell(g, runs, longest, has_h and has_v, prefer)
	return g


static func _spawn_cell(g: Group, runs: Array, longest: _Run, is_cross: bool, prefer: Array[Vector2i]) -> Vector2i:
	for cell: Vector2i in prefer:
		if cell in g.cells:
			return cell
	if is_cross:
		# The tile shared by a horizontal and a vertical run: the corner of the L/T.
		for run: _Run in runs:
			for cell: Vector2i in run.cells:
				for other: _Run in runs:
					if other != run and other.horizontal != run.horizontal and cell in other.cells:
						return cell
	return longest.cells[longest.cells.size() / 2]


static func _find_root(parent: Array[int], i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


static func _union(parent: Array[int], a: int, b: int) -> void:
	parent[_find_root(parent, a)] = _find_root(parent, b)
