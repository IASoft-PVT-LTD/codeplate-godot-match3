# Rebrand: name, icon, colors, fonts

Use when the user names their game and wants it to look like theirs.

1. **Name.** Set `config/name` in `project.godot`. The title screen shows it in upper case (`ui/title.gd`). The window title uses it too. Set `package/name` in the Android preset of `export_presets.cfg` to the same text (it's the name under the launcher icon; a check fails when the two differ). The save folder is `config/custom_user_dir_name` (it ships as `match-3`): set it to a slug of the new name now if nobody has played yet, and never change it once players have saves.
2. **Tagline.** Change the `Tagline` label text in `ui/title.tscn`.
3. **Icon.** Replace `assets/ui/icon.png` with a 256×256 or larger square PNG, and update its size in `assets.json`. `project.godot` `config/icon` already points to it.
4. **Background.** Any picture works: PNG, JPEG or WebP. Copy it into `assets/bg/`, list it in `assets.json`, and set `background_path` in `config/game_config.tres` to it (no scene edit). It's scaled to cover any screen shape. Designed for 720×1280 portrait; a landscape game wants a wide picture (`change-screen-shape.md`).
5. **Theme colors.** `ui/theme.tres` is a text file:
   - The `StyleBoxFlat` blocks hold `bg_color` and `border_color` for buttons (`button_normal`, `button_hover`, `button_pressed`, `button_disabled`), the `panel`, and the HUD `chip`s.
   - The `[resource]` section holds font colors and sizes.
   - Variations: `HeaderLabel` (big titles), `SmallLabel` (captions), `IconButton` (round icon buttons), `Chip` (HUD panels).

   Change the colors together, so the palette stays consistent.
6. **Board colors.** `cell_color_a`, `cell_color_b` and `frame_color` are `@export` values at the top of `game/board_view.gd`.
7. **Splash and clear color.** In `project.godot`: `boot_splash/bg_color` and `environment/defaults/default_clear_color`.
8. **Font.**
   - The font must be the user's own, SIL OFL or CC0.
   - Put the `.ttf` or `.otf` in `assets/fonts/`, and list it in `assets.json` with kind `font`.
   - Note the license in `CREDITS.md`; OFL fonts require their license text to ship, so copy `OFL.txt` next to the font.
   - Add the font to `ui/theme.tres` as an external resource, and set it as the default font:
     ```
     [ext_resource type="FontFile" path="res://assets/fonts/MyFont.ttf" id="font_1"]
     ...
     [resource]
     default_font = ExtResource("font_1")
     ```
   - Check that text still fits: headers and the moves counter are large.
9. **Re-import:** `godot --headless --path . --import`.

## Verify

1. Run the checks.
2. Take screenshots of `title`, `settings`, `credits`, `levels` and `level` with `moves=3` (the settings screen takes its look from `ui/theme.tres`). Look for:
   - readable contrast
   - text that fits its boxes
   - a consistent palette
3. Record the brand decisions in `docs/project.md`.
