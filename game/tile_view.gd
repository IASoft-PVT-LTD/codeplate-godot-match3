class_name TileView
extends Node2D
## Draws one tile and plays its small animations. BoardView owns and moves it.

var tile: Tile
var _size: float
var _gem: Sprite2D
var _overlay: Sprite2D
var _pulse: Tween
var _hint: Tween


func _init() -> void:
	_gem = Sprite2D.new()
	add_child(_gem)
	_overlay = Sprite2D.new()
	add_child(_overlay)


func setup(p_tile: Tile, size: float) -> void:
	tile = p_tile
	_size = size
	refresh()


## Re-reads the tile's color and special (after a shuffle or a conversion).
func refresh() -> void:
	_set_texture(_gem, TileSkin.tile_texture(tile))
	var ov := TileSkin.overlay(tile.special)
	_overlay.visible = ov != null
	if ov != null:
		_set_texture(_overlay, ov)
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	_overlay.modulate.a = 1.0
	if tile.is_special():
		_pulse = create_tween().set_loops()
		var target: CanvasItem = _overlay if ov != null else _gem
		_pulse.tween_property(target, "modulate:a", 0.6, 0.5).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(target, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)


func set_selected(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE * (1.12 if on else 1.0), 0.08)


## Gently bounces to show a hint; call with false to stop.
func set_hint(on: bool) -> void:
	if _hint != null:
		_hint.kill()
		_hint = null
	scale = Vector2.ONE
	if on:
		_hint = create_tween().set_loops()
		_hint.tween_property(self, "scale", Vector2.ONE * 1.15, 0.3).set_trans(Tween.TRANS_SINE)
		_hint.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)


## Pops in from nothing (new specials).
func pop_in(duration: float) -> void:
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Swells and fades out, then frees itself.
func vanish(duration: float) -> void:
	set_hint(false)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2.ONE * 1.35, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(queue_free)


## A short squash when landing after a fall.
func land(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 0.9), duration * 0.4)
	tw.tween_property(self, "scale", Vector2.ONE, duration * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_texture(sprite: Sprite2D, tex: Texture2D) -> void:
	sprite.texture = tex
	if tex != null:
		var fill := Game.config.tile_fill
		sprite.scale = Vector2.ONE * (_size * fill / maxf(tex.get_width(), tex.get_height()))
