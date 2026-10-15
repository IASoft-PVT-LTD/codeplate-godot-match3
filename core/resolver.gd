class_name Resolver
extends RefCounted
## Applies a swap to the board and resolves everything that follows: matches,
## special activations and combos, falling, refilling, cascades, and a
## shuffle when no moves are left. Records it all as Steps for the view.
## Pure logic: same board + same seed + same swaps = same result.


class Result:
	extends RefCounted
	## False when the swap did nothing (no match). It then costs no move.
	var valid: bool = false
	var steps: Array[Step] = []
	var points: int = 0
	## Tiles cleared per color (color index -> count). Used by COLLECT goals.
	var collected: Dictionary[int, int] = {}
	## Specials created per type (Tile.Special -> count).
	var specials_created: Dictionary[int, int] = {}
	## Highest cascade reached (0 = only the swap's own clears).
	var max_cascade: int = 0


var board: Board
var config: GameConfig


func _init(p_board: Board, p_config: GameConfig = null) -> void:
	board = p_board
	config = p_config if p_config != null else GameConfig.new()


## Swaps the tiles at `a` and `b` and resolves the board until it is stable.
func swap(a: Vector2i, b: Vector2i) -> Result:
	var r := Result.new()
	if not Moves.is_valid(board, a, b):
		if Moves.are_adjacent(a, b) and board.get_tile(a) != null and board.get_tile(b) != null:
			var back := Step.make(Step.Type.SWAP_BACK)
			back.a = a
			back.b = b
			back.tile_a = board.get_tile(a)
			back.tile_b = board.get_tile(b)
			r.steps.append(back)
		return r

	r.valid = true
	var swap_step := Step.make(Step.Type.SWAP)
	swap_step.a = a
	swap_step.b = b
	swap_step.tile_a = board.get_tile(a)
	swap_step.tile_b = board.get_tile(b)
	board.swap(a, b)
	r.steps.append(swap_step)

	var moved := board.get_tile(b) # the tile the player dragged, now at b
	var other := board.get_tile(a)
	if moved.special == Tile.Special.COLOR or other.special == Tile.Special.COLOR \
			or (moved.is_special() and other.is_special()):
		_resolve_combo(r, b, a)
	else:
		_clear(r, {}, MatchFinder.find(board, [b, a]), 0, {}, [])

	var cascade := 0
	while true:
		r.steps.append(_fall_and_refill())
		var groups := MatchFinder.find(board)
		if groups.is_empty():
			break
		cascade += 1
		_clear(r, {}, groups, cascade, {}, [])
	r.max_cascade = cascade

	if not Moves.has_any(board):
		r.steps.append(shuffle())
	return r


## Rearranges the tiles until there is no match and at least one move.
func shuffle() -> Step:
	var step := Step.make(Step.Type.SHUFFLE)
	var cells := board.playable_cells()
	var tiles: Array[Tile] = []
	for cell: Vector2i in cells:
		tiles.append(board.get_tile(cell))
	for attempt: int in 200:
		if attempt >= 100:
			# Rare: this layout can't be shuffled into a playable board. Recolor plain tiles.
			for t: Tile in tiles:
				if not t.is_special():
					t.color = board.random_color()
		for i: int in range(tiles.size() - 1, 0, -1):
			var j := board.rng.randi_range(0, i)
			var tmp := tiles[i]
			tiles[i] = tiles[j]
			tiles[j] = tmp
		for i: int in cells.size():
			board.set_tile(cells[i], tiles[i])
		if MatchFinder.find(board).is_empty() and Moves.has_any(board):
			break
	step.positions = board.positions()
	return step


func _resolve_combo(r: Result, at: Vector2i, other_at: Vector2i) -> void:
	var t1 := board.get_tile(at)
	var t2 := board.get_tile(other_at)
	var seeds: Dictionary[Vector2i, bool] = {at: true, other_at: true}
	var done: Dictionary[int, bool] = {t1.id: true, t2.id: true}
	var acts: Array[Step.Activation] = []
	var act := Step.Activation.new()
	act.cell = at

	var color_bomb := t1 if t1.special == Tile.Special.COLOR else (t2 if t2.special == Tile.Special.COLOR else null)
	if t1.special == Tile.Special.COLOR and t2.special == Tile.Special.COLOR:
		# Two color bombs: clear the whole board.
		act.special = Tile.Special.COLOR
		act.cells = board.playable_cells()
	elif color_bomb != null:
		var partner := t2 if color_bomb == t1 else t1
		act.special = Tile.Special.COLOR
		act.color = partner.color
		act.cells.append(at)
		act.cells.append(other_at)
		for cell: Vector2i in board.playable_cells():
			var t := board.get_tile(cell)
			if t != null and t.color == partner.color and cell not in act.cells:
				act.cells.append(cell)
				if partner.is_special():
					# Color bomb + special: every tile of that color becomes that special and fires.
					t.special = partner.special
					if partner.is_line():
						t.special = Tile.Special.LINE_H if board.rng.randi() % 2 == 0 else Tile.Special.LINE_V
		if partner.is_special():
			done.erase(partner.id) # the partner fires its own effect too
	else:
		# Two specials (lines and bombs): a bigger blast centered on `at`.
		var lines := int(t1.is_line()) + int(t2.is_line())
		if lines == 0:
			# bomb + bomb: one big bomb
			act.special = Tile.Special.BOMB
			act.cells = _square(at, config.bomb_radius + 1)
		else:
			# line + line: a cross; line + bomb: three rows and three columns
			var spread := 0 if lines == 2 else 1
			act = null
			for d: int in range(-spread, spread + 1):
				for horizontal: bool in [true, false]:
					var line := Step.Activation.new()
					line.special = Tile.Special.LINE_H if horizontal else Tile.Special.LINE_V
					line.cell = at + (Vector2i(0, d) if horizontal else Vector2i(d, 0))
					line.cells = _row(at.y + d) if horizontal else _column(at.x + d)
					acts.append(line)
	if act != null:
		acts.append(act)
	for a: Step.Activation in acts:
		for cell: Vector2i in a.cells:
			seeds[cell] = true
	_clear(r, seeds, [], 0, done, acts)


