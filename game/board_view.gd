class_name BoardView
extends Node2D
## Draws the board, turns taps and swipes into swap requests, and replays a
## Resolver.Result's steps as animations. Holds no game rules.

## The player asked to swap two cells. game/level.gd decides what happens.
signal swap_requested(a: Vector2i, b: Vector2i)
## Emitted as each step starts animating (sound and score hooks).
signal step_started(step: Step)
## Every animation of the last `play()` has finished.
signal settled

const NO_CELL := Vector2i(-1, -1)

@export var cell_color_a := Color(1, 1, 1, 0.07)
@export var cell_color_b := Color(1, 1, 1, 0.11)
@export var frame_color := Color(0.05, 0.035, 0.12, 0.55)

var board: Board
var config: GameConfig
var busy: bool = false
var input_enabled: bool = true

var _cell: float
var _views: Dictionary[int, TileView] = {}
var _content: Node2D
var _clip: Polygon2D
var _fx: Fx
var _selected := NO_CELL
var _press_cell := NO_CELL
var _press_pos := Vector2.ZERO
var _idle := 0.0
var _hinted: Array[TileView] = []
var _shake := 0.0


func setup(p_board: Board, p_config: GameConfig) -> void:
	board = p_board
	config = p_config
	_cell = config.cell_size
	for c: Node in get_children():
		c.queue_free()
	_content = Node2D.new()
	add_child(_content)
	var backdrop := Node2D.new()
	backdrop.draw.connect(_draw_backdrop.bind(backdrop))
	_content.add_child(backdrop)
	_clip = Polygon2D.new()
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_clip.polygon = PackedVector2Array([Vector2.ZERO, Vector2(pixel_size().x, 0), pixel_size(), Vector2(0, pixel_size().y)])
	_content.add_child(_clip)
	_fx = Fx.new()
	_content.add_child(_fx)
	_views.clear()
	for cell: Vector2i in board.playable_cells():
		var t := board.get_tile(cell)
		if t != null:
			_add_view(t, cell)


## Size of the board in pixels, before this node's scale.
func pixel_size() -> Vector2:
	return Vector2(board.width, board.height) * _cell


## Center of a cell in this node's local space.
func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * _cell


func cell_at(local_pos: Vector2) -> Vector2i:
	return Vector2i(floori(local_pos.x / _cell), floori(local_pos.y / _cell))


## Screen (viewport) position of a cell's center. Checks use it to simulate taps.
func cell_to_screen(cell: Vector2i) -> Vector2:
	return get_global_transform_with_canvas() * cell_center(cell)


func view_for(tile: Tile) -> TileView:
	return _views.get(tile.id)


## Replays a result's steps. Await it, or wait for `settled`.
func play(result: Resolver.Result) -> void:
	busy = true
	_clear_hint()
	_set_selected(NO_CELL)
	for step: Step in result.steps:
		step_started.emit(step)
		await _play_step(step)
	busy = false
	_idle = 0.0
	settled.emit()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - _shake * config.shake_decay * delta - delta)
		_content.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	elif _content != null:
		_content.position = Vector2.ZERO
	if board == null or busy or not input_enabled:
		return
	_idle += delta
	if _idle >= config.hint_delay and _hinted.is_empty():
		var move := Moves.best(board)
		if not move.is_empty():
			for cell: Vector2i in move:
				var v := view_for(board.get_tile(cell))
				if v != null:
					v.set_hint(true)
					_hinted.append(v)


