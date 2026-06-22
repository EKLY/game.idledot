@tool
extends MarginContainer
class_name SketchBox

## A reusable hand-drawn "pencil sketch" frame, matching the map grid's look
## (see scripts/map.gd). Draws a soft shadow, an optional paper fill, and a
## wobbly graphite border with rounded corners around its own rect — no image
## assets. Because it is a MarginContainer, children sit inside the border with
## the configured padding. Reuse it for any framed UI surface: top bar, bottom
## sheet, popups, etc.

@export_group("Sketch Style")
@export var paper_color: Color = Color("dfbe91")
@export var line_color: Color = Color("806649")
@export var line_width: float = 1.2
# Corner radius of the rounded frame, in pixels (0 = sharp corners).
@export var corner_radius: float = 8.0
@export var fill_paper: bool = true

@export_subgroup("Pencil Effect")
# Perpendicular jitter amplitude, in pixels (kept smaller than the grid's).
@export var wobble_amp: float = 5.0
# How quickly the wobble varies along a stroke (lower = longer, lazier waves).
@export var wobble_scale: float = 0.22
# The outline is resampled into segments roughly this long (px).
@export var segment_len: float = 7.0
# Graphite build-up passes layered on top of each other.
@export_range(1, 3) var passes: int = 2
# Base opacity of a single pass.
@export var stroke_alpha: float = 0.5
# Random pencil-skip gaps: 0 = solid border, higher = more / wider breaks.
@export_range(0.0, 0.6) var gap_amount: float = 0.0
# Gap frequency along a stroke (higher = shorter, more frequent gaps).
@export var gap_scale: float = 2.86
# Seed for the noise so different boxes wobble differently.
@export var noise_seed: int = 4242:
	set(value):
		noise_seed = value
		_noise.seed = value
		queue_redraw()

@export_group("Paper Noise")
# A mottled "stain" texture blended onto the paper fill, clipped to the rounded
# shape. Rebuilt when its colour / threshold / seed change.
@export var paper_noise_enabled: bool = true:
	set(value):
		paper_noise_enabled = value
		queue_redraw()
@export var stain_color: Color = Color(0.42, 0.31, 0.16):
	set(value):
		stain_color = value
		_rebuild_stain()
# Overall visibility of the stains (alpha multiplier).
@export_range(0.0, 1.0) var stain_strength: float = 0.25:
	set(value):
		stain_strength = value
		queue_redraw()
# Texture tiles every this many px; larger = bigger, lazier stains.
@export var stain_tile: float = 130.0:
	set(value):
		stain_tile = maxf(8.0, value)
		queue_redraw()
# Noise value below which the paper stays clean (higher = sparser stains).
@export_range(0.0, 0.95) var stain_threshold: float = 0.75:
	set(value):
		stain_threshold = value
		_rebuild_stain()
@export var stain_seed: int = 99:
	set(value):
		stain_seed = value
		_rebuild_stain()

@export_group("Shadow")
# Soft drop shadow so the box reads as floating above the grid.
@export var shadow_enabled: bool = true
@export var shadow_color: Color = Color(0.2, 0.18, 0.14, 0.22)
# Shifts the shadow down/right, as if light comes from the top-left.
@export var shadow_offset: Vector2 = Vector2(0, 5)
# How far the shadow spreads past the box edge (px) — a fake blur radius.
@export var shadow_spread: float = 8.0
# More layers = smoother falloff (costs a few extra polygons).
@export_range(1, 12) var shadow_layers: int = 6

var _noise := FastNoiseLite.new()
var _stain_tex: NoiseTexture2D

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = noise_seed
	# Stain UVs run past 1.0, so the texture must tile instead of clamping its
	# right/bottom edge into a long stretched smear.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)
	_rebuild_stain()

func _draw() -> void:
	if shadow_enabled:
		_draw_shadow()
	var outline := _rounded_rect_points(Rect2(Vector2.ZERO, size), corner_radius)
	if fill_paper:
		draw_colored_polygon(outline, paper_color)
	if paper_noise_enabled and _stain_tex != null:
		_draw_stain(outline)
	_pencil_outline()

# Blends the stain texture over the paper, mapped so the texture tiles in screen
# space (uv = point / stain_tile). The polygon clips it to the rounded shape, and
# the white modulate keeps the ramp's own brown colour while scaling its alpha.
func _draw_stain(outline: PackedVector2Array) -> void:
	var uvs := PackedVector2Array()
	for p in outline:
		uvs.append(p / stain_tile)
	draw_colored_polygon(outline, Color(1.0, 1.0, 1.0, stain_strength), uvs, _stain_tex)

