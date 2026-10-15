# Change the screen shape (portrait or landscape)

Use when the game should be played on a wide screen (a desktop or web page, or a landscape phone) instead of the tall portrait phone shape.

The game is portrait by default: 720×1280, the HUD above the board. A `layout` value in `config/game_config.tres` switches to landscape: the HUD becomes a panel on the right (score, stars, moves, goals, the pause button and the booster slot), the board fills the rest of the height, level select shows as many columns as the width allows, and the result panel's buttons sit in a row.

1. **Ask:** landscape only, or both? This recipe makes the game landscape. A game that must work in both orientations needs the layout picked at run time from the window's shape; tell the user that is a bigger change.
2. **Set the layout:** `layout = "landscape"` in `config/game_config.tres`.
3. **Set the window** in `project.godot` (`[display]`):
   - `window/size/viewport_width=1280` and `window/size/viewport_height=720`;
   - `window/size/window_width_override` and `window_height_override` for the size the desktop window opens at (for example 1280 and 720);
   - `window/handheld/orientation=0` (landscape) for phones.
4. **Check the art:** the background is scaled to cover any shape (`background_path` in the config). A picture drawn for portrait gets cropped; look at it, or swap it (`rebrand.md`).
5. **Screenshots in the new shape:** add `layout=landscape size=1280x720` to any screenshot command. Without `size=` the tool uses the project's viewport size:
   ```
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=3 moves=2 layout=landscape size=1280x720
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=1 result=won layout=landscape size=1280x720
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=levels layout=landscape size=1280x720
   ```
6. **Look for:** the board and the side panel don't overlap, the board is as tall as the view allows, the pause button and any booster buttons are on screen, and the title's Play and Settings buttons are visible.
7. **Boosters** added by `add-booster.md` put their buttons in `BottomBar/Row`; in landscape that bar moves to the bottom of the side panel. Look at it with a booster on.

## Where it lives

- `game/level.gd`: `board_area()` is the rectangle the board is fitted into; `_use_landscape()` moves the bottom bar and the result buttons.
- `game/hud.gd` `use_side_panel()`: the HUD as a column.
- `ui/level_select.gd` `_fit_columns()`: columns from the view width.
- `ui/title.gd`: tighter spacing so the buttons fit 720 px of height.

## Verify

1. Run the checks. `test_landscape_layout_fits_1280x720` opens every level at 1280×720 with `layout = landscape` and fails if the board and HUD overlap or leave the view, or if the board is under 85% of the view's height. If you chose another size, change the numbers in that check and say so.
2. Show the user the landscape screenshots.
