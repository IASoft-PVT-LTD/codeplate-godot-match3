# Add a screen

Use for a shop, daily-challenge, world map or any other new screen. Settings and credits already exist: they're the shared CodePlate screen (title screen > Settings), described at the end.

1. **Create the scene** `ui/<name>.tscn` with its script `ui/<name>.gd`. Copy the structure of `ui/level_select.tscn`:
   - a full-rect `Control` root
   - an instance of `ui/background.tscn`
   - a `MarginContainer` holding a `VBoxContainer`
   - a header row with a back `IconButton` (`assets/ui/back.png`)

   Mark the nodes the script needs as unique names (`unique_name_in_owner = true`) and reach them with `%Name`.
2. **Navigation.** In `autoload/game.gd`:
   - add a constant, e.g. `const SCENE_SETTINGS := "res://ui/settings.tscn"`
   - add a function `goto_settings()` that calls `get_tree().change_scene_to_file(SCENE_SETTINGS)`
3. **A way in.** Add a button on the title screen (`ui/title.tscn` / `title.gd`) or in the pause menu. Play `Audio.play(&"click")` on press, like the existing buttons.
4. **A way out.** The back button and the `pause` action (Esc) should go back, as in `ui/level_select.gd`.
5. **State.** Anything the screen saves goes through `Game`:
   - add fields to `save_progress()` and `load_progress()`
   - keep old saves loading: read new keys with `data.get(key, default)`
6. **Layout.** Use containers, not fixed positions, so the screen works on tall and wide displays (the project uses `canvas_items` stretch with `expand` aspect).
7. **Add a check** to `checks/tests/test_scenes.gd`, like `test_title_screen`: instantiate the scene, add it to `tree.root`, wait a few frames, and assert its key nodes are visible.

## Settings and credits

**To add a setting** (a toggle, a slider, a choice), build the control and hand it to `add_row` on the screen `CodePlateSettings.open()` returns: `settings.add_row(control)` puts it above Credits, `add_row(control, &"ResetButton")` above the control you name. Don't reparent the screen's own nodes. Keep the value in `Game` and save it in `save_progress()`.

The title screen's Settings button opens `addons/codeplate/ui/settings_screen.gd` (`CodePlateSettings.open(self)` in `ui/title.gd`): music and sound-effect volume, fullscreen, reset progress (it asks first) and a Credits page that shows `CREDITS.md`.

- **Don't edit the add-on;** it's replaced when the template updates. Change its look through `ui/theme.tres`.
- **Settings it reads and writes** live in `autoload/game.gd`: `music_volume`, `sfx_volume`, `fullscreen`, their `set_*` functions, `save_settings()` and `reset_progress()`. Remove a setter and its control disappears. Saved with the progress in `user://progress.json`.
- **To add a setting of your own** (say, "show hints"), add a row to a screen of yours rather than to the add-on, and save it through `Game` like the others.
- **Credits** are the lines of `CREDITS.md`. HTML comments (`<!-- -->`) are hidden; use them for notes.

## Verify

1. Run the checks.
2. Take a screenshot. Add your screen to `SCREENS` in `tools/screenshot_hooks.gd`, then run `godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=<name>`. Or skip the hook and pass `scene=res://ui/<name>.tscn`.