## Clears the seeds and match groups, fires every special they hit (chain
## reactions included), places newly created specials, and records one CLEAR step.
## `done` holds ids of specials that already fired; `acts` are activations so far.
func _clear(r: Result, seeds: Dictionary[Vector2i, bool], groups: Array[MatchFinder.Group],
		cascade: int, done: Dictionary[int, bool], acts: Array[Step.Activation]) -> void:
	var step := Step.make(Step.Type.CLEAR)
	step.cascade = cascade
	step.activations = acts
	var to_clear: Dictionary[Vector2i, bool] = seeds.duplicate()
	for g: MatchFinder.Group in groups:
		for cell: Vector2i in g.cells:
			to_clear[cell] = true

	# Chain reactions: any special inside the cleared area fires.
	var queue: Array[Vector2i] = to_clear.keys()
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var t := board.get_tile(cell)
		if t == null or not t.is_special() or done.has(t.id):
			continue
		done[t.id] = true
		var act := _activate(t, cell)
		step.activations.append(act)
		for hit: Vector2i in act.cells:
			if not to_clear.has(hit):
				to_clear[hit] = true
				queue.append(hit)

	for cell: Vector2i in to_clear.keys():
		var t := board.get_tile(cell)
		if t == null or not board.is_playable(cell):
			continue
		var c := Step.Cleared.new()
		c.tile = t
		c.cell = cell
		step.cleared.append(c)
		if t.color != Tile.NO_COLOR:
			r.collected[t.color] = r.collected.get(t.color, 0) + 1
		board.set_tile(cell, null)

	for g: MatchFinder.Group in groups:
		if g.create == Tile.Special.NONE:
			continue
		var color := Tile.NO_COLOR if g.create == Tile.Special.COLOR else g.color
		var tile := board.new_tile(color, g.create)
		board.set_tile(g.spawn_cell, tile)
		var created := Step.Created.new()
		created.tile = tile
		created.cell = g.spawn_cell
		step.created.append(created)
		r.specials_created[g.create] = r.specials_created.get(g.create, 0) + 1

	var multiplier := 1.0 + cascade * config.cascade_multiplier_step
	step.points = int(round(step.cleared.size() * config.points_per_tile * multiplier)) \
		+ step.created.size() * config.special_create_bonus
	r.points += step.points
	r.steps.append(step)


## What a single special hits when it fires on its own.
func _activate(t: Tile, cell: Vector2i) -> Step.Activation:
	var act := Step.Activation.new()
	act.special = t.special
	act.cell = cell
	match t.special:
		Tile.Special.LINE_H:
			act.cells = _row(cell.y)
		Tile.Special.LINE_V:
			act.cells = _column(cell.x)
		Tile.Special.BOMB:
			act.cells = _square(cell, config.bomb_radius)
		Tile.Special.COLOR:
			# Hit by another blast: clears the most common color on the board.
			act.color = _most_common_color()
			act.cells.append(cell)
			for c: Vector2i in board.playable_cells():
				var other := board.get_tile(c)
				if other != null and other.color == act.color:
					act.cells.append(c)
	return act


func _fall_and_refill() -> Step:
	var step := Step.make(Step.Type.FALL)
	for x: int in board.width:
		var column: Array[Vector2i] = []
		for y: int in board.height:
			if board.is_playable(Vector2i(x, y)):
				column.append(Vector2i(x, y))
		if column.is_empty():
			continue
		var tiles: Array[Tile] = []
		var from_cells: Array[Vector2i] = []
		for cell: Vector2i in column:
			var t := board.get_tile(cell)
			if t != null:
				tiles.append(t)
				from_cells.append(cell)
		var empties := column.size() - tiles.size()
		for i: int in tiles.size():
			var to := column[empties + i]
			board.set_tile(to, tiles[i])
			if to != from_cells[i]:
				var f := Step.Fall.new()
				f.tile = tiles[i]
				f.from = from_cells[i]
				f.to = to
				step.falls.append(f)
		for i: int in empties:
			var t := board.new_tile(board.random_color())
			board.set_tile(column[i], t)
			var f := Step.Fall.new()
			f.tile = t
			f.from = Vector2i(x, column[0].y - empties + i)
			f.to = column[i]
			f.is_new = true
			step.falls.append(f)
	return step


func _most_common_color() -> int:
	var counts: Dictionary[int, int] = {}
	var best := 0
	for cell: Vector2i in board.playable_cells():
		var t := board.get_tile(cell)
		if t != null and t.color != Tile.NO_COLOR:
			counts[t.color] = counts.get(t.color, 0) + 1
	for c: int in counts.keys():
		if counts[c] > counts.get(best, 0):
			best = c
	return best


func _row(y: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x: int in board.width:
		if board.is_playable(Vector2i(x, y)):
			out.append(Vector2i(x, y))
	return out


func _column(x: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in board.height:
		if board.is_playable(Vector2i(x, y)):
			out.append(Vector2i(x, y))
	return out


func _square(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			var cell := center + Vector2i(dx, dy)
			if board.is_playable(cell):
				out.append(cell)
	return out
