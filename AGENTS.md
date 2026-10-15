# Godot Match 3: agent brief

You are building a game for the user, starting from this template. This brief tells you how the project works, what to ask before changing anything, the rules that keep it working, and how to check every change. Read it all once. Then follow **Interview** before your first edit.

## Start here

This folder is a complete match-3 puzzle game in **Godot 4.7** (GDScript only, portrait 720×1280, mouse and touch):

- **Board:** swap, match, cascade.
- **Specials:**
  - 4 in a row makes a line clearer.
  - An L or T shape makes a bomb.
  - 5 in a row makes a color bomb.
  - Swapping two specials together triggers a bigger combo.
- **Levels:** 10 levels with goals (score, collect a color, create specials), limited moves and a 1–3 star rating. Progress is saved.
- **Screens:** title, settings and credits (music and effects volume, fullscreen, reset progress, the credits page), level select, HUD, pause menu, and a win/lose panel.
- **Feel:** animations, particles, screen shake, sound effects and a looping music track.

**Verify any change** by running both commands from this folder. Both must pass, and the second must end with `CODEPLATE CHECKS: PASS`:

```
godot --headless --path . --import
godot --headless --path . --script res://addons/codeplate/checks/run.gd
```

**Finding Godot.** `godot` in this brief stands for a Godot **4.7.x** binary. Find one in this order and use the first that works:

