# Export (build the game)

Use when the user wants a playable build for desktop, web or mobile.

1. **Export templates.** Godot needs export templates matching the editor version exactly (4.7.2).
   - They come from the official Godot download page (`Godot_v4.7.2-stable_export_templates.tpz`, about 1 GB).
   - Ask the user before downloading. Or let them install the templates from the editor: Editor → Manage Export Templates.
2. **Presets.** `export_presets.cfg` ships two: **Android** (see `export-android.md`) and **Web**. The Web preset is single-threaded (`thread_support=false`) and builds to `export/web/index.html`. For a desktop build, have the user add a preset in the editor (Project → Export), or copy the Web preset's filters into a new `[preset.N]` by hand and set its platform and `export_path`.
   - Builds go under `export/` (`export/web/`, `export/android/`...). Create the folder if it's missing. `export/` is git-ignored and holds an empty `.gdignore` so Godot doesn't import the builds; keep that file. The same goes for `shots/` (screenshots).
   - `exclude_filter` keeps `checks/*`, `tools/*`, `docs/*`, `shots/*`, `export/*` and `replays/*` out of the game. A new preset needs the same; a check fails otherwise.
   - `include_filter` matters: the game reads `levels/*.json` at runtime, and the credits page (title screen > Settings > Credits) reads `CREDITS.md` and `LICENSE.md`. None of them is a Godot resource, so without the filter the exported game starts with no levels, and its credits fall back to the CodePlate line alone.
   - `thread_support=false` makes the web build single-threaded, so it runs on any static host. Threaded builds need the COOP/COEP headers set on the server, so a check keeps Web presets single-threaded.
3. **Export headless:**
   ```
   godot --headless --path . --export-release "Web" export/web/index.html
   godot --headless --path . --export-release "Windows" export/windows/MyGame.exe
   ```
4. **Platform notes:**
   - **Web:** the project uses the Compatibility renderer, which is what browsers need. Serve the folder over HTTP to test (opening `index.html` as a file won't work).
   - **macOS:** builds should be signed and notarized for distribution; that needs the user's Apple developer account.
   - **Android:** see `export-android.md` (the project ships an Android preset).
   - **iOS:** needs a Mac with Xcode and an Apple developer account.
5. **Orientation.** The game is portrait (`window/handheld/orientation=1`). On desktop the window opens at 450×800 (`window_width_override` / `window_height_override` in `project.godot`).

## Verify

1. Run the checks before exporting.
2. Confirm the export command exits with status 0 and that the output file exists.
3. Ask the user to run the build on the target platform. You can't test it there yourself.
