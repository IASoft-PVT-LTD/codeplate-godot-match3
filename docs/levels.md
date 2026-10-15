# Level format

There is one JSON file per level in `levels/`, named `level_01.json`, `level_02.json`, and so on. Files play in name order, and the number in the name is the level number. Keep the numbers without gaps.

```json
{
  "title": "Corners",
  "width": 8,
  "height": 8,
  "colors": 5,
  "moves": 22,
  "holes": [[0, 0], [7, 0], [0, 7], [7, 7]],
  "goals": [
    { "kind": "score", "amount": 2200 },
    { "kind": "collect", "color": 0, "amount": 20 },
    { "kind": "specials", "amount": 3 }
  ],
  "stars": [2500, 2800, 3300],
  "seed": 0
}
```

| Key | Meaning |
|---|---|
| `title` | Shown in the HUD. |
| `width`, `height` | Board size, 3–10 each. |
| `colors` | Tile colors in play: 3 to `max_colors` (6 by default). Fewer colors means more matches, so the level is easier. |
| `moves` | Moves allowed. A swap that makes no match doesn't use a move. |
| `holes` | Cells with no tile, as `[x, y]`. `(0, 0)` is the top-left. Tiles fall past holes. |
| `goals` | All goals must be met to win. Kinds:<br>• `score`: reach `amount` points<br>• `collect`: clear `amount` tiles of `color`<br>• `specials`: create `amount` specials of any kind |
| `stars` | Scores for 1, 2 and 3 stars, ascending. Winning always gives at least 1 star. Unused moves add `points_per_move_left` each. |
| `seed` | `0` gives a new board every play. Any other number gives the same starting board every time, useful for a fixed tutorial level. |

**Tile color numbers** match the gem textures, `assets/tiles/gem_<n>.png`:

| Color | Gem |
|---|---|
| 0 | red heart |
| 1 | blue diamond |
| 2 | green emerald |
| 3 | yellow star |
| 4 | purple hexagon |
| 5 | orange orb |

Bad files are reported with clear messages by the checks (`test_levels.gd`), and by `push_error` when the game starts.

## Balancing

```
godot --headless --path . --script res://tools/balance.gd
godot --headless --path . --script res://tools/balance.gd -- level=4 runs=100
```

The report gives, for each level, the hint bot's win rate, its average score and stars, and **suggested star thresholds**. Suggested stars are the 20th, 50th and 85th percentile of the bot's winning scores; you can paste them into `stars`.

The bot plays the hint move every turn. Aim for about:

| Levels | Win rate |
|---|---|
| First levels | 90% or more |
| Middle levels | 60–85% |
| Hardest levels | 35–60% |

A check fails if the bot can't win a level even once in three tries.

To make a level easier, try in order:

1. more moves
2. lower goal amounts
3. fewer colors
4. fewer holes

Do the reverse to make it harder.
