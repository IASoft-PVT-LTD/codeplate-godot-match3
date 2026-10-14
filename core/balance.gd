class_name Balance
extends RefCounted
## A simple bot that plays the hint move, nudged toward the level's unmet
## goals. Used by the level checks and by tools/balance.gd to estimate how hard
## a level is. When you add a goal kind, teach the bot about it in _goal_bonus().


class Outcome:
	extends RefCounted
	var won: bool
	var score: int
	var stars: int
	var moves_used: int


static func play(level: LevelData, config: GameConfig, board_seed: int) -> Outcome:
	var s := LevelSession.new(level, config, board_seed)
	while s.state == LevelSession.State.PLAYING:
		var m := Moves.best(s.board, _goal_bonus.bind(s))
		if m.is_empty():
			break
		s.play(m[0], m[1])
	var o := Outcome.new()
	o.won = s.state == LevelSession.State.WON
	o.score = s.score
	o.stars = s.stars() if o.won else 0
	o.moves_used = level.moves - s.moves_left
	return o


## Extra value for a match that helps an unmet goal. Moves.best() passes
## (board, group); the session is bound after them (bind() appends).
static func _goal_bonus(_board: Board, g: MatchFinder.Group, s: LevelSession) -> int:
	var bonus := 0
	for i: int in s.level.goals.size():
		var goal := s.level.goals[i]
		if s.progress[i] >= goal.amount:
			continue
		match goal.kind:
			LevelData.GoalKind.COLLECT:
				if g.color == goal.color:
					bonus += g.cells.size()
			LevelData.GoalKind.SPECIALS:
				if g.create != Tile.Special.NONE:
					bonus += 6
	return bonus
