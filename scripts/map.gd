extends Node2D

## Map — a large, pannable / zoomable pencil-sketch grid, drawn procedurally
## (no image assets). A Camera2D handles pan and zoom, so the grid is drawn once
## and never needs to be re-rendered while the player moves around.
## World origin (0,0) is the top-left tile; x increases right, y increases down.

@export var cols: int = 100
@export var rows: int = 100
@export var cell_size: int = 32

@export_group("Sketch Style")
@export var paper_color: Color = Color("f1ece0")
@export var line_color: Color = Color("6f6453")
@export var line_width: float = 0.3

@export_subgroup("Pencil Effect")
# Perpendicular jitter amplitude, in pixels.
@export var wobble_amp: float = 5.0
# How quickly the wobble varies along a stroke (lower = longer, lazier waves).
@export var wobble_scale: float = 0.22
# A stroke is split into segments roughly this long (px).
@export var segment_len: float = 7.0
# Strokes cross slightly past each intersection, like a real sketch.
@export var overshoot: float = 3.0
# Graphite build-up passes layered on top of each other.
@export_range(1, 3) var passes: int = 2
# Base opacity of a single pass.
@export var stroke_alpha: float = 0.5
# Length (px) over which each line end fades out to transparent (0 = no fade).
@export var edge_fade: float = 36.0
# Random pencil-skip gaps: 0 = solid lines, higher = more / wider breaks.
@export_range(0.0, 0.6) var gap_amount: float = 0.45
# Gap frequency along a stroke (higher = shorter, more frequent gaps).
@export var gap_scale: float = 2.86

@export_group("Camera")
@export var min_zoom: float = 0.3
@export var max_zoom: float = 3.0
# Multiplier applied per mouse-wheel notch.
@export var zoom_step: float = 1.1
# A drag shorter than this (px) counts as a tap, not a pan.
@export var tap_threshold: float = 6.0

@onready var _camera: Camera2D = $Camera2D

var _noise := FastNoiseLite.new()
var _dragging := false
var _drag_moved := 0.0
var _touches := {}
var _pinch_dist := 0.0

## Emitted when the player taps a tile (a tap, not a drag).
signal tile_selected(tile_x: int, tile_y: int)

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = 1337
	var ms := _map_size()
	_camera.position = ms * 0.5
	_camera.zoom = Vector2.ONE
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(ms.x)
	_camera.limit_bottom = int(ms.y)
	_camera.make_current()
	_clamp_camera()

func _map_size() -> Vector2:
	return Vector2(cols * cell_size, rows * cell_size)

func _draw() -> void:
	var ms := _map_size()
	draw_rect(Rect2(Vector2.ZERO, ms), paper_color)
	var line_id := 0
	for x in range(1, cols):
		var fx := float(x * cell_size)
		_pencil_line(Vector2(fx, 0.0), Vector2(fx, ms.y), line_id)
		line_id += 1
	for y in range(1, rows):
		var fy := float(y * cell_size)
		_pencil_line(Vector2(0.0, fy), Vector2(ms.x, fy), line_id)
		line_id += 1

func _pencil_line(from: Vector2, to: Vector2, line_id: int) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var a := from - dir * overshoot
	var b := to + dir * overshoot
	var length := (b - a).length()
	var seg_count := maxi(2, int(length / segment_len))
	# Gap mask is independent of pass so both passes break at the same spots
	# (otherwise one pass would fill the other's gaps).
	var gap_off := float(line_id) * 13.0 + 500.0
	for p in range(passes):
		var line_off := float(p) * 17.0 + float(line_id) * 10.0
		var base_a := stroke_alpha if p == 0 else stroke_alpha * 0.6
		var pts := PackedVector2Array()
		var cols_arr := PackedColorArray()
		for i in range(seg_count + 1):
			var t := float(i) / seg_count
			var dist := t * length
			pts.append(a.lerp(b, t) + perp * _wobble(line_off, dist))
			cols_arr.append(Color(line_color.r, line_color.g, line_color.b, base_a * _edge_fade(dist, length) * _gap(gap_off, dist)))
		draw_polyline_colors(pts, cols_arr, line_width, true)

func _wobble(line_off: float, dist: float) -> float:
	return _noise.get_noise_2d(line_off, dist * wobble_scale) * wobble_amp

# Fades a stroke's opacity to 0 within `edge_fade` px of either end.
func _edge_fade(dist: float, length: float) -> float:
	if edge_fade <= 0.0:
		return 1.0
	return clampf(minf(dist, length - dist) / edge_fade, 0.0, 1.0)

# Returns 0 inside a random "pencil skip" gap, 1 on the drawn part of the stroke.
func _gap(gap_off: float, dist: float) -> float:
	if gap_amount <= 0.0:
		return 1.0
	var n := _noise.get_noise_2d(gap_off, dist * gap_scale) * 0.5 + 0.5
	return 0.0 if n > 1.0 - gap_amount else 1.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _dragging:
		_pan(event.relative)
		_drag_moved += event.relative.length()
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_at(event.position, zoom_step)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_at(event.position, 1.0 / zoom_step)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_moved = 0.0
		else:
			_dragging = false
			if _drag_moved < tap_threshold:
				_select_at(_screen_to_world(event.position))

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_drag_moved = 0.0
	else:
		var was_last := _touches.size() <= 1
		_touches.erase(event.index)
		if was_last and _drag_moved < tap_threshold:
			_select_at(_screen_to_world(event.position))
		if _touches.size() < 2:
			_pinch_dist = 0.0

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	_touches[event.index] = event.position
	if _touches.size() >= 2:
		_pinch_update()
	else:
		_pan(event.relative)
		_drag_moved += event.relative.length()

func _pinch_update() -> void:
	var keys := _touches.keys()
	var p0: Vector2 = _touches[keys[0]]
	var p1: Vector2 = _touches[keys[1]]
	var dist := p0.distance_to(p1)
	if _pinch_dist > 0.0 and dist > 0.0:
		_zoom_at((p0 + p1) * 0.5, dist / _pinch_dist)
	_pinch_dist = dist

func _pan(screen_delta: Vector2) -> void:
	_camera.position -= screen_delta / _camera.zoom
	_clamp_camera()

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_pos)
	var z := clampf(_camera.zoom.x * factor, min_zoom, max_zoom)
	_camera.zoom = Vector2(z, z)
	var after := _screen_to_world(screen_pos)
	_camera.position += before - after
	_clamp_camera()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	return _camera.position + (screen_pos - vp * 0.5) / _camera.zoom

# Keeps the camera centre inside the map so the view never shows past the edges
# (and, crucially, never lets `position` overflow past the bounds).
func _clamp_camera() -> void:
	var half := get_viewport().get_visible_rect().size * 0.5 / _camera.zoom
	var ms := _map_size()
	var pos := _camera.position
	pos.x = ms.x * 0.5 if half.x * 2.0 >= ms.x else clampf(pos.x, half.x, ms.x - half.x)
	pos.y = ms.y * 0.5 if half.y * 2.0 >= ms.y else clampf(pos.y, half.y, ms.y - half.y)
	_camera.position = pos

func _select_at(world_pos: Vector2) -> void:
	var ms := _map_size()
	if world_pos.x < 0.0 or world_pos.y < 0.0 or world_pos.x >= ms.x or world_pos.y >= ms.y:
		return
	var tx := int(world_pos.x / cell_size)
	var ty := int(world_pos.y / cell_size)
	print("[map] tile pressed (%d,%d)" % [tx, ty])
	tile_selected.emit(tx, ty)
