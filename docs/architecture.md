# Architecture

## Layers

```
 input ─► BoardView ──swap_requested──► level.gd ──► LevelSession.play() ──► Resolver.swap()
                                            │                                    │ changes Board,
                                            │                                    ▼ returns Result{steps}
 screen ◄─ BoardView.play(result) ◄─────────┘ ◄──────────────────────────────────┘
           (animates each Step, emits step_started → level.gd plays sounds, Hud counts score)
```

- **`core/`: rules.** These are plain `RefCounted` classes with no nodes, so they run headless and are deterministic for a given seed.
- **`game/`: the level screen.**
  - `BoardView` knows how to draw and animate, but not the rules.
  - `level.gd` (class `LevelScreen`) connects the session, view, HUD, sounds, pause and results.
- **`ui/`: the other screens,** plus `theme.tres` (the look of buttons, panels and labels).
- **`autoload/`:**
  - `Game` holds the config, the loaded levels, saved progress (`user://progress.json`) and scene changes.
  - `Audio` plays sounds by name.

## core/

| Class | Job |
|---|---|
| `Tile` | One piece: `id` (stable, used by the view), `color` (0..n-1, or `NO_COLOR` for color bombs), and `special` (`NONE`, `LINE_H`, `LINE_V`, `BOMB`, `COLOR`). |
| `Board` | The grid: size, holes, tiles, the seeded `rng`, `fill_random()`, and `from_rows()` (builds boards from text, used by the checks). Cell `(0,0)` is the top-left. |
| `MatchFinder` | Finds 3+ runs, merges L/T shapes into groups, and decides which special a group creates and where. **The rules for creating specials are at the top of this file.** |
| `Moves` | Valid swaps, `has_any()`, and `best()` (the hint and the bot's choice). |
| `Resolver` | Applies a swap and resolves everything in one go: clears, chain reactions, special combos, falling and refilling, cascades, and a shuffle when no moves are left. **What each special does is in `_activate()` and `_resolve_combo()`.** |
| `Step` | The record of what happened, in order: `SWAP`, `SWAP_BACK`, `CLEAR` (with `cleared`, `activations`, `created`, `points`, `cascade`), `FALL` (with `falls`, including new tiles dropping in), and `SHUFFLE`. |
| `LevelData` | Loads and validates `levels/level_NN.json`, and defines the goal kinds. |
| `LevelSession` | One play of a level: moves left, score, goal progress, won or lost, stars. |
| `Balance` | A bot that plays the hint move every turn. Used by the checks and `tools/balance.gd`. |

**Important:** `Resolver.swap()` finishes the whole move, cascades included, before the view animates anything. Steps therefore carry everything the view needs (tiles, cells, points). The view never reads the live board to animate.

## game/

| File | Job |
|---|---|
| `board_view.gd` | Draws the backdrop, creates a `TileView` per tile, and turns mouse and touch into swaps (tap-tap or swipe). Replays steps with tweens, triggers `Fx`, and handles hints after a few idle seconds and screen shake. |
| `tile_view.gd` | One tile's sprite plus its special overlay, with small animations: select, hint, pop in, vanish, land. |
| `tile_skin.gd` | Which texture each tile and special uses, and each color's tint. |
| `fx.gd` | Particle bursts, rings, beams and score popups. |
| `hud.gd` / `hud.tscn` | Level name, score with the three-star bar, moves, goals. |
| `result_panel.*` | The win/lose overlay. |
| `level.gd` / `level.tscn` | The level screen, which wires everything together. `request_swap(a, b)` is the single entry point for a move. |

## Settings and credits

The title's Settings button opens `addons/codeplate/ui/settings_screen.gd` (`CodePlateSettings`): music and effects volume, fullscreen, reset progress (with a confirmation) and a Credits page built from `CREDITS.md`. It reads and sets `Game.music_volume`, `sfx_volume` and `fullscreen` through their `set_*()` functions, `save_settings()` and `reset_progress()`. `Audio` applies the volumes; they're saved with the progress in `user://progress.json`.

## Data and assets

- `config/game_config.tres` holds every tunable (see `game_config.gd` for what each one means).
- `levels/level_NN.json` holds one level each (see `docs/levels.md`).
- `assets.json` lists every asset: path, size, use, license.

## Checks

- The runner is in the CodePlate add-on: `addons/codeplate/checks/run.gd`. It finds `checks/tests/test_*.gd` plus the add-on's own `builtin/` checks, and runs every `test_*` method, which may use `await`.
- Every Godot error printed during a check fails that check.
- Base class `CheckCase` (`addons/codeplate/checks/check_case.gd`): `expect`, `expect_eq`, `frames`, `until`, `mouse_button`, `mouse_drag_to`, `action`.
- **Don't edit `addons/codeplate/`.** It's shared tooling and is replaced when the template updates.

| File | Covers |
|---|---|
| `test_match_finder.gd`, `test_resolver.gd` | The rules, on exact boards built with `Board.from_rows()` |
| `test_levels.gd` | Level files and difficulty |
| `test_scenes.gd` | Real screens: moves, simulated swipes and taps, win, lose, pause |
| `test_settings.gd` | The settings screen from the title: volumes saved, reset asks first, credits shown |
| `test_project.gd` | Skin textures, sounds, saved progress |
| add-on `builtin/` | `assets.json` against the files; every `res://` path exists |
