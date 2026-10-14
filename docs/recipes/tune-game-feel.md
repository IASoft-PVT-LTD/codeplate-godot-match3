# Tune game feel

Use when the user says it feels slow, floaty, too busy, too quiet, not punchy enough, and so on.

1. **Find the feeling in the table below.** Ask the user which moment feels wrong if they're vague (swaps, clears, falls, specials).
2. **Change the number** in `config/game_config.tres`, in small steps (about 20% at a time). Each one is explained in `config/game_config.gd`.
3. **Still wrong? Change the animation code** listed after the table.
4. **Run the checks and take mid-move screenshots** (see **Verify**), then ask the user to play.

| Feels… | Change |
|---|---|
| Slow overall | Raise `animation_speed`. It multiplies every animation's speed (1.5 = 50% faster). |
| Swaps sluggish | Lower `swap_time` (0.12–0.2 feels good). |
| Clears too quick to read | Raise `clear_time`, or `cascade_pause` (the gap between cascades). |
| Falling feels floaty | Lower `fall_time_per_cell` and `fall_min_time`. |
| Shake too strong or weak | `shake_line`, `shake_bomb`, `shake_color` (pixels); `shake_decay` (higher = shorter). |
| Particles too busy or sparse | `particles_per_tile`. |
| Cascades sound flat | Raise `pitch_per_cascade`. |
| Hints too eager | Raise `hint_delay` (seconds). |
| Swipes trigger too easily | Raise `swipe_threshold` (fraction of a cell). |

The animations themselves are in code (step 3):
- **`game/tile_view.gd`:** `vanish()` (clear), `pop_in()` (new special), `land()` (squash after falling), `set_selected()`, `set_hint()`. Change scale amounts or the `Tween.TRANS_*` / `EASE_*` curves.
- **`game/fx.gd`:** particle velocity, gravity and lifetime in `burst()`; ring, beam and popup styles.
- **`game/board_view.gd`:** how each step type is animated (`_animate_swap`, `_animate_clear`, `_animate_fall`, `_animate_shuffle`), and the effects per special (`_activation_fx`).

The checks run with `animation_speed = 200`, so feel changes don't slow them down.

## Verify

1. Run the checks.
2. Take mid-move screenshots at a few moments of the same move:
   ```
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=2 moves=3 action=0.05 wait=0 out=res://shots/a.png
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=2 moves=3 action=0.2 wait=0 out=res://shots/b.png
   ```
   The same `seed` and `moves` give the same move, so the frames line up.
3. Ask the user to play (`godot --path .`); feel is best judged by hand. Note their reaction in `docs/project.md`.
