class_name Board
extends RefCounted
## The grid: which cells are playable and which tile sits in each.
## Pure logic, no nodes. Cell (0, 0) is the top-left; y grows downward.

var width: int
var height: int
## Number of tile colors in play (colors are 0 .. colors - 1).
var colors: int
var rng: RandomNumberGenerator

var _playable: PackedByteArray
var _cells: Array[Tile] = []
var _next_id: int = 1


func _init(p_width: int, p_height: int, p_colors: int, p_seed: int, holes: Array[Vector2i] = []) -> void:
	width = p_width
	height = p_height
	colors = p_colors
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	_playable.resize(width * height)
	_playable.fill(1)
	for h: Vector2i in holes:
		if in_bounds(h):
			_playable[_index(h)] = 0
	_cells.resize(width * height)


## Builds a board from text, one string per row, cells separated by spaces.
## Tokens: a color digit (`0`..`9`), optionally followed by `h`, `v` or `b` for
## LINE_H, LINE_V or BOMB; `*` is a color bomb; `#` is a hole; `.` is empty.
## Tests use this to set up exact situations.
static func from_rows(rows: PackedStringArray, p_colors: int, p_seed: int = 1) -> Board:
	var grid: Array[PackedStringArray] = []
	for r: String in rows:
		grid.append(r.strip_edges().split(" ", false))
	var holes: Array[Vector2i] = []
	for y: int in grid.size():
		for x: int in grid[y].size():
			if grid[y][x] == "#":
				holes.append(Vector2i(x, y))
	var b := Board.new(grid[0].size(), grid.size(), p_colors, p_seed, holes)
	for y: int in grid.size():
		for x: int in grid[y].size():
			var tok: String = grid[y][x]
			if tok == "#" or tok == ".":
				continue
			if tok == "*":
				b.set_tile(Vector2i(x, y), b.new_tile(Tile.NO_COLOR, Tile.Special.COLOR))
				continue
			var special := Tile.Special.NONE
			match tok.substr(1):
				"h": special = Tile.Special.LINE_H
				"v": special = Tile.Special.LINE_V
				"b": special = Tile.Special.BOMB
			b.set_tile(Vector2i(x, y), b.new_tile(tok.substr(0, 1).to_int(), special))
	return b


## Fills every playable cell with random colors so that no match exists yet
## and at least one valid move does.
func fill_random() -> void:
	for attempt: int in 100:
		for y: int in height:
			for x: int in width:
				var cell := Vector2i(x, y)
				if is_playable(cell):
					set_tile(cell, new_tile(_color_without_match(cell)))
		if Moves.has_any(self):
			return
	push_error("Board.fill_random: no valid layout after 100 attempts; check the level's size, holes and colors")


## Creates a tile with a fresh id. It is not placed on the board.
func new_tile(color: int, special: Tile.Special = Tile.Special.NONE) -> Tile:
	var t := Tile.new(_next_id, color, special)
	_next_id += 1
	return t


func random_color() -> int:
	return rng.randi_range(0, colors - 1)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_playable(cell: Vector2i) -> bool:
	return in_bounds(cell) and _playable[_index(cell)] == 1


func get_tile(cell: Vector2i) -> Tile:
	if not in_bounds(cell):
		return null
	return _cells[_index(cell)]


func set_tile(cell: Vector2i, tile: Tile) -> void:
	_cells[_index(cell)] = tile


func swap(a: Vector2i, b: Vector2i) -> void:
	var t := get_tile(a)
	set_tile(a, get_tile(b))
	set_tile(b, t)


## All playable cells, row by row.
func playable_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in height:
		for x: int in width:
			if _playable[y * width + x] == 1:
				out.append(Vector2i(x, y))
	return out


## Where each tile is, by tile id. Used by the view and by tests.
func positions() -> Dictionary[int, Vector2i]:
	var out: Dictionary[int, Vector2i] = {}
	for cell: Vector2i in playable_cells():
		var t := get_tile(cell)
		if t != null:
			out[t.id] = cell
	return out


## True when every playable cell holds a tile.
func is_full() -> bool:
	for cell: Vector2i in playable_cells():
		if get_tile(cell) == null:
			return false
	return true


## The color of the tile at `cell` for matching, or Tile.NO_COLOR.
func color_at(cell: Vector2i) -> int:
	var t := get_tile(cell)
	return t.color if t != null else Tile.NO_COLOR


func _index(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func _color_without_match(cell: Vector2i) -> int:
	var banned: Array[int] = []
	var left := cell + Vector2i.LEFT
	if color_at(left) != Tile.NO_COLOR and color_at(left) == color_at(left + Vector2i.LEFT):
		banned.append(color_at(left))
	var up := cell + Vector2i.UP
	if color_at(up) != Tile.NO_COLOR and color_at(up) == color_at(up + Vector2i.UP):
		banned.append(color_at(up))
	var choices: Array[int] = []
	for c: int in colors:
		if c not in banned:
			choices.append(c)
	return choices[rng.randi_range(0, choices.size() - 1)]


## Debug view: one character per cell. `.` empty, `#` hole, digits are colors,
## `*` a color bomb. Specials are marked after the digit: h, v, b.
func dump() -> String:
	var lines: PackedStringArray = []
	for y: int in height:
		var row := ""
		for x: int in width:
			var cell := Vector2i(x, y)
			var t := get_tile(cell)
			if not is_playable(cell):
				row += " # "
			elif t == null:
				row += " . "
			elif t.special == Tile.Special.COLOR:
				row += " * "
			else:
				row += " %d%s" % [t.color, ["", "h", "v", "b", ""][t.special]]
				row += "" if t.is_special() else " "
		lines.append(row)
	return "\n".join(lines)