func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _unhandled_input(event: InputEvent) -> void:
	if board == null or busy or not input_enabled:
		return
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	var local := make_input_local(event) as InputEventMouse
	var cell := cell_at(local.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_idle = 0.0
			_clear_hint()
			if not board.is_playable(cell) or board.get_tile(cell) == null:
				_set_selected(NO_CELL)
				return
			get_viewport().set_input_as_handled()
			if _selected != NO_CELL and Moves.are_adjacent(_selected, cell):
				var from := _selected
				_set_selected(NO_CELL)
				swap_requested.emit(from, cell)
				return
			_set_selected(cell)
			_press_cell = cell
			_press_pos = local.position
		else:
			_press_cell = NO_CELL
	elif event is InputEventMouseMotion and _press_cell != NO_CELL:
		var drag := local.position - _press_pos
		if drag.length() >= config.swipe_threshold * _cell:
			var dir := Vector2i(signi(roundi(drag.x)), 0) if absf(drag.x) > absf(drag.y) else Vector2i(0, signi(roundi(drag.y)))
			var from := _press_cell
			_press_cell = NO_CELL
			_set_selected(NO_CELL)
			get_viewport().set_input_as_handled()
			if board.is_playable(from + dir):
				swap_requested.emit(from, from + dir)


func _set_selected(cell: Vector2i) -> void:
	if _selected != NO_CELL and board.get_tile(_selected) != null:
		var old := view_for(board.get_tile(_selected))
		if old != null:
			old.set_selected(false)
	_selected = cell
	if cell != NO_CELL:
		var v := view_for(board.get_tile(cell))
		if v != null:
			v.set_selected(true)


func _clear_hint() -> void:
	for v: TileView in _hinted:
		if is_instance_valid(v):
			v.set_hint(false)
	_hinted.clear()


func _add_view(tile: Tile, cell: Vector2i) -> TileView:
	var v := TileView.new()
	v.setup(tile, _cell)
	v.position = cell_center(cell)
	_clip.add_child(v)
	_views[tile.id] = v
	return v


func _play_step(step: Step) -> void:
	match step.type:
		Step.Type.SWAP:
			await _animate_swap(step, false)
		Step.Type.SWAP_BACK:
			await _animate_swap(step, true)
		Step.Type.CLEAR:
			await _animate_clear(step)
		Step.Type.FALL:
			await _animate_fall(step)
		Step.Type.SHUFFLE:
			await _animate_shuffle(step)


func _animate_swap(step: Step, back: bool) -> void:
	var a := step.a
	var b := step.b
	var va := view_for(step.tile_a)
	var vb := view_for(step.tile_b)
	if va == null or vb == null:
		return
	var d := config.t(config.swap_time)
	var tw := create_tween().set_parallel()
	tw.tween_property(va, "position", cell_center(b), d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(vb, "position", cell_center(a), d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if back:
		tw.chain().tween_property(va, "position", cell_center(a), d).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(vb, "position", cell_center(b), d).set_trans(Tween.TRANS_QUAD)
	await tw.finished


func _animate_clear(step: Step) -> void:
	var d := config.t(config.clear_time)
	_fx.speed = config.animation_speed
	for act: Step.Activation in step.activations:
		_activation_fx(act, d)
	var center := Vector2.ZERO
	for c: Step.Cleared in step.cleared:
		var v: TileView = _views.get(c.tile.id)
		if v != null:
			_views.erase(c.tile.id)
			v.vanish(d)
		_fx.burst(cell_center(c.cell), TileSkin.tint(c.tile.color) if c.tile.color >= 0 else Color.WHITE, config.particles_per_tile)
		center += cell_center(c.cell)
	if not step.cleared.is_empty() and step.points > 0:
		var label := "+%d" % step.points
		if step.cascade > 0:
			label += "  x%s" % String.num(1.0 + step.cascade * config.cascade_multiplier_step, 2).trim_suffix(".0")
		_fx.popup(center / step.cleared.size(), label)
	for cr: Step.Created in step.created:
		var v := _add_view(cr.tile, cr.cell)
		v.pop_in(config.t(config.spawn_pop_time))
		_fx.ring(cell_center(cr.cell), Color.WHITE, _cell * 0.9, config.t(0.35))
	await get_tree().create_timer(d + config.t(config.cascade_pause)).timeout


func _activation_fx(act: Step.Activation, d: float) -> void:
	var at := cell_center(act.cell)
	var white := Color(1, 1, 1, 0.95)
	match act.special:
		Tile.Special.LINE_H:
			_fx.beam(Vector2(0, at.y), Vector2(pixel_size().x, at.y), white, _cell * 0.9, config.t(0.35))
			shake(config.shake_line)
		Tile.Special.LINE_V:
			_fx.beam(Vector2(at.x, 0), Vector2(at.x, pixel_size().y), white, _cell * 0.9, config.t(0.35))
			shake(config.shake_line)
		Tile.Special.BOMB:
			var r := 0.0
			for c: Vector2i in act.cells:
				r = maxf(r, cell_center(c).distance_to(at))
			_fx.ring(at, Color(1, 0.9, 0.6), r + _cell * 0.6, config.t(0.4))
			shake(config.shake_bomb)
		Tile.Special.COLOR:
			var tint := TileSkin.tint(act.color) if act.color >= 0 else Color.WHITE
			for c: Vector2i in act.cells:
				if c != act.cell:
					_fx.beam(at, cell_center(c), tint, _cell * 0.25, config.t(0.4))
			_fx.ring(at, tint, _cell * 2.0, config.t(0.4))
			shake(config.shake_color)


func _animate_fall(step: Step) -> void:
	if step.falls.is_empty():
		return
	var tw := create_tween().set_parallel()
	var longest := 0.0
	for f: Step.Fall in step.falls:
		var v: TileView = _views.get(f.tile.id)
		if v == null:
			v = _add_view(f.tile, f.from)
		v.position = cell_center(f.from)
		var cells := float(f.to.y - f.from.y)
		var d := config.t(maxf(config.fall_min_time, cells * config.fall_time_per_cell))
		longest = maxf(longest, d)
		tw.tween_property(v, "position", cell_center(f.to), d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(v.land.bind(config.t(0.16))).set_delay(d)
	await tw.finished


func _animate_shuffle(step: Step) -> void:
	var d := config.t(config.shuffle_time)
	var mid := pixel_size() / 2.0
	var tw := create_tween().set_parallel()
	for id: int in step.positions:
		var v: TileView = _views.get(id)
		if v == null:
			continue
		v.refresh()
		tw.tween_property(v, "position", mid, d / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(v, "position", cell_center(step.positions[id]), d / 2.0) \
			.set_delay(d / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


func _draw_backdrop(canvas: Node2D) -> void:
	var pad := _cell * 0.12
	var frame := StyleBoxFlat.new()
	frame.bg_color = frame_color
	frame.set_corner_radius_all(int(_cell * 0.3))
	canvas.draw_style_box(frame, Rect2(-Vector2.ONE * pad, pixel_size() + Vector2.ONE * pad * 2))
	var cell_box := StyleBoxFlat.new()
	cell_box.set_corner_radius_all(int(_cell * 0.16))
	for cell: Vector2i in board.playable_cells():
		cell_box.bg_color = cell_color_a if (cell.x + cell.y) % 2 == 0 else cell_color_b
		canvas.draw_style_box(cell_box, Rect2(Vector2(cell) * _cell + Vector2.ONE * 2, Vector2.ONE * (_cell - 4)))
