# Replace sounds and add music

Use when the user has their own sound effects or music, or wants new sounds for new events.

## Replace a sound effect

1. Sounds are listed by name in `SOUNDS` in `autoload/audio.gd` (e.g. `&"match"` → `res://assets/audio/match.wav`). Each entry in `assets.json` says when that sound plays.
2. Put the new file in `assets/audio/`. `.wav` or `.ogg` both work; short effects are best as `.wav`.
   - Keeping the same file name means nothing else changes.
   - If the name changes, update the path in `SOUNDS` and in `assets.json`.
3. Update the entry in `assets.json`: `path`, `license`, `credit`.
4. **Re-import:** `godot --headless --path . --import`.

## Add a new sound for an event

1. Add the file, its `assets.json` entry, and a `SOUNDS` entry, e.g. `&"level_start": "res://assets/audio/level_start.wav"`.
2. Play it where the event happens: `Audio.play(&"level_start")`. Optional pitch and volume: `Audio.play(&"match", 1.2, -6.0)`.
   - Game events: `level.gd` (`_on_step_started`, `_finish`).
   - UI events: the screen scripts in `ui/`.

## Replace or add music

1. The template has one looping track, `assets/audio/music_theme.wav`, listed in `MUSIC` in `autoload/audio.gd` as `&"theme"`. `ui/title.gd` starts it, and it keeps playing on every screen.
2. **To replace it,** copy the user's track over `assets/audio/music_theme.wav`, or add the new file and change the path in `MUSIC`. Use `.ogg` for long music: it's much smaller than `.wav`. `play_music()` loops both. Update its `assets.json` entry (`path`, `license`, `credit`) and add a line to `CREDITS.md`.
3. **For per-screen music,** add more `MUSIC` entries (e.g. `&"level": "res://assets/audio/music_level.ogg"`) and call `Audio.play_music(&"level")` in that screen's `_ready()`. The same track keeps playing across screens; `&""` stops the music.
4. **Volume:** `MUSIC_DB` (−8 dB) in `audio.gd` is the music level at 100%. The player sets music and sound-effect volume on the settings screen (`Game.music_volume`, `Game.sfx_volume`); `Audio` applies both, so new sounds need nothing extra.

## Verify

1. Run the checks. `test_every_sound_exists` confirms every `SOUNDS` path imports, and `test_assets_json_matches_files` confirms the manifest.
2. You can't hear the game. Ask the user to play (`godot --path .`) and confirm the sounds and the music volume.
