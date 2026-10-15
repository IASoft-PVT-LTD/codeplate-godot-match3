class_name Hud
extends MarginContainer
## The HUD during play: level name, score with a three-star bar, moves left,
## and goals. A bar across the top in portrait; a side panel in landscape
## (use_side_panel()).

const STAR_FULL := preload("res://assets/ui/star_full.png")
const STAR_EMPTY := preload("res://assets/ui/star_empty.png")
const SCORE_ICON := preload("res://assets/ui/star_full.png")
const SPECIALS_ICON := preload("res://assets/specials/color_bomb.png")
const CHECK_ICON := preload("res://assets/ui/check.png")
## The level caption (translated through game/strings.gd; level titles too).
const LEVEL_TEXT := "LEVEL %d"
const LEVEL_TITLE_TEXT := "LEVEL %d  ·  %s"

@onready var _level_label: Label = %LevelLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _star_bar: Control = %StarBar
@onready var _moves_label: Label = %MovesLabel
@onready var _goals_box: BoxContainer = %Goals
@onready var _top: BoxContainer = %Top

var _session: LevelSession
var _bar: ProgressBar
var _stars: Array[TextureRect] = []
var _lit: Array[bool] = [false, false, false]
var _goal_labels: Array[Label] = []
var _goal_checks: Array[TextureRect] = []
var _shown_score: float = 0.0
var _score_tween: Tween


func setup(session: LevelSession) -> void:
	_session = session
	var level := session.level
	_level_label.text = (tr(LEVEL_TITLE_TEXT) % [level.number, tr(level.title).to_upper()]) if level.title else tr(LEVEL_TEXT) % level.number

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_bar.add_child(_bar)
	for i: int in 3:
		var s := TextureRect.new()
		s.texture = STAR_EMPTY
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.size = Vector2(44, 44)
		s.pivot_offset = s.size / 2.0
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_star_bar.add_child(s)
		_stars.append(s)
	_star_bar.resized.connect(_layout_star_bar)
	_layout_star_bar()

	for g: LevelData.Goal in level.goals:
		var chip := PanelContainer.new()
		chip.theme_type_variation = &"Chip"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		match g.kind:
			LevelData.GoalKind.SCORE: icon.texture = SCORE_ICON
			LevelData.GoalKind.COLLECT: icon.texture = TileSkin.gem(g.color)
			LevelData.GoalKind.SPECIALS: icon.texture = SPECIALS_ICON
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 32)
		var check := TextureRect.new()
		check.texture = CHECK_ICON
		check.custom_minimum_size = Vector2(40, 40)
		check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		check.modulate = Color("#7dffb0")
		check.visible = false
		row.add_child(icon)
		row.add_child(label)
		row.add_child(check)
		_goal_checks.append(check)
		chip.add_child(row)
		_goals_box.add_child(chip)
		_goal_labels.append(label)
	refresh(false)


## Landscape: a column `width` pixels wide down the right edge of the
## screen, with the score, moves and goals stacked.
func use_side_panel(width: float) -> void:
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -width
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_top.vertical = true
	_goals_box.vertical = true
	_goals_box.alignment = BoxContainer.ALIGNMENT_BEGIN


## Updates every number. `animate` counts the score up.
func refresh(animate: bool = true) -> void:
	_moves_label.text = str(_session.moves_left)
	_moves_label.add_theme_color_override("font_color", Color("#ff8fa3") if _session.moves_left <= 5 else Color.WHITE)
	show_score(_session.score, animate)
	for i: int in _goal_labels.size():
		var g := _session.level.goals[i]
		var done := _session.progress[i] >= g.amount
		# A met goal shows the check icon instead of its number (an image, so it
		# never depends on the font having a check-mark glyph).
		_goal_checks[i].visible = done
		_goal_labels[i].visible = not done
		if g.kind == LevelData.GoalKind.SCORE:
			_goal_labels[i].text = "%d" % g.amount
		else:
			_goal_labels[i].text = "%d" % (g.amount - _session.progress[i])


## Moves the displayed score toward `value`.
func show_score(value: int, animate: bool = true) -> void:
	if _score_tween != null:
		_score_tween.kill()
	if not animate:
		_set_shown_score(value)
		return
	_score_tween = create_tween()
	_score_tween.tween_method(_set_shown_score, _shown_score, float(value), 0.35)


func _set_shown_score(v: float) -> void:
	_shown_score = v
	_score_label.text = str(int(v))
	_bar.value = _bar_fill(v)
	var thresholds := _session.level.stars
	for i: int in 3:
		var lit := v >= thresholds[i]
		if lit and not _lit[i]:
			_stars[i].texture = STAR_FULL
			var tw := _stars[i].create_tween()
			_stars[i].scale = Vector2.ONE * 1.6
			tw.tween_property(_stars[i], "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Audio.play(&"star", 1.0 + 0.1 * i, -6.0)
		elif not lit:
			_stars[i].texture = STAR_EMPTY
		_lit[i] = lit


## Stars sit at 1/3, 2/3 and the end of the bar; the fill moves linearly
## between thresholds, so close thresholds never overlap.
func _bar_fill(score: float) -> float:
	var s := _session.level.stars
	var prev := 0.0
	for i: int in 3:
		if score < s[i]:
			return (i + (score - prev) / maxf(s[i] - prev, 1.0)) / 3.0
		prev = s[i]
	return 1.0


func _layout_star_bar() -> void:
	if _bar == null:
		return
	var w := _star_bar.size.x - 22.0
	_bar.position = Vector2(0, 14)
	_bar.size = Vector2(w, 16)
	for i: int in 3:
		_stars[i].position = Vector2(w * (i + 1) / 3.0 - 22.0, 0)
