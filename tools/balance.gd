extends SceneTree
## Balance report: a bot plays each level many times and prints win rate,
## average score and stars. Use it after changing levels or scoring.
##
##   godot --headless --path . --script res://tools/balance.gd
##   godot --headless --path . --script res://tools/balance.gd -- level=3 runs=50
##
## The bot always plays the hint move (Moves.best), so it is a little better
## than a new player and worse than a good one. Aim for roughly:
##   early levels 90%+ wins, middle 60-85%, hardest 35-60%.
## "suggested stars" are the 20th, 50th and 85th percentile of winning scores:
## copy them into the level's "stars" if the current ones feel off.


func _initialize() -> void:
	preload("res://addons/codeplate/checks/run.gd").watchdog(self, 600.0)
	_run.call_deferred()


func _run() -> void:
	var args := {}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var only := int(args.get("level", "0"))
	var runs := int(args.get("runs", "20"))
	var game: Node = root.get_node("Game")
	print("level  win%%   avg score  avg stars  avg moves  stars now            suggested stars      title   (%d runs each)" % runs)
	for level: LevelData in game.levels:
		if only != 0 and level.number != only:
			continue
		var wins := 0
		var score := 0
		var stars := 0
		var moves := 0
		var win_scores: Array[int] = []
		for i: int in runs:
			var o := Balance.play(level, game.config, 1000 + i)
			wins += int(o.won)
			score += o.score
			stars += o.stars
			moves += o.moves_used
			if o.won:
				win_scores.append(o.score)
		win_scores.sort()
		var suggested := "-"
		if win_scores.size() >= 3:
			suggested = str([_pct(win_scores, 0.2), _pct(win_scores, 0.5), _pct(win_scores, 0.85)])
		print("%5d  %4d  %10d  %9.1f  %9.1f  %-19s  %-19s  %s" % [level.number, 100 * wins / runs, score / runs,
			float(stars) / runs, float(moves) / runs, str(level.stars), suggested, level.title])
	quit(0)


## The p-th percentile of sorted scores, rounded to 100.
func _pct(sorted: Array[int], p: float) -> int:
	var v := sorted[clampi(int(p * (sorted.size() - 1)), 0, sorted.size() - 1)]
	return maxi(100, int(round(v / 100.0)) * 100)
