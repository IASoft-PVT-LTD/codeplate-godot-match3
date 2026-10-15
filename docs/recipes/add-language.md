# Add a language

Use when the user wants the game in another language (or in several), including a language picker for players.

The game's words stay in English in the scenes and scripts; a table per language maps each English text to its translation, and Godot swaps the words when the player picks a language. The template ships English only, so nothing shows until a second language is added. The pieces are already there: `game/strings.gd` (the tables), `Game.set_language()` and `Game.language` (saved with the progress), the title logo and every button through `tr()`, and a check that lists what's missing.

1. **Ask which languages,** and who translates. Write the translations yourself only if the user wants that, and say that a native speaker should read them.
2. **Add the language** to `game/strings.gd`:
   - an entry in `LANGUAGES`: the code and the name players see on its button, in that language (`"es": "Español"`);
   - a table in `TABLES` for the same code: `"English text": "translated text"` for every word.
3. **List what needs translating:** run the checks. `test_every_language_has_every_word` names every English text a player can see that the table lacks, and where it comes from: the scene or script, a level title (`levels/level_NN.json`), a line of `CREDITS.md`, or the settings screen. Add them all. Keep the English on the left exactly as written (capitals, punctuation, `%d` and `%s` in the same order).
4. **Words that never change:** the line "Built with CodePlate (codeplate.io)" stays in English, in `CREDITS.md` only. Leave it out of every table. Credit lines naming people or libraries (Godot Engine, an artist) are names, not text to translate, so they stay as written; the check accepts a table that repeats them.
5. **Fonts.** The default font may lack accents or marks like `¡` and `¿`. Look at a screenshot with the language on (step 7). If a letter shows as a box, add a font that has it (the user's own, OFL or CC0; see `rebrand.md` step 8) and list it in `assets.json`.
6. **Level names and goals:** level titles are in `levels/level_NN.json` (`title`) and are translated like any other text. Text built from numbers (`LEVEL %d`, `%d / %d stars`) goes in the table as the pattern.
7. **Look at it.** With two languages the settings screen shows a language row (one button per language). The player's choice is saved. To screenshot a language, set `language` in a scratch save, or call `Game.set_language("es")` from a screenshot hook, then:
   ```
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=title
   godot --path . --script res://addons/codeplate/tools/screenshot.gd -- screen=level level=1
   ```
   Longer words can overflow buttons and the HUD. Fix the layout, not the translation, unless the translation is poor.

## Verify

1. Run the checks. `test_every_language_has_every_word` must pass for every language in `Game.languages`, and `test_switching_language_and_reloading_restores_it` proves the choice is saved and loaded.
2. Screenshots of the title, settings (with the language row), level select, a level and the result panel in each language.
3. Tell the user which texts you translated yourself.
