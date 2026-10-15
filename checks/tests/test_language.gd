extends CheckCase
## Languages (game/strings.gd, docs/recipes/add-language.md): every language in
## Game.languages has a translation for every word players can see, and the
## player's choice is saved. The template ships English only, so the last two
## checks add a made-up language for the length of the check.

## Folders whose scenes and scripts hold the game's own words.
const UI_DIRS: Array[String] = ["res://ui", "res://game"]
## The shared settings screen; its words are translated by the same tables.
const SETTINGS_SCRIPT := "res://addons/codeplate/ui/settings_screen.gd"
## A language code the template doesn't ship, used only inside these checks.
const TEST_CODE := "eo"


## Every word a player can see, English text -> where it comes from.
static func english_words() -> Dictionary:
	var out: Dictionary = {}
	out[str(ProjectSettings.get_setting("application/config/name", ""))] = "project.godot config/name (title logo)"
	for dir: String in UI_DIRS:
		for file: String in DirAccess.get_files_at(dir):
			var path := dir.path_join(file)
			if file.ends_with(".tscn"):
				_scene_words(path, out)
			elif file.ends_with(".gd") and file != "strings.gd":
				_code_words(FileAccess.get_file_as_string(path), path, out)
	var settings := FileAccess.get_file_as_string(SETTINGS_SCRIPT)
	for re: String in ["(?:_t|_button|_heading|_volume_row)\\(\"((?:[^\"\\\\]|\\\\.)*)\"",
			"\\bif \\w+ else \"((?:[^\"\\\\]|\\\\.)*)\"\\)"]:
		for m: RegExMatch in RegEx.create_from_string(re).search_all(settings):
			_add(m.get_string(1).c_unescape(), "settings screen", out)
	for l: LevelData in Game.levels:
		_add(l.title, "levels/level_%02d.json title" % l.number, out)
	var credits := FileAccess.get_file_as_string(CodePlateSettings.CREDITS_PATH)
	for line: PackedStringArray in CodePlateSettings.credit_lines(credits):
		if not line[1].contains(CodePlateSettings.CODEPLATE_CREDIT):
			_add(line[1], "CREDITS.md", out)
	return out


## The words `table` lacks or leaves empty, each with where it comes from.
static func missing_words(table: Dictionary) -> PackedStringArray:
	var missing: PackedStringArray = []
	var words := english_words()
	for english: String in words:
		if str(table.get(english, "")).strip_edges() == "":
			missing.append("'%s' (%s)" % [english, words[english]])
	return missing


## Scene text Godot translates on its own: `text` and `tooltip_text` of every
## Control whose auto-translate is on. Labels that code fills in set
## auto_translate_mode = 2 (Disabled) and their script uses tr() instead.
static func _scene_words(path: String, out: Dictionary) -> void:
	var root := (load(path) as PackedScene).instantiate()
	_node_words(root, true, path, out)
	root.free()


static func _node_words(node: Node, parent_on: bool, path: String, out: Dictionary) -> void:
	var on := parent_on
	if node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_ALWAYS:
		on = true
	elif node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED:
		on = false
	if on and node is Control:
		_add(str(node.get(&"text")) if node.get(&"text") != null else "", "%s %s" % [path.get_file(), node.name], out)
		_add((node as Control).tooltip_text, "%s %s tooltip" % [path.get_file(), node.name], out)
	for child: Node in node.get_children():
		_node_words(child, on, path, out)


## Words set from code: tr("...") literals and string constants (not paths).
static func _code_words(code: String, path: String, out: Dictionary) -> void:
	for m: RegExMatch in RegEx.create_from_string("\\btr\\(\"((?:[^\"\\\\]|\\\\.)*)\"").search_all(code):
		_add(m.get_string(1).c_unescape(), path.get_file(), out)
	for m: RegExMatch in RegEx.create_from_string("(?m)^const \\w+ := \"((?:[^\"\\\\]|\\\\.)*)\"").search_all(code):
		var s := m.get_string(1).c_unescape()
		if not s.begins_with("res://") and not s.begins_with("user://"):
			_add(s, path.get_file(), out)


static func _add(s: String, where: String, out: Dictionary) -> void:
	var t := s.strip_edges()
	if t == "" or t.is_valid_float() or out.has(s):
		return
	out[s] = where


## A stand-in translation of every word, for the made-up test language.
static func _test_table() -> Dictionary:
	var table: Dictionary = {}
	for english: String in english_words():
		table[english] = "~" + english
	return table


