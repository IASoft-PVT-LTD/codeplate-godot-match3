# Change scoring and stars

Use for points per tile, the cascade multiplier, special and leftover-move bonuses, or how stars are awarded.

1. **The numbers** are in the Scoring group of `config/game_config.tres`. Their meanings are in `config/game_config.gd`:
   - `points_per_tile`: per cleared tile
   - `cascade_multiplier_step`: each cascade adds this to the multiplier (0.5 gives ×1, ×1.5, ×2 …)
   - `special_create_bonus`: per special created
   - `points_per_move_left`: bonus per unused move on a win
2. **The formula** is at the end of `Resolver._clear()` (`core/resolver.gd`). Change it there if the user wants a different system, e.g. bigger bonuses for long matches.
3. **Stars** are in `LevelSession.stars()` (`core/level_session.gd`): it counts the thresholds in each level's `stars` that the score reached, and a win always gives at least 1 star.
4. **Rebalance every level after a scoring change.** Scores shift, so the old star thresholds and `score` goals no longer fit.
   - Run `godot --headless --path . --script res://tools/balance.gd -- runs=60`.
   - Update each level's `stars` from "suggested stars".
   - Re-check `score` goals against the new averages.
5. **Update checks.** If you changed the formula, update `test_cascade_multiplier` in `checks/tests/test_resolver.gd` to the new expected numbers.

## Verify

1. Run the checks. `test_every_level_is_winnable_by_a_simple_bot` catches score goals that are now out of reach.
2. Compare the balance report before and after the change.
3. Take a screenshot mid-move (`action=0.2 wait=0`) to see the score popups.
