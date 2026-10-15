class_name Strings
extends RefCounted
## The game's words in other languages. English is the text written in the
## scenes and scripts; it needs no table. Each other language gets a table of
## "English text": "translated text" lines in TABLES and an entry in LANGUAGES.
## Godot swaps the words as the player picks a language (Game.set_language).
##
## The settings screen shows a language row once LANGUAGES has two or more
## entries. docs/recipes/add-language.md walks through adding one, and
## checks/tests/test_language.gd fails if a table misses a word.
##
## Keep "Built with CodePlate (codeplate.io)" out of every table: the CodePlate
## free license asks for that exact line.

## Language code -> the language's own name, shown on its settings button
## (e.g. "es": "Español"). English first; it's the default.
const LANGUAGES: Dictionary[String, String] = {"en": "English"}

## Language code -> {English text: translated text}. The English on the left
## must match the game's text exactly (capitals, punctuation and any %d / %s).
## Example once Spanish is added:
##   "es": {"Play": "Jugar", "Settings": "Ajustes", "LEVEL %d": "NIVEL %d"},
const TABLES: Dictionary[String, Dictionary] = {}

## The language the game is written in.
const SOURCE := "en"

static var _installed: Array[Translation] = []


## Gives Godot the translation tables. Replaces any it installed before, so
## calling it again (or with other tables, as the checks do) is safe.
static func install(tables: Dictionary = TABLES) -> void:
	uninstall()
	for code: String in tables:
		var t := Translation.new()
		t.locale = code
		var table: Dictionary = tables[code]
		for english: String in table:
			t.add_message(english, str(table[english]))
		TranslationServer.add_translation(t)
		_installed.append(t)


## Removes the tables install() added.
static func uninstall() -> void:
	for t: Translation in _installed:
		TranslationServer.remove_translation(t)
	_installed.clear()
