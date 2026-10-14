class_name LevelData
extends RefCounted
## One level, loaded from levels/level_NN.json. See docs/levels.md for the format.

enum GoalKind {
	SCORE, ## Reach `amount` points.
	COLLECT, ## Clear `amount` tiles of `color`.
	SPECIALS, ## Create `amount` specials of any kind.
}


class Goal:
	extends RefCounted
	var kind: GoalKind
	var color: int = -1
	var amount: int


## File number: level_03.json has number 3.
var number: int
var title: String
var width: int
var height: int
var colors: int
var moves: int
var goals: Array[Goal] = []
## Scores for 1, 2 and 3 stars, ascending.
var stars: Array[int] = []
var holes: Array[Vector2i] = []
## 0 means a different board every play; anything else gives the same board every time.
var board_seed: int = 0


const LEVELS_DIR := "res://levels"


## Paths of every level file, in play order.
static func list_paths() -> PackedStringArray:
	var out: PackedStringArray = []
	for f: String in DirAccess.get_files_at(LEVELS_DIR):
		if f.begins_with("level_") and f.ends_with(".json"):
			out.append(LEVELS_DIR.path_join(f))
	out.sort()
	return out


## Loads and validates a level. On failure returns null and appends messages to `errors`.
static func load_file(path: String, max_colors: int, errors: PackedStringArray) -> LevelData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		errors.append("%s: missing or empty" % path)
		return null
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		errors.append("%s: not a JSON object" % path)
		return null
	var level := from_dict(data, max_colors, errors, path)
	if level != null:
		level.number = path.get_file().get_basename().trim_prefix("level_").to_int()
	return level


static func from_dict(d: Dictionary, max_colors: int, errors: PackedStringArray, where: String = "level") -> LevelData:
	var start := errors.size()
	var fail := func(msg: String) -> void: errors.append("%s: %s" % [where, msg])
	var allowed := ["title", "width", "height", "colors", "moves", "goals", "stars", "holes", "seed"]
	for key: Variant in d.keys():
		if key not in allowed:
			fail.call("unknown key \"%s\" (allowed: %s)" % [key, ", ".join(allowed)])

	var l := LevelData.new()
	l.title = str(d.get("title", ""))
	l.width = _int(d, "width", 8, fail)
	l.height = _int(d, "height", 8, fail)
	l.colors = _int(d, "colors", 5, fail)
	l.moves = _int(d, "moves", 20, fail)
	l.board_seed = _int(d, "seed", 0, fail)
	if l.width < 3 or l.width > 10 or l.height < 3 or l.height > 10:
		fail.call("width and height must be 3..10")
	if l.colors < 3 or l.colors > max_colors:
		fail.call("colors must be 3..%d (max_colors in config/game_config.tres)" % max_colors)
	if l.moves < 1:
		fail.call("moves must be at least 1")

	var stars: Variant = d.get("stars", [])
	if not stars is Array or stars.size() != 3:
		fail.call("stars must be a list of 3 scores")
	else:
		for s: Variant in stars:
			l.stars.append(int(s))
		if not (l.stars[0] > 0 and l.stars[0] < l.stars[1] and l.stars[1] < l.stars[2]):
			fail.call("stars must be positive and ascending")

	var holes: Variant = d.get("holes", [])
	if not holes is Array:
		fail.call("holes must be a list of [x, y]")
	else:
		for h: Variant in holes:
			if not h is Array or h.size() != 2:
				fail.call("each hole must be [x, y]")
				continue
			var cell := Vector2i(int(h[0]), int(h[1]))
			if cell.x < 0 or cell.y < 0 or cell.x >= l.width or cell.y >= l.height:
				fail.call("hole %s is outside the board" % cell)
			l.holes.append(cell)

	var goals: Variant = d.get("goals", [])
	if not goals is Array or goals.is_empty():
		fail.call("goals must be a non-empty list")
	else:
		for g: Variant in goals:
			if not g is Dictionary:
				fail.call("each goal must be an object")
				continue
			var goal := Goal.new()
			var kind := str(g.get("kind", ""))
			match kind:
				"score": goal.kind = GoalKind.SCORE
				"collect": goal.kind = GoalKind.COLLECT
				"specials": goal.kind = GoalKind.SPECIALS
				_:
					fail.call("goal kind \"%s\" must be score, collect or specials" % kind)
					continue
			goal.amount = int(g.get("amount", 0))
			if goal.amount < 1:
				fail.call("goal amount must be at least 1")
			if goal.kind == GoalKind.COLLECT:
				goal.color = int(g.get("color", -1))
				if goal.color < 0 or goal.color >= l.colors:
					fail.call("collect goal color must be 0..%d for a level with %d colors" % [l.colors - 1, l.colors])
			l.goals.append(goal)
	return l if errors.size() == start else null


static func _int(d: Dictionary, key: String, default: int, fail: Callable) -> int:
	var v: Variant = d.get(key, default)
	if not (v is int or v is float) or float(v) != floorf(float(v)):
		fail.call("%s must be a whole number" % key)
		return default
	return int(v)