func test_the_word_list_finds_words_in_every_place() -> void:
	var words := english_words()
	expect(words.has(str(ProjectSettings.get_setting("application/config/name"))), "the game name (title logo)")
	expect(words.has(ResultPanel.LOSE_TITLE) and words.has(ResultPanel.WIN_TITLE), "result panel words (code constants)")
	expect(words.has(PauseMenu.SOUND_ON_TEXT), "pause menu words (code constants)")
	expect(Array(words.values()).has("settings screen"), "settings screen words")
	expect(Array(words.keys()).any(func(w: String) -> bool: return str(words[w]).begins_with("title.tscn")), "title scene words")
	for l: LevelData in Game.levels:
		expect(l.title == "" or words.has(l.title), "level %d title" % l.number)
	expect(Array(words.values()).has("CREDITS.md"), "credits lines")
	expect(not words.has(CodePlateSettings.CODEPLATE_CREDIT), "the CodePlate credit is never translated")


func test_every_language_has_every_word() -> void:
	expect(Game.languages.has(Strings.SOURCE), "English is in Game.languages")
	for code: String in Game.languages:
		if code == Strings.SOURCE:
			continue
		if not expect(Strings.TABLES.has(code), "game/strings.gd TABLES has a table for '%s'" % code):
			continue
		var table: Dictionary = Strings.TABLES[code]
		var missing := missing_words(table)
		expect(missing.is_empty(), "'%s' has no translation for:\n       %s" % [code, "\n       ".join(missing)])
		expect(not table.has(CodePlateSettings.CODEPLATE_CREDIT),
			"'%s' leaves \"%s\" in English (the free license asks for that line)" % [code, CodePlateSettings.CODEPLATE_CREDIT])
	for code: String in Strings.TABLES:
		expect(Game.languages.has(code), "table '%s' is listed in Strings.LANGUAGES" % code)


func test_a_gap_in_a_table_is_reported() -> void:
	var table := _test_table()
	expect(missing_words(table).is_empty(), "a full table has nothing missing")
	table.erase(ResultPanel.LOSE_TITLE)
	table[PauseMenu.SOUND_ON_TEXT] = ""
	var missing := "\n".join(missing_words(table))
	expect(missing.contains(ResultPanel.LOSE_TITLE), "a missing word is reported")
	expect(missing.contains(PauseMenu.SOUND_ON_TEXT), "an empty translation is reported")


func test_language_row_hidden_with_one_language() -> void:
	if Game.languages.size() >= 2:
		return
	var title: Control = load("res://ui/title.tscn").instantiate()
	tree.root.add_child(title)
	await frames(2)
	var s: CodePlateSettings = title.call("open_settings")
	await frames(1)
	expect(s.find_child("LanguageRow", true, false) == null, "no language row while the game is English only")
	title.queue_free()
	await frames(1)


func test_switching_language_and_reloading_restores_it() -> void:
	var saved_path := Game.save_path
	Game.save_path = "user://check_language.json"
	Game.load_progress()
	expect_eq(Game.language, Strings.SOURCE, "English on a fresh save")
	var tables: Dictionary = Strings.TABLES.duplicate()
	tables[TEST_CODE] = _test_table()
	Strings.install(tables)
	Game.languages[TEST_CODE] = "Test"

	var title: Control = load("res://ui/title.tscn").instantiate()
	tree.root.add_child(title)
	await frames(2)
	var s: CodePlateSettings = title.call("open_settings")
	await frames(1)
	var button := s.find_child("Language_" + TEST_CODE, true, false) as Button
	if expect(button != null, "the settings screen shows a button per language"):
		button.button_pressed = true
		await frames(2)
		expect_eq(Game.language, TEST_CODE, "the button sets Game.language")
		expect_eq(tr(ResultPanel.LOSE_TITLE), "~" + ResultPanel.LOSE_TITLE, "words switch language")
		var game_name := str(ProjectSettings.get_setting("application/config/name"))
		expect_eq((title.get_node("%Logo") as Label).text, ("~" + game_name).to_upper(), "the title logo goes through tr()")
		s.close()
		Game.set_language(Strings.SOURCE)
		Game.load_progress()
		expect_eq(Game.language, TEST_CODE, "the language is saved and loaded again")
		expect_eq(TranslationServer.get_locale().substr(0, 2), TEST_CODE, "the loaded language is applied")

	title.queue_free()
	Game.languages.erase(TEST_CODE)
	Strings.install()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.save_path = saved_path
	Game.load_progress()
	expect_eq(TranslationServer.get_locale().substr(0, 2), Game.language.substr(0, 2), "language restored after the check")