1. **The `GODOT` environment variable.** CodePlate's own tools use it, so it's often set already: `echo $GODOT` (bash/zsh) or `echo $env:GODOT` (PowerShell).
2. **PATH:** `where godot*` (Windows cmd), `Get-Command godot*` (PowerShell), `which godot godot4` (macOS/Linux).
3. **Typical install paths:**
   - **Windows:** `C:\Program Files\Godot\`, `%LOCALAPPDATA%\Programs\Godot\`, `%USERPROFILE%\scoop\apps\godot\current\`, Steam's `steamapps\common\Godot Engine\`, or a folder like `C:\Godot\`. Use the `Godot_v4.7.x-stable_win64_console.exe` build that sits next to the plain `.exe`: only the console build prints output to your terminal.
   - **macOS:** `/Applications/Godot.app/Contents/MacOS/Godot` (or under `~/Applications/`). Homebrew (`brew install --cask godot`) puts `godot` on PATH.
   - **Linux:** `~/.local/bin/`, `/usr/local/bin/` or `/usr/bin/` (`godot`, `godot4`), the downloaded `Godot_v4.7.x-stable_linux.x86_64`, Flatpak (`flatpak run org.godotengine.Godot`) or Snap (`/snap/bin/godot-4`).
4. **Check the version:** `<binary> --version` must start with `4.7`. Don't use Godot 3.x or another 4.x minor version.
5. **None found?** Ask the user to install Godot 4.7 from godotengine.org and tell you the path.

Once you've found it, write the path in `docs/project.md` so later sessions don't search again.

## Interview

Before you change anything, read `docs/project.md`.

- **If it still contains `<!-- codeplate:project-stub -->`, interview the user first.** Ask only what you need, in one short message, and suggest defaults so they can just say "yes":
  1. **Concept and theme.** What is the game about? A name? Example: "candy shop", "space gems", "ocean pets".
  2. **Assets.** Do they have art or sounds? Where are the files? If none, keep the placeholders, which are free to ship.
  3. **Rule changes.** Board size, number of colors, specials, goals, moves, scoring. Any new mechanics?
  4. **Levels.** How many, and how hard should the ramp be?
  5. **Platforms.** Desktop, web, mobile? This only matters at export time.
  6. **Must-keep / must-change.** Anything they love or dislike about the template as it stands?

  Then replace the stub in `docs/project.md` with their answers as short decisions, and remove the marker.
- **Otherwise, the project has started.** `docs/project.md` holds the decisions made so far. Follow them, and add new decisions as the user makes them. This file is how the next session knows what was agreed.

Work in small steps. Make one change, verify it, show the result (see **Seeing your work**), then continue.

`README.md` and `codeplate.json` describe the template. Once the user has named their game, rewrite `README.md` for their game (what it is, how to run it), and leave `codeplate.json`, `LICENSE.md` and `CREDITS.md` in place. `LICENSE.md` explains the user's rights to the template code; `CREDITS.md` is where credits for added assets go.

## Architecture

The rules and the visuals are strictly separate. See `docs/architecture.md` for details and data flow.

| Folder | What lives there |
|---|---|
| `core/` | **Pure game logic, no nodes:** `Board`, `Tile`, `MatchFinder`, `Moves`, `Resolver`, `Step`, `LevelData`, `LevelSession`, `Balance`. Same seed and same swaps give the same result. |
| `game/` | **The level screen:** `BoardView` (draws tiles, reads input, replays `Step`s as animations), `TileView`, `Fx`, `Hud`, `ResultPanel`, `TileSkin` (texture lookup), `level.gd` (wires everything together). |
| `ui/` | Title, level select, pause menu, shared background, `theme.tres`. The title's Settings button opens the shared settings + credits screen from `addons/codeplate/`. |
| `autoload/` | `Game` (config, level list, saved progress and settings, scene changes) and `Audio` (sound effects and music by name, at the player's volumes). |
| `config/game_config.tres` | **Every tunable number:** timings, scoring, shake, particles, tile tints. |
| `levels/level_NN.json` | One file per level. Format in `docs/levels.md`. |
| `assets/` + `assets.json` | Art and sounds; `assets.json` lists every file with its size and purpose. |
| `checks/tests/` | This game's checks. |
| `addons/codeplate/` | Shared CodePlate tooling: the check runner, `CheckCase`, project-wide checks, the screenshot tool, the settings + credits screen. **Don't edit it.** It's replaced when the template updates. |
| `tools/` | `balance.gd` (level difficulty report) and `screenshot_hooks.gd` (the screens the screenshot tool knows). |

How one move works:

1. `BoardView` turns a tap or swipe into `swap_requested(a, b)`.
2. `level.gd` calls `LevelSession.play()`, which calls `Resolver.swap()`.
3. The resolver updates the board **completely** and returns a list of `Step`s: SWAP, CLEAR, FALL and so on.
4. `BoardView.play()` animates those steps in order. `level.gd` plays sounds and updates the HUD on each step.

## Rules

1. **Keep the rules in `core/` and the visuals in `game/` and `ui/`.** `core/` must never touch nodes, scenes, textures, sound or `Game`. Matching, specials, scoring and goals are tested headless, and that depends on this separation.
2. **Gameplay and feel numbers go in `config/game_config.gd` and `config/game_config.tres`, not in code.** Add a new tunable as an `@export` with a default, and give it the same value in the `.tres`.
3. **Levels are data.** Change `levels/*.json`, not code. Keep the files numbered `level_01.json`, `level_02.json` … with no gaps.
4. **Every file under `assets/` is listed in `assets.json`,** with its real pixel size. When you add, replace or remove an asset, update `assets.json` in the same step. Godot's `*.import` and `*.uid` files sit next to assets and scripts; they belong to the project but aren't listed.
5. **Moving or renaming a script or asset?** Move its `.uid` / `.import` file with it, update every `res://` path that points to it, then rerun the import command. A check fails if any `res://` path in code or scenes doesn't exist.
6. **Use static types in GDScript:**
   - Type every variable, parameter and return value (`var x: int`, `-> void`).
   - Keep scenes as text (`.tscn` / `.tres`).
   - No C#.
7. **Don't name a class after a Godot built-in.** For example `Skin`, `Theme` and `Timer` already exist; that is why the texture lookup is called `TileSkin`.
8. **Keep the template's licensing clean.** Use only assets the user provides, assets that are the user's own, or CC0 assets. Record each new asset's `license` and `credit` in `assets.json` (use the user's name for their own assets). Don't paste code from tutorials or other projects; write it here. `CodePlate-original` marks only the template's own placeholders. For art or sound you make for the user, put their game or team name in `license` and `credit` (they own it), and say in `use` that it's a generated placeholder.
9. **Never weaken a check to make it pass.** If a check fails, fix the cause. If the user deliberately changed a rule that a check tests (say, 4 in a row now makes a bomb), update that check to the new rule and say so.
10. **Checks don't match the words on screen.** Find buttons and labels by node name, or compare with the constant the screen uses (`ResultPanel.LOSE_TITLE`), so rewording or translating a text breaks no check. Write new checks the same way.
11. **Add checks for new rules.** When you add a mechanic in `core/`, add a check in `checks/tests/`. `Board.from_rows()` builds exact boards for this; copy the style of `test_resolver.gd`.
12. **Keep the CodePlate credit.** This template's free license (`LICENSE.md`) asks that anything the user shares shows "Built with CodePlate (codeplate.io)" where people can see it. It's the first line of `CREDITS.md`, which players see on title > Settings > Credits, and a check fails if it goes missing. Keep it when you rebrand. The credit is only optional if `LICENSE.md` is the **CodePlate Pro License**: a copy downloaded with an active CodePlate paid plan comes with it, and names its license ID in `CODEPLATE-LICENSE.txt`. If the user asks to remove the credit and `LICENSE.md` is still the free license, tell them that.

## Verify

After every change:

1. **Run the two check commands** (see **Start here**). The second must end with `CODEPLATE CHECKS: PASS`.
   - Each failure prints the check's name and message.
   - Any Godot error printed during a check also fails it, so read the error lines.
   - To rerun only some checks: `godot --headless --path . --script res://addons/codeplate/checks/run.gd -- resolver`. The filter matches `file:method` names.
2. **Look at it.** For anything visible, take a screenshot and open the PNG to look at it (see **Seeing your work**). Taking it isn't enough. Check that:
   - the board fits
   - every piece of text is readable against its background
   - nothing overlaps or is cut off
3. **Changed levels or scoring?** Run the balance report and check the win rates (see `docs/levels.md`):
   ```
   godot --headless --path . --script res://tools/balance.gd
   ```
4. **Tell the user** what changed, show the screenshot, and suggest they play it (`godot --path .`).

The checks cover:
- matching, specials, combos, cascades and shuffles
- every level loads, generates playable boards and can be won by the hint bot
- every screen opens (settings and credits too, with the credit line shown), and real taps and swipes play moves through the level scene
- `assets.json` matches the files
- every `res://` path exists
- progress saves and loads

## Recipes

Step-by-step guides for common requests. Follow the matching recipe when one fits; each ends with its own verification.

- `docs/recipes/reskin-tiles.md`: replace the gem art with the user's own tiles.
- `docs/recipes/add-tile-color.md`: add a 7th (or later) tile color.
- `docs/recipes/add-level.md`: add or edit levels, holes and goals, then balance them.
- `docs/recipes/add-goal-type.md`: a new kind of level goal (e.g. "fire 5 bombs").
- `docs/recipes/add-special.md`: a new special tile and how it's created and fired.
- `docs/recipes/add-blocker.md`: ice over cells that breaks when matched, and an "ice" goal.
- `docs/recipes/add-booster.md`: in-level boosters such as a hammer that smashes one tile without using a move.
- `docs/recipes/change-scoring.md`: points, cascade multiplier, bonuses, star thresholds.
- `docs/recipes/tune-game-feel.md`: speed, animation, shake, particles, sound pitch.
- `docs/recipes/replace-sounds-and-music.md`: swap sound effects; add background music.
- `docs/recipes/rebrand.md`: game name (and the Android package name), icon, title screen, background, colors and fonts.
- `docs/recipes/add-language.md`: another language and a language picker (`game/strings.gd`).
- `docs/recipes/change-screen-shape.md`: landscape instead of portrait (`layout` in the config).
- `docs/recipes/add-screen.md`: a new screen (shop, world map …) and how to navigate to it; how the built-in settings and credits screen works. **To add a setting, use `add_row(control)`** on the settings screen; never reparent its nodes.
- `docs/recipes/export.md`: build for Windows, macOS, Linux, web or Android.
- `docs/recipes/export-android.md`: export a debug APK for a phone or emulator (the preset is included); package name, icons, and what a Play release needs.

**Credits** live in `CREDITS.md`, shown on title > Settings > Credits (the shared screen in `addons/codeplate/ui/`). Keep its first line, "Built with CodePlate (codeplate.io)", and add a line for every asset the user brings in.

`docs/customization-map.md` answers "I want to change X — which file?" for everything else.

## Seeing your work

You can't watch the game run, but you can screenshot it. The screenshot tool needs a real window, so **don't** pass `--headless`:

```
godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=3 moves=2
godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=3 moves=2 action=0.25 wait=0 out=res://shots/action.png
godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=title
godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=settings
```

The PNG goes to `shots/` (git-ignored), and the tool prints its path. Open it and look.
- `screen` is `title`, `settings`, `credits`, `levels` or `level`.
- `action=0.25` captures 0.25 s into a move, so you can see effects mid-animation.
- If no display is available (CI, a remote shell), say so and rely on the checks.

## Common pitfalls

- **"Identifier not found" for a class you just added or renamed:** run `godot --headless --path . --import` again. It rebuilds Godot's class cache.
- **A `--script` entry file (`tools/*.gd`, the screenshot hooks) can't name classes whose code uses the `Game` or `Audio` autoloads.** Those scripts compile before the autoloads exist. Use `node.get("…")` and `node.call("…")`, as `tools/screenshot_hooks.gd` does.
- **Controls stop board input.** Any full-screen `Control` above the board needs `mouse_filter = 2` (ignore), or taps never reach `BoardView`.
- **The resolver works ahead of the animation.** When `BoardView` plays a step, the board already shows the final state. Animate from the data in the `Step`, never by reading the board.
