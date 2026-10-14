class_name LevelSession
extends RefCounted
## One play of a level: board, moves left, score and goal progress.
## Pure logic; level.tscn drives it from player input.

enum State { PLAYING, WON, LOST }

var level: LevelData
var config: GameConfig
var board: Board
var resolver: Resolver
var state: State = State.PLAYING
var moves_left: int
var score: int = 0
## Progress per goal, same order as level.goals.
var progress: Array[int] = []
## Bonus from unused moves, set when the level is won.
var bonus: int = 0


func _init(p_level: LevelData, p_config: GameConfig, p_seed: int = 0) -> void:
	level = p_level
	config = p_config
	var board_seed := p_seed if p_seed != 0 else (level.board_seed if level.board_seed != 0 else randi())
	board = Board.new(level.width, level.height, level.colors, board_seed, level.holes)
	board.fill_random()
	resolver = Resolver.new(board, config)
	moves_left = level.moves
	for g: LevelData.Goal in level.goals:
		progress.append(0)


## Plays a swap. Invalid swaps cost nothing. Updates score, goals and state.
func play(a: Vector2i, b: Vector2i) -> Resolver.Result:
	if state != State.PLAYING:
		return Resolver.Result.new()
	var r := resolver.swap(a, b)
	if not r.valid:
		return r
	moves_left -= 1
	score += r.points
	for i: int in level.goals.size():
		var g := level.goals[i]
		match g.kind:
			LevelData.GoalKind.SCORE:
				progress[i] = score
			LevelData.GoalKind.COLLECT:
				progress[i] += r.collected.get(g.color, 0)
			LevelData.GoalKind.SPECIALS:
				for n: int in r.specials_created.values():
					progress[i] += n
	if goals_met():
		state = State.WON
		bonus = moves_left * config.points_per_move_left
		score += bonus
	elif moves_left <= 0:
		state = State.LOST
	return r


func goals_met() -> bool:
	for i: int in level.goals.size():
		if progress[i] < level.goals[i].amount:
			return false
	return true


## 0..3 stars for the current score. A won level always earns at least 1.
func stars() -> int:
	var n := 0
	for s: int in level.stars:
		if score >= s:
			n += 1
	if state == State.WON:
		n = maxi(n, 1)
	return n
