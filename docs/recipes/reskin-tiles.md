# Reskin the tiles

Use when the user wants their own art for the gems, the specials or the color bomb.

## What the art needs

- **One image per tile color.** Each one is square, PNG, with a transparent background.
  - Any size works. Tiles are scaled to `cell_size × tile_fill` (80 × 0.92 px by default).
  - 96–256 px is plenty.
- **Overlays for specials.**
  - `line_h.png`, `line_v.png` and `bomb.png` are drawn **on top of** a gem, so they need mostly transparent pixels (glows, stripes, rings).
  - `color_bomb.png` is a full tile on its own.

## Steps

1. **Look at what the user gave you.** List the files and check each one's size and transparency. You can read PNG sizes with any image tool, or open the files.
   - If they sent a sprite sheet, cut it into separate PNGs first, with a short script (Python Pillow, or Godot `Image.get_region()`).
   - If an image has a solid background, ask whether to remove it, or remove it if the background is a flat color.
2. **Decide the color order.** Color `n` uses `assets/tiles/gem_<n>.png`. Keep the existing file names: replacing the files is the simplest path.
   - If the user's set has more colors than `max_colors`, also follow `add-tile-color.md`.
   - If it has fewer, lower `colors` in levels that use more, or keep some placeholders.
3. **Copy the new PNGs over** `assets/tiles/gem_0.png` … (and `assets/specials/*.png` if replaced).
4. **Update `assets.json`** for every replaced file:
   - `width` and `height`: the real pixel size
   - `use`: describe the new tile, e.g. "Tile color 0: strawberry"
   - `license` and `credit`: where the art comes from (rule 8 in `AGENTS.md`). Ask the user if you don't know. Examples:
     - `"license": "<game or team name>", "credit": "<user's name or studio>"` for the user's own art (they own it)
     - `"license": "CC0-1.0", "credit": "<author>"` with `"source": "<url>"` for public-domain art
   - Add a line for the new art to `CREDITS.md` under "Art and sound"; players see it on the Credits page.
5. **Update `tile_tints`** in `config/game_config.tres` so each color's tint matches its new tile. Tints color the particle bursts and some UI. Pick the dominant color of each tile.
6. **Update the color table** in `docs/levels.md` (color number → tile name).
7. **Pixel art?** Make it crisp: add this under `[rendering]` in `project.godot`:
   ```
   textures/canvas_textures/default_texture_filter=0
   ```
8. **Re-import:** `godot --headless --path . --import`.

## A new background?

1. **Add the picture** to `assets/bg/` (PNG, JPEG or WebP, scaled to cover the screen; 720×1280 suits portrait) and list it in `assets.json`. Set `background_path` in `config/game_config.tres` to its path. No scene edit, and no need to convert a JPEG.
2. **Check contrast.** The UI was designed on a dark background. If the new one is light or busy, look at the screenshots, especially the title tagline, the HUD and the level-select header.
3. **Adjust** if needed:
   - `ui/theme.tres`: `font_color` and `font_outline_color` / `outline_size` for `Label` and `SmallLabel`, and the `chip` and `panel` `bg_color`
   - `frame_color` and the cell colors at the top of `game/board_view.gd`

## Verify

1. Run the checks. `test_project.gd` confirms every file exists and matches `assets.json`.
2. Take screenshots: `screen=title` (shows all gems), and `screen=level level=1 moves=2`. Look at them:
   - Are the tiles easy to tell apart at board size?
   - Are the specials visible on every tile color?
   - Is all text readable against the new background?
3. Record the change in `docs/project.md`.
