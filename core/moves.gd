class_name Moves
extends RefCounted
## Finds valid swaps. A swap is valid when it makes a match, or when both
## tiles are specials, or when either tile is a color bomb.

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]


## Every valid swap as [cell_a, cell_b] pairs, each pair listed once.
static func all(board: Board) -> Array[Array]:
	var out: Array[Array] = []
	for a: Vector2i in board.playable_cells():
		for d: Vector2i in DIRECTIONS:
			var b := a + d
			if is_valid(board, a, b):
				out.append([a, b])
	return out


static func has_any(board: Board) -> bool:
	for a: Vector2i in board.playable_cells():
		for d: Vector2i in DIRECTIONS:
			if is_valid(board, a, a + d):
				return true
	return false


## True if `a` and `b` are adjacent tiles and swapping them does something.
static func is_valid(board: Board, a: Vector2i, b: Vector2i) -> bool:
	if not are_adjacent(a, b):
		return false
	var ta := board.get_tile(a)
	var tb := board.get_tile(b)
	if ta == null or tb == null or not board.is_playable(a) or not board.is_playable(b):
		return false
	if ta.special == Tile.Special.COLOR or tb.special == Tile.Special.COLOR:
		return true
	if ta.is_special() and tb.is_special():
		return true
	board.swap(a, b)
	var ok := MatchFinder.has_match_at(board, a) or MatchFinder.has_match_at(board, b)
	board.swap(a, b)
	return ok


static func are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


## The move to suggest as a hint: the one that clears the most tiles right
## away, ties broken by board order. Returns [] if there is no move.
## `bonus` (optional) is called as bonus.call(board, group) -> int for every
## match a move would make, and adds to that move's value. The balance bot uses
## it to chase unmet goals; players' hints leave it empty.
static func best(board: Board, bonus: Callable = Callable()) -> Array:
	var best_move: Array = []
	var best_size := -1
	for move: Array in all(board):
		var a: Vector2i = move[0]
		var b: Vector2i = move[1]
		board.swap(a, b)
		var size := 0
		for g: MatchFinder.Group in MatchFinder.find(board):
			size += g.cells.size()
			if bonus.is_valid():
				size += int(bonus.call(board, g))
		board.swap(a, b)
		var ta := board.get_tile(a)
		var tb := board.get_tile(b)
		if ta.is_special() and tb.is_special():
			size += 10
		elif ta.special == Tile.Special.COLOR or tb.special == Tile.Special.COLOR:
			size += 8
		if size > best_size:
			best_size = size
			best_move = move
	return best_move
