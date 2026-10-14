# Add a goal type

Use when a level needs a goal the three built-in kinds (`score`, `collect`, `specials`) don't cover. The example here adds **`fire`**: "set off N specials of a kind" (e.g. 3 bombs).

1. **Count it in the resolver** (`core/resolver.gd`). Add a field to `Result`:
   ```gdscript
   ## Specials that fired, per type (Tile.Special -> count).
   var specials_fired: Dictionary[int, int] = {}
   ```
   At the end of `_clear()`, just before `r.steps.append(step)`, count every activation:
   ```gdscript
   for act: Step.Activation in step.activations:
   	r.specials_fired[act.special] = r.specials_fired.get(act.special, 0) + 1
   ```
2. **Add the kind** (`core/level_data.gd`):
   - Add `FIRE` to `enum GoalKind`. Put new values at the end.
   - Give `Goal` the extra field it needs: `var special: int = Tile.Special.NONE`.
   - In `from_dict()`, add a `"fire"` case to the `match kind:` block. Read `special` from a name, to keep the JSON readable:
     ```gdscript
     "fire":
     	goal.kind = GoalKind.FIRE
     	var names := {"line": Tile.Special.LINE_H, "bomb": Tile.Special.BOMB, "color_bomb": Tile.Special.COLOR}
     	var name := str(g.get("special", ""))
     	if not names.has(name):
     		fail.call("fire goal special must be line, bomb or color_bomb")
     	goal.special = names.get(name, Tile.Special.BOMB)
     ```
     Also update the error message listing the valid kinds.
   - Lines come in two directions. Count `LINE_V` as `LINE_H` when updating progress (next step).
3. **Track progress** (`core/level_session.gd`, `play()`). Add a case:
   ```gdscript
   LevelData.GoalKind.FIRE:
   	var n: int = r.specials_fired.get(g.special, 0)
   	if g.special == Tile.Special.LINE_H:
   		n += r.specials_fired.get(Tile.Special.LINE_V, 0)
   	progress[i] += n
   ```
4. **Show it in the HUD** (`game/hud.gd`, `setup()`). Add an icon to the `match g.kind:`, e.g. `TileSkin.overlay(g.special)`. Overlays are white, so you may want a dark gem behind them, or a new icon in `assets/ui/` (list it in `assets.json`).
5. **Document it** in `docs/levels.md`, in the goals row of the table and in the example.
6. **Teach the balance bot.** In `Balance._goal_bonus()` (`core/balance.gd`), add a case that values matches that help the new goal. For `fire`, give a bonus when a group creates `goal.special`, or contains a tile with that special (it will fire). Without this, the bot ignores the goal, and `test_every_level_is_winnable_by_a_simple_bot` may fail for levels that use it.
7. **Add checks:**
   - In `checks/tests/test_resolver.gd`: a board where a bomb fires, asserting `r.specials_fired[Tile.Special.BOMB] == 1`.
   - In `checks/tests/test_levels.gd`: `from_dict` accepts `{"kind": "fire", "special": "bomb", "amount": 3}` and rejects an unknown special.
8. **Use it** in a level, then balance that level (`add-level.md`).

## Verify

1. Run the checks, including your new ones.
2. Run the balance report for the level that uses the goal.
3. Take a screenshot of that level to see the goal icon in the HUD.
