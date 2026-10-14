class_name LevelScreen
extends Control
## Plays one level. Connects the rules (LevelSession) to the visuals
## (BoardView, Hud), sounds, the pause menu and the result panel.
## Opens the level in `Game.current_level`.

## Set before the scene enters the tree to get a fixed board (checks use this).
var board_seed: int = 0
var session: LevelSession

@onready var board_view: BoardView = %BoardView
@onready var hud: Hud = %Hud
@onready var bottom_bar: Control = %BottomBar
@onready var pause_button: Button = %PauseButton
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var result_panel: ResultPanel = %ResultPanel

var _running_score: int = 0


func _ready() -> void:
	var level := Game.level(Game.current_level)
	if level == null:
		push_error("LevelScreen: no level %d" % Game.current_level)
		return
	session = LevelSession.new(level, Game.config, board_seed)
	board_view.setup(session.board, Game.config)
	hud.setup(session)
	board_view.swap_requested.connect(request_swap)
	board_view.step_started.connect(_on_step_started)
	pause_button.pressed.connect(_pause)
	pause_menu.restart_pressed.connect(_restart)
	pause_menu.levels_pressed.connect(Game.goto_level_select)
	result_panel.next_pressed.connect(func() -> void: Game.play_level(Game.next_level(level.number)))
	result_panel.retry_pressed.connect(_restart)
	result_panel.levels_pressed.connect(Game.goto_level_select)
	resized.connect(_layout)
	hud.resized.connect(_layout)
	_layout()
	_intro()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not pause_menu.visible and not result_panel.visible:
		get_viewport().set_input_as_handled()
		_pause()


## Plays a swap: the same path as a player's tap or swipe. Awaitable.
func request_swap(a: Vector2i, b: Vector2i) -> void:
	if board_view.busy or session.state != LevelSession.State.PLAYING or pause_menu.visible:
		return
	_running_score = session.score
	var result := session.play(a, b)
	hud.refresh(true)
	hud.show_score(_running_score)
	await board_view.play(result)
	hud.refresh(true)
	if session.state != LevelSession.State.PLAYING:
		await _finish()


## Fits the board between the HUD and the bottom bar.
func _layout() -> void:
	if session == null:
		return
	var top := hud.position.y + hud.size.y + 28.0
	var bottom := size.y - bottom_bar.size.y + 12.0
	var area := Rect2(24.0, top, size.x - 48.0, maxf(bottom - top, 100.0))
	var px := board_view.pixel_size()
	var pad := Game.config.cell_size * 0.3
	var s := minf(area.size.x / (px.x + pad), area.size.y / (px.y + pad))
	s = minf(s, 1.3)
	board_view.scale = Vector2.ONE * s
	board_view.position = area.get_center() - px * s / 2.0


## Tiles drop in from above when the level starts.
func _intro() -> void:
	var drop := Step.make(Step.Type.FALL)
	for cell: Vector2i in session.board.playable_cells():
		var f := Step.Fall.new()
		f.tile = session.board.get_tile(cell)
		f.from = Vector2i(cell.x, cell.y - session.board.height - 1)
		f.to = cell
		drop.falls.append(f)
	var intro := Resolver.Result.new()
	intro.steps.append(drop)
	board_view.play(intro)


func _on_step_started(step: Step) -> void:
	var cfg := Game.config
	match step.type:
		Step.Type.SWAP:
			Audio.play(&"swap")
		Step.Type.SWAP_BACK:
			Audio.play(&"invalid")
		Step.Type.CLEAR:
			Audio.play(&"match", 1.0 + step.cascade * cfg.pitch_per_cascade)
			for act: Step.Activation in step.activations:
				match act.special:
					Tile.Special.LINE_H, Tile.Special.LINE_V: Audio.play(&"line")
					Tile.Special.BOMB: Audio.play(&"bomb")
					Tile.Special.COLOR: Audio.play(&"color_bomb")
			if not step.created.is_empty():
				Audio.play(&"special_create")
			_running_score += step.points
			hud.show_score(_running_score)
		Step.Type.SHUFFLE:
			Audio.play(&"shuffle")


func _finish() -> void:
	var won := session.state == LevelSession.State.WON
	await get_tree().create_timer(0.5).timeout
	var number := session.level.number
	if won:
		Game.record_result(number, session.stars(), session.score)
	Audio.play(&"win" if won else &"lose")
	result_panel.open(won, session.stars(), session.score, Game.best_score(number), session.bonus,
		Game.next_level(number) != 0)


func _pause() -> void:
	if result_panel.visible:
		return
	Audio.play(&"click")
	pause_menu.open()


func _restart() -> void:
	Game.play_level(session.level.number)
