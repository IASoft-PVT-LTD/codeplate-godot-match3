class_name ResultPanel
extends Control
## The win / lose overlay at the end of a level.

signal next_pressed
signal retry_pressed
signal levels_pressed

const STAR_FULL := preload("res://assets/ui/star_full.png")
const STAR_EMPTY := preload("res://assets/ui/star_empty.png")

## The panel's words. Change them here; checks compare against these names,
## never the English, and game/strings.gd translates them.
const WIN_TITLE := "Level complete!"
const LOSE_TITLE := "Out of moves"
const REPLAY_WON := "Play again"
const REPLAY_LOST := "Try again"
const BEST := "Best: %d"
const BONUS := "Includes %d bonus for moves left  ·  %s"

## True when the panel last opened for a win.
var won: bool = false

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _stars_box: HBoxContainer = %Stars
@onready var _score: Label = %Score
@onready var _detail: Label = %Detail
@onready var _next: Button = %NextButton
@onready var _retry: Button = %RetryButton
@onready var _levels: Button = %LevelsButton
@onready var _buttons: BoxContainer = %Buttons


func _ready() -> void:
	_next.pressed.connect(_click.bind(next_pressed))
	_retry.pressed.connect(_click.bind(retry_pressed))
	_levels.pressed.connect(_click.bind(levels_pressed))


func open(did_win: bool, stars: int, score: int, best: int, bonus: int, has_next: bool) -> void:
	won = did_win
	_title.text = tr(WIN_TITLE) if won else tr(LOSE_TITLE)
	_score.text = str(score)
	var detail := tr(BEST) % best
	if bonus > 0:
		detail = tr(BONUS) % [bonus, detail]
	_detail.text = detail
	_next.visible = won and has_next
	_retry.text = tr(REPLAY_WON) if won else tr(REPLAY_LOST)
	for c: Node in _stars_box.get_children():
		c.queue_free()
	var star_nodes: Array[TextureRect] = []
	for i: int in 3:
		var s := TextureRect.new()
		s.texture = STAR_EMPTY
		s.custom_minimum_size = Vector2(96, 96)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.pivot_offset = Vector2(48, 48)
		_stars_box.add_child(s)
		star_nodes.append(s)
	visible = true
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2.ONE * 0.8
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i: int in stars:
		tw.tween_interval(0.18)
		tw.tween_callback(_light_star.bind(star_nodes[i], i))
	(_next if _next.visible else _retry).grab_focus.call_deferred()


## Landscape: Next, Retry and Levels side by side instead of stacked.
func use_row_buttons() -> void:
	_buttons.vertical = false
	_panel.custom_minimum_size.x = 0.0


func close() -> void:
	visible = false


func _light_star(s: TextureRect, i: int) -> void:
	s.texture = STAR_FULL
	s.scale = Vector2.ONE * 1.8
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play(&"star", 1.0 + 0.12 * i)


func _click(sig: Signal) -> void:
	Audio.play(&"click")
	sig.emit()
