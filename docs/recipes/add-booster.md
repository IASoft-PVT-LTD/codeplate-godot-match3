# Add a booster (hammer)

Use when the user wants in-level boosters: tools the player uses without spending a move. The example is a **hammer** that smashes one tile (a special fires when smashed); the same steps fit a shuffle, a "+5 moves" or a color picker.

1. **Config** (`config/game_config.gd` + `.tres`). Before `@export_group("Feel")`:
   ```gdscript
   @export_group("Boosters")
   ## Hammers the player gets at the start of every level (0 = no hammer button).
   @export var hammers_per_level: int = 1
   ```
   and `hammers_per_level = 1` in `config/game_config.tres`. (For boosters that the player buys or earns, save a count in `autoload/game.gd` instead and pass it to the session.)
2. **The rule** (`core/resolver.gd`). Move the cascade loop at the end of `swap()` into its own function, so the hammer can reuse it. Replace everything from `var cascade := 0` to the end of `swap()` with `_settle(r)` and `return r`, then add:
   ```gdscript
   ## Booster: clears the tile at `cell` (a special fires), then the board falls
   ## and cascades as after a move. Needs no match.
   func smash(cell: Vector2i) -> Result:
   	var r := Result.new()
   	if not board.is_playable(cell) or board.get_tile(cell) == null:
   		return r
   	r.valid = true
   	_clear(r, {cell: true}, [], 0, {}, [])
   	_settle(r)
   	return r


   ## Falls, refills and cascades until nothing matches, then shuffles if no
   ## move is left.
   func _settle(r: Result) -> void:
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
   ```
3. **The session** (`core/level_session.gd`). Add `var hammers: int = 0` ("Hammers left this level.") after `var bonus`, and `hammers = config.hammers_per_level` after `moves_left = level.moves` in `_init()`. Split `play()` so scoring and goals are shared: after `moves_left -= 1`, call `_apply(r)` and `return r`, and move the rest of `play()` (from `score += r.points` to the win/lose check, without the final `return r`) into:
   ```gdscript
   ## Adds a result's points and goal progress, and checks for a win or loss.
   func _apply(r: Resolver.Result) -> void:
   	score += r.points
   	...  # the goal loop and the WON / LOST check, unchanged
   ```
   Then add:
   ```gdscript
   ## Uses a hammer on `cell`: clears that tile without using a move.
   func use_hammer(cell: Vector2i) -> Resolver.Result:
   	if state != State.PLAYING or hammers <= 0:
   		return Resolver.Result.new()
   	var r := resolver.smash(cell)
   	if r.valid:
   		hammers -= 1
   		_apply(r)
   	return r
   ```
4. **Taps go to the booster** (`game/board_view.gd`). Add after `var input_enabled`:
   ```gdscript
   ## When set, a tap on a tile calls this with the cell instead of selecting it
   ## (boosters use it). Callable(cell: Vector2i).
   var tap_override: Callable
   ```
   In `_unhandled_input()`, right after the first `get_viewport().set_input_as_handled()` (in the pressed branch):
   ```gdscript
   			if tap_override.is_valid():
   				_set_selected(NO_CELL)
   				tap_override.call(cell)
   				return
   ```
5. **The button** (`game/level.tscn`). In `BottomBar/Row`, after `PauseButton`, add a spacer and a toggle button:
   ```
   [node name="Spacer" type="Control" parent="BottomBar/Row"]
   layout_mode = 2
   size_flags_horizontal = 3
   mouse_filter = 2

   [node name="HammerButton" type="Button" parent="BottomBar/Row"]
   unique_name_in_owner = true
   custom_minimum_size = Vector2(240, 96)
   layout_mode = 2
   toggle_mode = true
   text = "Hammer"
   ```
6. **Wire it** (`game/level.gd`). Add `@onready var hammer_button: Button = %HammerButton`; in `_ready()`, after `pause_button.pressed.connect(_pause)`, add `hammer_button.toggled.connect(_arm_hammer)` and `_update_hammer()`. Then add:
   ```gdscript
   ## Uses a hammer on `cell`, like a player tapping with the hammer armed. Awaitable.
   func use_hammer(cell: Vector2i) -> void:
   	hammer_button.set_pressed_no_signal(false)
   	_arm_hammer(false)
   	if board_view.busy or session.state != LevelSession.State.PLAYING:
   		return
   	_running_score = session.score
   	var result := session.use_hammer(cell)
   	if not result.valid:
   		return
   	Audio.play(&"bomb")
   	_update_hammer()
   	await board_view.play(result)
   	hud.refresh(true)
   	if session.state != LevelSession.State.PLAYING:
   		await _finish()


   func _arm_hammer(on: bool) -> void:
   	board_view.tap_override = use_hammer if on else Callable()
   	if on:
   		Audio.play(&"click")


   func _update_hammer() -> void:
   	hammer_button.visible = Game.config.hammers_per_level > 0
   	hammer_button.text = "Hammer  %d" % session.hammers
   	hammer_button.disabled = session.hammers <= 0
   ```
   For an icon instead of text, draw a 64×64 hammer, list it in `assets.json`, and set the button's `icon` (see `PauseButton`).
7. **Add checks.** In `checks/tests/test_resolver.gd`:
   ```gdscript
   func test_hammer_clears_one_tile_and_settles() -> void:
   	var res := _resolver(["0 1 2 3", "4 5 0 1", "2 3 4 5", "0 1 2 3"])
   	var hit := res.board.get_tile(Vector2i(1, 2))
   	var r := res.smash(Vector2i(1, 2))
   	expect(r.valid, "a hammer on a tile is valid")
   	var clear := _first(r, Step.Type.CLEAR)
   	expect(clear != null and clear.cleared.size() >= 1 and clear.cleared[0].tile == hit, "the hit tile is cleared")
   	_expect_stable(res, "after the hammer")
   	expect(not res.smash(Vector2i(9, 9)).valid, "a hammer off the board does nothing")
   ```
   And in `checks/tests/test_scenes.gd`, through the real button and a real tap:
   ```gdscript
   func test_hammer_button_clears_a_tapped_tile() -> void:
   	_fast()
   	var level := await _open_level(1)
   	var moves := level.session.moves_left
   	var hammers := level.session.hammers
   	if not expect(hammers > 0 and level.hammer_button.is_visible_in_tree(), "the level starts with a hammer button"):
   		_restore()
   		return
   	level.hammer_button.button_pressed = true
   	var cell := Vector2i(2, 2)
   	var tile := level.session.board.get_tile(cell)
   	var p := level.board_view.cell_to_screen(cell)
   	mouse_button(p, true)
   	mouse_button(p, false)
   	await frames(2)
   	expect(await until(func() -> bool: return not level.board_view.busy), "the hammer animation finishes")
   	expect_eq(level.session.hammers, hammers - 1, "one hammer used")
   	expect_eq(level.session.moves_left, moves, "no move used")
   	expect(not level.session.board.positions().has(tile.id), "the tapped tile is gone")
   	expect(not level.hammer_button.button_pressed, "the hammer disarms after use")
   	_restore()
   ```

## Verify

1. Run the checks. The hint bot doesn't use boosters, so the balance report doesn't change; tell the user boosters make levels easier for players.
2. Take `screen=level level=2 moves=1` and look: the hammer button sits at the bottom right, clear of the board, with its count.
3. Ask the user to try it (`godot --path .`): tap Hammer, then a tile.
