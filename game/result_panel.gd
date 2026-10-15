class_name ResultPanel
extends Control
## The win / lose overlay at the end of a level.

signal next_pressed
signal retry_pressed
signal levels_pressed

const STAR_FULL := preload("res://assets/ui/star_full.png")
const STAR_EMPTY := preload("res://assets/ui/star_empty.png")

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _stars_box: HBoxContainer = %Stars
@onready var _score: Label = %Score
@onready var _detail: Label = %Detail
@onready var _next: Button = %NextButton
@onready var _retry: Button = %RetryButton
@onready var _levels: Button = %LevelsButton


func _ready() -> void:
	_next.pressed.connect(_click.bind(next_pressed))
	_retry.pressed.connect(_click.bind(retry_pressed))
	_levels.pressed.connect(_click.bind(levels_pressed))


func open(won: bool, stars: int, score: int, best: int, bonus: int, has_next: bool) -> void:
	_title.text = "Level complete!" if won else "Out of moves"
	_score.text = str(score)
	var detail := "Best: %d" % best
	if bonus > 0:
		detail = "Includes %d bonus for moves left  ·  %s" % [bonus, detail]
	_detail.text = detail
	_next.visible = won and has_next
	_retry.text = "Play again" if won else "Try again"
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
