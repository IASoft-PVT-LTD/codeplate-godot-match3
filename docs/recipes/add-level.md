# Add or edit levels

Use for new levels, changed goals or moves, board shapes and holes, and difficulty tuning. The format is in `docs/levels.md`.

1. **Create the file.**
   - For a new level: copy the last file, e.g. `levels/level_10.json` to `levels/level_11.json`. The number must be the next one, with no gaps.
   - To insert a level between two others, rename the later files up by one.
2. **Set the shape:** `width`, `height` and `holes`.
   - Holes make shapes. Keep at least 3 playable cells in a row in most rows and columns, or matches become rare.
   - To draw a shape quickly, sketch it as rows of `.` and `#` and convert the `#`s to `[x, y]`.
3. **Set the challenge:** `colors`, `moves` and `goals`.
   - Collect goals need a `color` below `colors`.
   - Mix goal kinds for variety.
4. **Set provisional `stars`** (any three ascending numbers). You'll replace them in step 6.
5. **Run the balance report** for this level:
   ```
   godot --headless --path . --script res://tools/balance.gd -- level=11 runs=60
   ```
   Adjust `moves`, goal amounts or `colors` until the win rate fits where the level sits in the difficulty ramp (see `docs/levels.md`).
6. **Copy the "suggested stars"** from the report into `stars`.
7. **Unlocking.** The level select grid picks up new files automatically. Each level unlocks when the previous one has a star.

## Verify

1. Run the checks. `test_levels.gd` validates every file, checks the numbering, generates boards with 20 seeds, and has the bot try to win.
2. Take a screenshot of the new level: `screen=level level=11`. Look at it:
   - Does the board fit?
   - Is the shape as intended?
   - Is the HUD readable with all the goals?
3. Note the level in `docs/project.md`.
