# Add a tile color

Use when the game needs more than 6 tile colors.

1. **Add the texture** `assets/tiles/gem_6.png`: square PNG, transparent background. Make its shape different from the others too, not just its color; players with color blindness rely on shapes.
2. **Add it to `assets.json`** with its real `width` and `height`, plus `use`, `license` and `credit`.
3. **In `config/game_config.tres`:**
   - set `max_colors = 7`
   - append a seventh color to `tile_tints`

   `tile_tints` is a flat list of RGBA floats, 4 numbers per color. Append the new color's 4 values.
4. **Optional: use it in levels.** Levels use colors `0 .. colors-1`, so set `"colors": 7` in a level to include the new one.
5. **Update the color table** in `docs/levels.md`.
6. **Re-import:** `godot --headless --path . --import`.

Notes:
- More colors means fewer natural matches, so levels get harder. Re-balance any level you raise to 7 colors.
- The title screen shows one gem per color (`max_colors`). Seven still fit at 720 px wide; past 8, reduce the gem size in `ui/title.gd`.

## Verify

1. Run the checks. `test_skin_has_a_gem_and_tint_per_color` confirms the texture and the tint exist.
2. If levels changed, run the balance report.
3. Take a screenshot of `screen=title` and look at it.
