extends Control
## Level grid. A level opens once the one before it has at least one star.

const STAR_FULL := preload("res://assets/ui/star_full.png")
const STAR_EMPTY := preload("res://assets/ui/star_empty.png")
const LOCK := preload("res://assets/ui/lock.png")
## The star count in the header (translated through game/strings.gd).
const STARS_TEXT := "%d / %d stars"
## Size of a level button; the grid fits as many columns as the view is wide.
const BUTTON_SIZE := 190.0

@onready var _grid: GridContainer = %Grid
@onready var _back: Button = %BackButton
@onready var _total: Label = %TotalStars


func _ready() -> void:
	_back.pressed.connect(func() -> void:
		Audio.play(&"click")
		Game.goto_title())
	var total := 0
	var last_open: Button = null
	for level: LevelData in Game.levels:
		var b := _level_button(level)
		_grid.add_child(b)
		total += Game.stars_for(level.number)
		if not b.disabled:
			last_open = b
	_total.text = tr(STARS_TEXT) % [total, Game.levels.size() * 3]
	resized.connect(_fit_columns)
	_fit_columns()
	if last_open != null:
		last_open.grab_focus.call_deferred()


## As many columns as fit the view: 3 on a portrait phone, 5 in landscape.
func _fit_columns() -> void:
	var margin := get_node("Margin") as MarginContainer
	var width := size.x - margin.get_theme_constant(&"margin_left") - margin.get_theme_constant(&"margin_right")
	var gap := float(_grid.get_theme_constant(&"h_separation"))
	_grid.columns = maxi(1, int((width + gap) / (BUTTON_SIZE + gap)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		Game.goto_title()


func _level_button(level: LevelData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	b.set_meta(&"level", level.number)
	b.disabled = not Game.is_unlocked(level.number)
	b.tooltip_text = level.title
	var rows := VBoxContainer.new()
	rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 6)
	b.add_child(rows)
	if b.disabled:
		var lock := TextureRect.new()
		lock.texture = LOCK
		lock.custom_minimum_size = Vector2(64, 64)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.modulate.a = 0.5
		rows.add_child(lock)
	else:
		var number := Label.new()
		number.text = str(level.number)
		number.add_theme_font_size_override("font_size", 64)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.add_child(number)
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i: int in 3:
			var s := TextureRect.new()
			s.texture = STAR_FULL if i < Game.stars_for(level.number) else STAR_EMPTY
			s.custom_minimum_size = Vector2(40, 40)
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars.add_child(s)
		rows.add_child(stars)
		b.pressed.connect(func() -> void:
			Audio.play(&"click")
			Game.play_level(level.number))
	return b
