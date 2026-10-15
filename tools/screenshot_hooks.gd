extends RefCounted
## Screens and setup for the CodePlate screenshot tool:
##
##   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=2 moves=3
##
## screen=settings and screen=credits open the shared settings screen over the
## title.
##
## Extra arguments understood here (screen=level only):
##   level=N           level number (default: 1)
##   seed=N            board seed, for repeatable shots (default: 4242)
##   moves=N           play N hint moves first, fast (default: 0)
##   action=SECONDS    then play one more move at normal speed and capture
##                     SECONDS after it starts (use with wait=0 for mid-animation)
##
## A --script file compiles before autoloads exist, so this file must not name
## classes whose code uses them (like LevelScreen). It uses get() and call().

const SCREENS := {
	"title": "res://ui/title.tscn",
	"levels": "res://ui/level_select.tscn",
	"level": "res://game/level.tscn",
	"settings": "res://ui/title.tscn",
	"credits": "res://ui/title.tscn",
}


func before_add(node: Node, args: Dictionary, tree: SceneTree) -> void:
	var game: Node = tree.root.get_node("Game")
	game.set("current_level", int(args.get("level", "1")))
	if node.get("board_seed") != null:
		node.set("board_seed", int(args.get("seed", "4242")))


func after_add(node: Node, args: Dictionary, tree: SceneTree) -> void:
	var screen := str(args.get("screen", ""))
	if screen == "settings" or screen == "credits":
		var settings: Node = node.call("open_settings")
		if screen == "credits":
			settings.call("show_credits")
		return
	if node.get("board_view") == null:
		return
	var game: Node = tree.root.get_node("Game")
	var board_view: Node2D = node.get("board_view")
	while board_view.get("busy"):
		await tree.process_frame
	var config: Resource = game.get("config")
	var speed: float = config.get("animation_speed")
	config.set("animation_speed", 50.0)
	for i: int in int(args.get("moves", "0")):
		var session: LevelSession = node.get("session")
		var m := Moves.best(session.board)
		if m.is_empty() or session.state != LevelSession.State.PLAYING:
			break
		await node.call("request_swap", m[0], m[1])
	config.set("animation_speed", speed)
	if args.has("action"):
		var m := Moves.best((node.get("session") as LevelSession).board)
		if not m.is_empty():
			node.call("request_swap", m[0], m[1])
			await tree.create_timer(float(args["action"])).timeout