# Builds the seamless stain texture: simplex noise shaped by an alpha ramp so
# only the high-noise patches show up as translucent brown blotches.
func _rebuild_stain() -> void:
	if not is_node_ready():
		return
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = stain_seed
	noise.frequency = 0.03
	noise.fractal_octaves = 4
	var clear := Color(stain_color.r, stain_color.g, stain_color.b, 0.0)
	var solid := Color(stain_color.r, stain_color.g, stain_color.b, 1.0)
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, clear)
	ramp.set_offset(1, 1.0)
	ramp.set_color(1, solid)
	ramp.add_point(stain_threshold, clear)
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.color_ramp = ramp
	tex.noise = noise
	tex.changed.connect(queue_redraw)
	_stain_tex = tex
	queue_redraw()

# Fakes a soft blur by stacking translucent rounded polygons that shrink toward
# the box, so they overlap most in the centre and fade out at the spread edge.
# The paper fill drawn afterwards covers the middle, leaving only the halo.
func _draw_shadow() -> void:
	var per_layer := Color(shadow_color.r, shadow_color.g, shadow_color.b, shadow_color.a / float(shadow_layers))
	for i in range(shadow_layers, 0, -1):
		var grow := shadow_spread * float(i) / float(shadow_layers)
		var r := Rect2(shadow_offset - Vector2(grow, grow), size + Vector2(grow, grow) * 2.0)
		draw_colored_polygon(_rounded_rect_points(r, corner_radius + grow), per_layer)

# Draws the wobbly graphite border as a single closed stroke that follows the
# rounded-rect outline, layered `passes` times for a graphite build-up.
func _pencil_outline() -> void:
	var base := _rounded_rect_points(Rect2(Vector2.ZERO, size), corner_radius)
	var samples := _resample_closed(base, segment_len)
	var n := samples.size()
	if n < 3:
		return
	var gap_off := 777.0
	for p in range(passes):
		var line_off := float(p) * 17.0
		var base_a := stroke_alpha if p == 0 else stroke_alpha * 0.6
		var pts := PackedVector2Array()
		var cols_arr := PackedColorArray()
		var dist := 0.0
		for i in range(n + 1):
			var idx := i % n
			var cur: Vector2 = samples[idx]
			var nxt: Vector2 = samples[(idx + 1) % n]
			var prv: Vector2 = samples[(idx - 1 + n) % n]
			var tangent := (nxt - prv).normalized()
			var perp := Vector2(-tangent.y, tangent.x)
			pts.append(cur + perp * _wobble(line_off, dist))
			cols_arr.append(Color(line_color.r, line_color.g, line_color.b, base_a * _gap(gap_off, dist)))
			dist += cur.distance_to(nxt)
		draw_polyline_colors(pts, cols_arr, line_width, true)

# Builds the perimeter of a rounded rectangle as a closed point loop (convex),
# usable both as a fill polygon and as the path for the pencil stroke.
func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rad := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	if rad <= 0.5:
		pts.append(rect.position)
		pts.append(Vector2(rect.end.x, rect.position.y))
		pts.append(rect.end)
		pts.append(Vector2(rect.position.x, rect.end.y))
		return pts
	var c_tl := rect.position + Vector2(rad, rad)
	var c_tr := Vector2(rect.end.x - rad, rect.position.y + rad)
	var c_br := rect.end - Vector2(rad, rad)
	var c_bl := Vector2(rect.position.x + rad, rect.end.y - rad)
	_append_arc(pts, c_tl, rad, PI, PI * 1.5)
	_append_arc(pts, c_tr, rad, PI * 1.5, TAU)
	_append_arc(pts, c_br, rad, 0.0, PI * 0.5)
	_append_arc(pts, c_bl, rad, PI * 0.5, PI)
	return pts

func _append_arc(pts: PackedVector2Array, center: Vector2, radius: float, from_a: float, to_a: float) -> void:
	var steps := 5
	for i in range(steps + 1):
		var a := lerpf(from_a, to_a, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)

# Resamples a closed polygon into points spaced ~`step` px apart, so straight
# sides get enough vertices to show the pencil wobble.
func _resample_closed(base: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := base.size()
	for i in range(n):
		var a: Vector2 = base[i]
		var b: Vector2 = base[(i + 1) % n]
		var seg := a.distance_to(b)
		var count := maxi(1, int(seg / step))
		for k in range(count):
			out.append(a.lerp(b, float(k) / float(count)))
	return out

func _wobble(line_off: float, dist: float) -> float:
	return _noise.get_noise_2d(line_off, dist * wobble_scale) * wobble_amp

# Returns 0 inside a random "pencil skip" gap, 1 on the drawn part of the stroke.
func _gap(gap_off: float, dist: float) -> float:
	if gap_amount <= 0.0:
		return 1.0
	var n := _noise.get_noise_2d(gap_off, dist * gap_scale) * 0.5 + 0.5
	return 0.0 if n > 1.0 - gap_amount else 1.0
