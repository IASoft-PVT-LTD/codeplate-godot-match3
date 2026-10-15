# Customization map

"I want to change X." Here is where to go. If a recipe exists, follow it.

| I want to… | Change | Recipe |
|---|---|---|
| Use my own tile art | `assets/tiles/gem_N.png`, `assets.json` | `recipes/reskin-tiles.md` |
| Change special overlays or the color bomb look | `assets/specials/*.png` | `recipes/reskin-tiles.md` |
| Change the background | `assets/bg/background.png` (720×1280) | — |
| Add a tile color | gem texture, `tile_tints`, `max_colors` | `recipes/add-tile-color.md` |
| Change board size, shape or holes | `levels/level_NN.json` (`width`, `height`, `holes`) | `recipes/add-level.md` |
| Add, remove or reorder levels | `levels/` | `recipes/add-level.md` |
| Change moves, goals or stars of a level | `levels/level_NN.json` | `recipes/add-level.md` |
| Make levels easier or harder | `levels/*.json`, then `tools/balance.gd` | `recipes/add-level.md` |
| Add a new goal kind | `core/level_data.gd`, `core/level_session.gd`, `game/hud.gd` | `recipes/add-goal-type.md` |
| Change what makes a special (e.g. 4 makes a bomb) | top of `core/match_finder.gd` (`_make_group`) | `recipes/add-special.md` |
| Change what a special does | `core/resolver.gd` (`_activate`, `_resolve_combo`) | `recipes/add-special.md` |
| Add a new special | several files | `recipes/add-special.md` |
| Change bomb size | `bomb_radius` in `config/game_config.tres` | — |
| Change points, cascade multiplier, bonuses | `config/game_config.tres` (Scoring group) | `recipes/change-scoring.md` |
| Make the game faster or slower; tune animations | `config/game_config.tres` (Animation group) | `recipes/tune-game-feel.md` |
| More or less shake or particles | `config/game_config.tres` (Feel group) | `recipes/tune-game-feel.md` |
| Change the hint delay or swipe sensitivity | `hint_delay`, `swipe_threshold` in config | — |
| Replace sounds or the music | `assets/audio/`, `autoload/audio.gd` | `recipes/replace-sounds-and-music.md` |
| Obstacles on the board (ice) | `core/board.gd`, `core/resolver.gd`, `levels/*.json` | `recipes/add-blocker.md` |
| Boosters (hammer, shuffle, +moves) | `core/resolver.gd`, `core/level_session.gd`, `game/level.gd` | `recipes/add-booster.md` |
| Rename the game, change the icon | `project.godot`, `assets/ui/icon.png` | `recipes/rebrand.md` |
| Change button, panel and font styles | `ui/theme.tres` | `recipes/rebrand.md` |
| Change board colors (cells, frame) | `@export` colors at the top of `game/board_view.gd` | `recipes/rebrand.md` |
| Change the title screen | `ui/title.tscn`, `ui/title.gd` | `recipes/rebrand.md` |
| Change the HUD layout | `game/hud.tscn`, `game/hud.gd` | — |
| Change the win/lose panel | `game/result_panel.tscn`, `.gd` | — |
| Change level unlock rules | `Game.is_unlocked()` in `autoload/game.gd` | — |
| Change how the score turns into stars | `LevelSession.stars()` in `core/level_session.gd` | `recipes/change-scoring.md` |
| Add a shop or world-map screen | `ui/`, `autoload/game.gd` | `recipes/add-screen.md` |
| Music and effects volume, fullscreen, credits | `CREDITS.md`; settings in `autoload/game.gd` (the screen itself is in `addons/codeplate/ui/`) | `recipes/add-screen.md` |
| Change screen size or orientation | `project.godot` `[display]` (keep `canvas_items` stretch) | — |
| Build for desktop, web or mobile | export presets | `recipes/export.md` |
| Export for Android (package name, icons, version, debug APK) | `export_presets.cfg`, `assets/launcher/*.png` | `recipes/export-android.md` |
