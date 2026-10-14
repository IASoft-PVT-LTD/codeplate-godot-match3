# Add or change a special

Use to change which shapes create which specials, what a special does, or to add a new one. The example adds a **CROSS**: made by a T or + shape whose longest run is 4 or more; it clears its row and column.

## Changing an existing rule only

1. **Find the rule:**
   - **Which shape makes what:** `MatchFinder._make_group()` in `core/match_finder.gd`. The rules are listed in the comment at the top of the file; keep that comment up to date.
   - **What a special does on its own:** `Resolver._activate()` in `core/resolver.gd`.
   - **What two specials do when swapped together:** `Resolver._resolve_combo()`.
2. **Change it,** then update the matching checks in `test_match_finder.gd` / `test_resolver.gd` and say so (see AGENTS.md, rule 9).

## Adding a new special

1. **Add the type.** In `core/tile.gd`, add `CROSS` at the **end** of `enum Special`, with a `##` comment saying what it does.
2. **Text boards for tests.** In `Board.from_rows()` (`core/board.gd`), map a token letter, e.g. `x`, to `Tile.Special.CROSS`. In `Board.dump()`, extend the suffix list to match.
3. **Creation rule.** In `MatchFinder._make_group()`, add the case, ordered by priority. For example, before the BOMB line:
   ```gdscript
   elif has_h and has_v and longest.cells.size() >= 4:
   	g.create = Tile.Special.CROSS
   ```
   Update the rule list in the comment at the top of the file.
4. **Effect.** In `Resolver._activate()`, add a case:
   ```gdscript
   Tile.Special.CROSS:
   	act.cells = _row(cell.y)
   	act.cells.append_array(_column(cell.x))
   ```
5. **Combos.** In `_resolve_combo()`, decide what CROSS does with each other special:
   - With a color bomb, the existing code already turns every tile of the partner's color into the partner's special.
   - For two non-color specials, the code counts lines with `Tile.is_line()`. Either treat CROSS as two lines, or add an explicit branch.
6. **Art.** Create the overlay `assets/specials/cross.png`: a mostly transparent PNG the same size as the other overlays (96×96), white so it shows on every color. List it in `assets.json`. Then map it in `TileSkin.OVERLAY_PATHS` (`game/tile_skin.gd`).
7. **Effects.** In `BoardView._activation_fx()` (`game/board_view.gd`), add a case. For a cross, draw two beams (copy the LINE_H and LINE_V cases) and call `shake(config.shake_line)`.
8. **Sound.** In `level.gd` `_on_step_started()`, map `Tile.Special.CROSS` to a sound, e.g. `&"line"`, or add a new one (`replace-sounds-and-music.md`).
9. **Checks.**
   - In `test_match_finder.gd`: a T shape with a 4-long arm creates CROSS.
   - In `test_resolver.gd`: a CROSS cleared by a match clears its row and column. Build the board with the `x` token, e.g. `"0 0x 0 1"`.
   - Run `test_random_play_keeps_invariants` too; it catches broken boards.
10. **Re-import** (new class contents and a new asset): `godot --headless --path . --import`.

## Verify

1. Run the checks.
2. Take a screenshot mid-effect: `screen=level level=3 moves=4 action=0.2 wait=0`. Specials come up naturally after a few moves; try a few seeds (`seed=`) to catch one.
3. Run the balance report. New specials usually make levels easier.
