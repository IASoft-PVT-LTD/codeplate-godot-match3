# Add a blocker (ice)

Use when the user wants obstacles on the board: cells covered in ice (one or two layers) that break when a match clears the tile on them, and a level goal to break all the ice.

Ice belongs to the **cell**, not the tile: tiles move, match and fall as usual, and clearing the tile that sits on an iced cell breaks one layer. That keeps swaps, falls and shuffles unchanged. (A crate that takes up a cell and stops tiles falling is a bigger change: falls, refills, `Moves` and shuffles all need to skip it. Plan it with the user if they need that.)

1. **Art.** Add `assets/tiles/ice.png`: a square, mostly transparent frosty overlay (frame, glints, cracks), any size (96×96 is plenty). It's drawn **over** the tile, so the gem must stay visible through it. Use the user's art, or draw one with a short script (Python Pillow: a rounded rectangle with a light-blue fill at about 45% alpha, a bright border and a few white crack lines). List it in `assets.json` with its size, and set `license`/`credit` as rule 8 says.
2. **Board** (`core/board.gd`). Add a layer count per cell next to `_playable`:
   ```gdscript
   ## Ice layers per cell (0 = none). Clearing the tile on an iced cell breaks one layer.
   var _ice: PackedByteArray
   ```
   In `_init()`, after `_cells.resize(width * height)`, add `_ice.resize(width * height)`. Then add, above `swap()`:
   ```gdscript
   func ice_at(cell: Vector2i) -> int:
   	return _ice[_index(cell)] if in_bounds(cell) else 0


   func set_ice(cell: Vector2i, layers: int) -> void:
   	_ice[_index(cell)] = clampi(layers, 0, 255)


   ## Ice layers left on the whole board.
   func ice_left() -> int:
   	var n := 0
   	for v: int in _ice:
   		n += v
   	return n
   ```
3. **Record broken ice.** In `core/step.gd`, after `var falls`, add:
   ```gdscript
   ## CLEAR: cells whose ice lost a layer.
   var ice_broken: Array[Vector2i] = []
   ```
   In `core/resolver.gd`, add `var ice_broken: int = 0` (comment: "Ice layers broken. Used by ICE goals.") to `class Result`, and in `_clear()`, right after `board.set_tile(cell, null)`:
   ```gdscript
   		if board.ice_at(cell) > 0:
   			board.set_ice(cell, board.ice_at(cell) - 1)
   			step.ice_broken.append(cell)
   			r.ice_broken += 1
   ```
4. **Levels and the goal** (`core/level_data.gd`):
   - Add `ICE, ## Break `amount` layers of ice.` to `GoalKind`, and `var ice: Dictionary[Vector2i, int] = {}` ("Iced cells: cell -> layers (1 or 2).") next to `holes`.
   - Add `"ice"` to `allowed` in `from_dict()`.
   - Before `var goals: Variant = d.get("goals", [])`, parse the ice:
     ```gdscript
     	var ice: Variant = d.get("ice", [])
     	if not ice is Array:
     		fail.call("ice must be a list of [x, y] or [x, y, layers]")
     	else:
     		for e: Variant in ice:
     			if not e is Array or e.size() < 2 or e.size() > 3:
     				fail.call("each ice entry must be [x, y] or [x, y, layers]")
     				continue
     			var cell := Vector2i(int(e[0]), int(e[1]))
     			var layers: int = int(e[2]) if e.size() == 3 else 1
     			if cell.x < 0 or cell.y < 0 or cell.x >= l.width or cell.y >= l.height or cell in l.holes:
     				fail.call("ice %s must be on a playable cell" % cell)
     			if layers < 1 or layers > 2:
     				fail.call("ice layers must be 1 or 2")
     			l.ice[cell] = layers
     ```
   - In the goal `match kind:`, add `"ice": goal.kind = GoalKind.ICE`, and add `ice` to the error message's list of kinds.
   - Just before `l.goals.append(goal)`, check the goal can be met:
     ```gdscript
     			if goal.kind == GoalKind.ICE:
     				var total := 0
     				for v: int in l.ice.values():
     					total += v
     				if goal.amount > total:
     					fail.call("ice goal amount %d is more than the %d ice layers on the board" % [goal.amount, total])
     ```
5. **Session** (`core/level_session.gd`). After `board.fill_random()`:
   ```gdscript
   	for cell: Vector2i in level.ice:
   		board.set_ice(cell, level.ice[cell])
   ```
   and in `play()`'s goal `match`, add:
   ```gdscript
   			LevelData.GoalKind.ICE:
   				progress[i] += r.ice_broken
   ```
6. **Teach the bot** (`core/balance.gd`), or ice levels look impossible to it. Rename `_goal_bonus()`'s first parameter from `_board` to `board`, and add to its `match goal.kind:`:
   ```gdscript
   			LevelData.GoalKind.ICE:
   				for cell: Vector2i in g.cells:
   					bonus += 3 * board.ice_at(cell)
   ```
