class_name Fx
extends Node2D
## One-shot visual effects drawn above the tiles: bursts, rings, beams and
## score popups. Every effect frees itself when done.

## Playback speed for bursts and popups (BoardView keeps it equal to
## config.animation_speed). Rings and beams take explicit durations instead.
var speed: float = 1.0

const SPARK := preload("res://assets/fx/spark.png")
const RING := preload("res://assets/fx/ring.png")
const BEAM := preload("res://assets/fx/beam.png")


## A burst of particles, e.g. where a tile was cleared.
func burst(pos: Vector2, color: Color, amount: int) -> void:
	if amount <= 0:
		return
	var p := CPUParticles2D.new()
	p.texture = SPARK
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 700)
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	p.color = color.lightened(0.2)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.speed_scale = speed
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## An expanding ring. `radius` is in pixels.
func ring(pos: Vector2, color: Color, radius: float, duration: float) -> void:
	var s := Sprite2D.new()
	s.texture = RING
	s.position = pos
	s.modulate = color
	s.scale = Vector2.ONE * 0.1
	add_child(s)
	var target := Vector2.ONE * (radius * 2.0 / RING.get_width())
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)


## A glowing beam from `a` to `b` that fades out.
func beam(a: Vector2, b: Vector2, color: Color, thickness: float, duration: float) -> void:
	var s := Sprite2D.new()
	s.texture = BEAM
	s.position = (a + b) / 2.0
	s.rotation = (b - a).angle()
	s.scale = Vector2((a.distance_to(b) + thickness) / BEAM.get_width(), thickness / BEAM.get_height())
	s.modulate = color
	add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale:y", s.scale.y * 0.2, duration).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)


## Floating text that rises and fades (score popups).
func popup(pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 40) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.25))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(240, 60)
	l.position = pos - l.size / 2.0
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2.ONE * 0.5
	add_child(l)
	var tw := l.create_tween()
	tw.set_speed_scale(speed)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:y", l.position.y - 70, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)
