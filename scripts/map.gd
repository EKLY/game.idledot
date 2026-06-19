extends Control

## Map screen — draws a pencil / hand-sketch grid procedurally (no image assets).
## Each line is wobbled, drawn in multiple low-opacity passes, overshoots the
## intersections slightly and varies its weight to mimic a graphite stroke.
## Origin (0,0) is the top-left tile; x increases right, y increases down.

@export var cols: int = 12
@export var rows: int = 12
@export var cell_size: int = 42

@export_group("Sketch Style")
@export var paper_color: Color = Color("f1ece0")
@export var line_color: Color = Color("6f6453")
@export var line_width: float = 1.0

@export_subgroup("Pencil Effect")
# Perpendicular jitter amplitude, in pixels.
@export var wobble_amp: float = 2.3
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

var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = 1337
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), paper_color)
	var origin := _grid_origin()
	var gs := _grid_size()
	var line_id := 0
	for x in range(1, cols):
		var fx := origin.x + x * cell_size
		_pencil_line(Vector2(fx, origin.y), Vector2(fx, origin.y + gs.y), line_id)
		line_id += 1
	for y in range(1, rows):
		var fy := origin.y + y * cell_size
		_pencil_line(Vector2(origin.x, fy), Vector2(origin.x + gs.x, fy), line_id)
		line_id += 1

func _pencil_line(from: Vector2, to: Vector2, line_id: int) -> void:
	var base_color := line_color
	var width := line_width
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var a := from - dir * overshoot
	var b := to + dir * overshoot
	var length := (b - a).length()
	var seg_count := maxi(2, int(length / segment_len))
	for p in range(passes):
		var line_off := float(p) * 17.0 + float(line_id) * 10.0
		var alpha := stroke_alpha if p == 0 else stroke_alpha * 0.6
		var prev := a + perp * _wobble(line_off, 0.0)
		for i in range(1, seg_count + 1):
			var dist := float(i) / seg_count * length
			var pt := a.lerp(b, float(i) / seg_count) + perp * _wobble(line_off, dist)
			var pressure := absf(_noise.get_noise_2d(line_off + 50.0, dist * wobble_scale))
			var w := width * (0.75 + 0.5 * pressure)
			var col := Color(base_color.r, base_color.g, base_color.b, alpha * _edge_fade(dist, length))
			draw_line(prev, pt, col, w, true)
			prev = pt

func _wobble(line_off: float, dist: float) -> float:
	return _noise.get_noise_2d(line_off, dist * wobble_scale) * wobble_amp

# Fades a stroke's opacity to 0 within `edge_fade` px of either end.
func _edge_fade(dist: float, length: float) -> float:
	if edge_fade <= 0.0:
		return 1.0
	return clampf(minf(dist, length - dist) / edge_fade, 0.0, 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)

func _handle_tap(pos: Vector2) -> void:
	var local := pos - _grid_origin()
	var grid_size := _grid_size()
	if local.x < 0.0 or local.y < 0.0 or local.x >= grid_size.x or local.y >= grid_size.y:
		return
	var tx := int(local.x / cell_size)
	var ty := int(local.y / cell_size)
	print("[map] tile pressed (%d,%d)" % [tx, ty])

func _grid_size() -> Vector2:
	return Vector2(cols * cell_size, rows * cell_size)

func _grid_origin() -> Vector2:
	return ((size - _grid_size()) * 0.5).round()