7. **Draw it.**
   - `game/tile_skin.gd`: `const ICE_PATH := "res://assets/tiles/ice.png"`.
   - `game/board_view.gd`: the board is already ahead of the animation, so the view keeps its own copy of the ice and updates it as CLEAR steps play. Add the fields after `var _fx: Fx`:
     ```gdscript
     var _ice_layer: Node2D
     var _ice: Dictionary[Vector2i, int] = {}
     ```
     In `setup()`, just before `_fx = Fx.new()` (so ice sits over the tiles and under the effects):
     ```gdscript
     	_ice.clear()
     	for cell: Vector2i in board.playable_cells():
     		if board.ice_at(cell) > 0:
     			_ice[cell] = board.ice_at(cell)
     	_ice_layer = Node2D.new()
     	_ice_layer.draw.connect(_draw_ice)
     	_content.add_child(_ice_layer)
     ```
     In `_animate_clear()`, before the `for cr: Step.Created` loop:
     ```gdscript
     	for cell: Vector2i in step.ice_broken:
     		_ice[cell] = _ice.get(cell, 1) - 1
     		_fx.ring(cell_center(cell), Color(0.8, 0.95, 1.0), _cell * 0.7, config.t(0.3))
     	if not step.ice_broken.is_empty():
     		_ice_layer.queue_redraw()
     ```
     And add the drawing function above `_draw_backdrop()`:
     ```gdscript
     func _draw_ice() -> void:
     	var tex := TileSkin.texture(TileSkin.ICE_PATH)
     	for cell: Vector2i in _ice:
     		if _ice[cell] > 0:
     			var alpha := 0.6 if _ice[cell] == 1 else 1.0
     			_ice_layer.draw_texture_rect(tex, Rect2(Vector2(cell) * _cell, Vector2.ONE * _cell), false, Color(1, 1, 1, alpha))
     ```
   - `game/hud.gd`: in the goal icon `match`, add `LevelData.GoalKind.ICE: icon.texture = TileSkin.texture(TileSkin.ICE_PATH)`.
8. **A level with ice.** Add `levels/level_11.json` (or add ice to an existing level):
   ```json
   {
     "title": "Thin Ice", "width": 8, "height": 8, "colors": 5, "moves": 24,
     "ice": [[2, 2], [3, 2], [4, 2], [5, 2], [2, 3], [3, 3, 2], [4, 3, 2], [5, 3],
             [2, 4], [3, 4, 2], [4, 4, 2], [5, 4], [2, 5], [3, 5], [4, 5], [5, 5]],
     "goals": [{"kind": "ice", "amount": 20}],
     "stars": [2700, 3200, 3600]
   }
   ```
   Run `tools/balance.gd -- level=11` and paste its suggested stars (this one won 90% of bot runs).
9. **Add checks** to `checks/tests/test_resolver.gd`:
   ```gdscript
   func test_clearing_a_tile_on_ice_breaks_one_layer() -> void:
   	var res := _resolver(["0 1 0 2", "1 0 3 4", "2 3 4 5"])
   	res.board.set_ice(Vector2i(1, 0), 2) # the cell where the swap's match lands
   	res.board.set_ice(Vector2i(3, 2), 1) # untouched
   	var r := res.swap(Vector2i(1, 0), Vector2i(1, 1))
   	expect(r.valid, "the swap matches")
   	expect_eq(res.board.ice_at(Vector2i(1, 0)), 1, "one layer broke")
   	expect_eq(res.board.ice_at(Vector2i(3, 2)), 1, "ice elsewhere stays")
   	expect(r.ice_broken >= 1, "the result counts broken ice")
   	var clear := _first(r, Step.Type.CLEAR)
   	expect(Vector2i(1, 0) in clear.ice_broken, "the CLEAR step lists the cell")


   func test_ice_levels_validate() -> void:
   	var errors: PackedStringArray = []
   	var l := LevelData.from_dict({"colors": 5, "moves": 10, "stars": [1, 2, 3], "holes": [[0, 0]],
   		"ice": [[0, 0], [1, 1, 3]], "goals": [{"kind": "ice", "amount": 9}]}, 6, errors)
   	expect(l == null, "bad ice is an error")
   	for needle: String in ["must be on a playable cell", "layers must be 1 or 2", "more than the"]:
   		expect(Array(errors).any(func(e: String) -> bool: return e.contains(needle)), "reports: %s" % needle)
   	var s := LevelSession.new(LevelData.from_dict({"colors": 5, "moves": 10, "stars": [1, 2, 3],
   		"ice": [[2, 2, 2]], "goals": [{"kind": "ice", "amount": 2}]}, 6, errors), Game.config, 5)
   	expect_eq(s.board.ice_left(), 2, "the session puts the level's ice on the board")
   ```
10. **Document it** in `docs/levels.md`: the `ice` key (`[x, y]` or `[x, y, layers]`, layers 1–2, playable cells only) and the `ice` goal kind.

## Verify

1. Run the checks. The new checks, the level checks (every level loads and the hint bot wins it) and `test_scenes.gd` (every level opens) must pass.
2. Take `screen=level level=11 moves=3` and look: the ice shows over the tiles, two-layer cells are more opaque than one-layer cells, and the goal chip shows the ice icon and the layers left.
3. Run `tools/balance.gd -- level=11` and tell the user the win rate.
