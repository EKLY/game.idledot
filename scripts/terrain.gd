extends Node2D
class_name Terrain

## Hand-drawn (procedural) mountains over the grid — no sprites. Mono palette to
## match the sketch map (player buildings get colour, not terrain). Each entry is
## Vector3i(cell_x, cell_y, width_cells 1..3); height is fixed in cells. Drawn
## once and cached like the grid. Child of Map; reads cell_size from the parent.
## See KB [[Map Objects]].

@export var mountains: Array[Vector3i] = [Vector3i(46, 50, 1), Vector3i(49, 50, 2), Vector3i(53, 50, 3)]:
	set(value):
		mountains = value
		queue_redraw()
@export var height_cells: float = 2.0:
	set(value):
		height_cells = value
		queue_redraw()
# How much shorter than height_cells a peak may randomly become (0 = every peak
# full height, 1 = peaks can shrink to nearly flat).
@export_range(0.0, 1.0) var height_randomness: float = 0.8:
	set(value):
		height_randomness = value
		queue_redraw()
# Valley depth between peaks, as a fraction of the lower neighbouring peak
# (kept < 1 so a valley always sits below both its peaks).
@export_range(0.1, 0.9) var valley_factor: float = 0.55:
	set(value):
		valley_factor = value
		queue_redraw()
@export var body_color: Color = Color(0.67, 0.64, 0.59)
@export var snow_color: Color = Color(0.96, 0.95, 0.91)
@export var rock_color: Color = Color(0.58, 0.55, 0.5)
@export var line_color: Color = Color(0.3, 0.27, 0.22)
# Base thickness for every terrain stroke (mountains + trees); some strokes scale
# it down (trunk ×0.7, snow line ×0.6, rock edge ×0.5).
@export var line_width: float = 0.8:
	set(value):
		line_width = value
		queue_redraw()

@export_group("Trees")
# Trees are scattered like grass: random cells get 1-3 trees at random spots and
# sizes. Each tree is drawn from its trunk base, so foliage may spill outside the
# cell. Placement is deterministic (hashed per cell) and cached with the rest.
@export_range(0.0, 1.0) var tree_density: float = 0.04:
	set(value):
		tree_density = value
		queue_redraw()
@export var tree_seed: int = 23:
	set(value):
		tree_seed = value
		queue_redraw()
@export var canopy_color: Color = Color(0.8, 0.79, 0.75)
@export var canopy_shade: Color = Color(0.6, 0.58, 0.53)
@export var trunk_color: Color = Color(0.42, 0.37, 0.3)
# Sizes relative to a cell.
@export var canopy_radius: float = 0.42
@export var trunk_height: float = 0.3
# Number of bumps around a broadleaf canopy.
@export_range(4, 12) var canopy_lobes: int = 8

@export_group("Boulders")
# Scattered like trees. Each boulder is one of 3 size tiers (small/medium/large)
# — same shape, only the size differs.
@export_range(0.0, 1.0) var boulder_density: float = 0.03:
	set(value):
		boulder_density = value
		queue_redraw()
@export var boulder_seed: int = 41:
	set(value):
		boulder_seed = value
		queue_redraw()
@export var boulder_color: Color = Color(0.7, 0.68, 0.63)
@export var boulder_shade: Color = Color(0.52, 0.5, 0.46)
# Radius (relative to a cell) of the largest tier; smaller tiers scale down.
@export var boulder_size: float = 0.42:
	set(value):
		boulder_size = value
		queue_redraw()

@export_group("Pencil")
# Perpendicular jitter so the strokes look hand-drawn, like the grid lines.
@export var wobble_amp: float = 2.0:
	set(value):
		wobble_amp = value
		queue_redraw()
# Lower = longer, lazier waves along the stroke.
@export var wobble_scale: float = 0.4
# The stroke is resampled into segments roughly this long (px).
@export var segment_len: float = 6.0
@export var noise_seed: int = 99

var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = noise_seed

func _draw() -> void:
	var cs: int = get_parent().cell_size
	for m in mountains:
		_draw_mountain(m.x, m.y, maxi(1, m.z), cs)
	_scatter_boulders(cs)
	_scatter_trees(cs)

func _draw_mountain(cx: int, cy: int, w: int, cs: int) -> void:
	var fcs := float(cs)
	var base_y := float(cy + 1) * fcs
	var left := float(cx) * fcs
	var max_h := height_cells * fcs
	# Peak heights first, so each valley can be placed below both its neighbours.
	var peaks: Array[Vector2] = []
	for i in range(w):
		var px := left + (float(i) + 0.5) * fcs
		var ph := max_h * lerpf(1.0 - height_randomness, 1.0, _rand01(cx + i * 7, cy, 1))
		peaks.append(Vector2(px, base_y - ph))
	# Silhouette: foot → peaks with valleys between them. A valley is a fraction
	# of the lower of its two peaks, so a short peak never dips below its valley.
	var sil := PackedVector2Array()
	sil.append(Vector2(left, base_y))
	for i in range(w):
		sil.append(peaks[i])
		if i < w - 1:
			var vx := left + float(i + 1) * fcs
			var lower := minf(base_y - peaks[i].y, base_y - peaks[i + 1].y)
			var vy := base_y - lower * valley_factor * (0.85 + 0.3 * _rand01(cx + i, cy, 2))
			sil.append(Vector2(vx, vy))
	sil.append(Vector2(left + float(w) * fcs, base_y))
	# Body (concave when multi-peak → triangulate before filling).
	_fill(sil, body_color)
	for peak in peaks:
		_draw_snow(peak, base_y, fcs)
	# Pencil outline of shoulders + peaks (open path → no line along the base).
	_pencil(sil, line_color, line_width, float(cx * 7 + cy * 13))
	# Scattered rocks at the foot.
	for k in range(2 + w):
		var rx := left + _rand01(cx, cy, 60 + k) * float(w) * fcs
		var rr := fcs * (0.05 + 0.04 * _rand01(cx, cy, 80 + k))
		var pos := Vector2(rx, base_y - rr * 0.5)
		draw_circle(pos, rr, rock_color)
		draw_arc(pos, rr, 0.0, TAU, 8, line_color, line_width * 0.5, true)

func _draw_snow(peak: Vector2, base_y: float, fcs: float) -> void:
	var ph := base_y - peak.y
	var run := fcs * 0.16
	var rise := ph * 0.32
	var sl := peak + Vector2(-run, rise)
	var sr := peak + Vector2(run, rise)
	draw_colored_polygon(PackedVector2Array([peak, sr, sl]), snow_color)
	_pencil(PackedVector2Array([sl, sr]), line_color, line_width * 0.6, peak.x + peak.y)

# Scatters trees deterministically (like grass): random cells get 1-3 trees at
# random spots and sizes. Trees are positioned by trunk base, so foliage spills
# freely past the cell edges.
func _scatter_trees(cs: int) -> void:
	var fcs := float(cs)
	var map := get_parent()
	var cols: int = map.cols
	var rows: int = map.rows
	for ty in range(rows):
		for tx in range(cols):
			if _rand01(tx, ty, tree_seed) >= tree_density:
				continue
			var count := 1 + int(_rand01(tx, ty, tree_seed + 1) * 3.0)
			for k in range(count):
				var bx := (float(tx) + _rand01(tx, ty, tree_seed + 10 + k)) * fcs
				var by := (float(ty) + 0.4 + 0.55 * _rand01(tx, ty, tree_seed + 20 + k)) * fcs
				var unit := fcs * (0.55 + 0.55 * _rand01(tx, ty, tree_seed + 30 + k))
				var salt := tx * 131 + ty * 17 + k * 7
				_draw_broadleaf(Vector2(bx, by), unit, salt)

# Round broadleaf tree at trunk base `base`, sized by `unit` (px): tapered trunk
# + a scalloped (lobed) canopy with the lower half shaded for volume.
func _draw_broadleaf(base: Vector2, unit: float, salt: int) -> void:
	var cxp := base.x
	var base_y := base.y
	var trunk_top := base_y - unit * trunk_height
	var r := unit * canopy_radius
	var center := Vector2(cxp, trunk_top - r * 0.5)
	var tw := unit * 0.06
	# Trunk first so the canopy overlaps its top.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cxp - tw, base_y), Vector2(cxp - tw * 0.55, trunk_top),
		Vector2(cxp + tw * 0.55, trunk_top), Vector2(cxp + tw, base_y)]), trunk_color)
	_pencil(PackedVector2Array([Vector2(cxp - tw, base_y), Vector2(cxp - tw * 0.55, trunk_top)]), line_color, line_width * 0.7, float(salt))
	_pencil(PackedVector2Array([Vector2(cxp + tw, base_y), Vector2(cxp + tw * 0.55, trunk_top)]), line_color, line_width * 0.7, float(salt) + 5.0)
	# Canopy fill, then a darker lower half for volume.
	var canopy := _scallop(center, r, salt)
	_fill(canopy, canopy_color)
	var n := canopy_lobes * 4
	var shade := PackedVector2Array()
	for i in range(n + 1):
		var a := lerpf(0.0, PI, float(i) / float(n))
		shade.append(center + Vector2(cos(a), sin(a)) * r * 0.95 * (1.0 + 0.13 * sin(a * float(canopy_lobes))))
	_fill(shade, canopy_shade)
	# Outline (closed loop).
	var ol := canopy.duplicate()
	ol.append(canopy[0])
	_pencil(ol, line_color, line_width, float(salt) + 1.0)

# Scatters boulders like trees: random cells, random spot, one of 3 size tiers
# (small/medium/large) — same shape, size only.
func _scatter_boulders(cs: int) -> void:
	var fcs := float(cs)
	var map := get_parent()
	var cols: int = map.cols
	var rows: int = map.rows
	var tier_mult: Array[float] = [0.45, 0.7, 1.0]
	for by_cell in range(rows):
		for bx_cell in range(cols):
			if _rand01(bx_cell, by_cell, boulder_seed) >= boulder_density:
				continue
			var tier := int(_rand01(bx_cell, by_cell, boulder_seed + 1) * 3.0)
			var bx := (float(bx_cell) + 0.2 + 0.6 * _rand01(bx_cell, by_cell, boulder_seed + 2)) * fcs
			var by := (float(by_cell) + 0.45 + 0.45 * _rand01(bx_cell, by_cell, boulder_seed + 3)) * fcs
			var unit := fcs * boulder_size * tier_mult[tier]
			_draw_boulder(Vector2(bx, by), unit, bx_cell * 53 + by_cell * 11)

# One boulder at base `base`, radius `r`: an irregular squashed rock with a
# shaded lower half, a crack, and a pencil outline.
func _draw_boulder(base: Vector2, r: float, salt: int) -> void:
	var center := Vector2(base.x, base.y - r * 0.62)
	var n := 9
	var sil := PackedVector2Array()
	for i in range(n):
		var a := TAU * (float(i) + 0.4 * _rand01(salt, i, 200)) / float(n)
		var rad := r * (0.78 + 0.34 * _rand01(salt, i, 210))
		sil.append(center + Vector2(cos(a) * rad, sin(a) * rad * 0.82))
	_fill(sil, boulder_color)
	# Shaded lower half for volume.
	var shade := PackedVector2Array()
	var m := 12
	for i in range(m + 1):
		var a := lerpf(0.0, PI, float(i) / float(m))
		shade.append(center + Vector2(cos(a) * r * 0.9, sin(a) * r * 0.74))
	_fill(shade, boulder_shade)
	# A crack across the face.
	var c0 := center + Vector2(-r * 0.1, -r * 0.55)
	var c1 := center + Vector2(r * 0.12, -r * 0.05)
	var c2 := center + Vector2(-r * 0.05, r * 0.35)
	_pencil(PackedVector2Array([c0, c1, c2]), line_color, line_width * 0.6, float(salt) + 3.0)
	# Outline (closed loop).
	var ol := sil.duplicate()
	ol.append(sil[0])
	_pencil(ol, line_color, line_width, float(salt))

# Lobed (cloud-like) canopy outline, with a little hand-drawn jitter per lobe.
func _scallop(center: Vector2, r: float, salt: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := canopy_lobes * 4
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var bump := 1.0 + 0.13 * sin(a * float(canopy_lobes))
		var jit := 0.93 + 0.14 * _rand01(salt, i, 100)
		pts.append(center + Vector2(cos(a), sin(a)) * r * bump * jit)
	return pts

# Draws a hand-drawn version of a polyline: resample it, then jitter each point
# perpendicular to the stroke with noise — same idea as the grid's pencil lines.
func _pencil(points: PackedVector2Array, color: Color, width: float, salt: float) -> void:
	var s := _resample(points, segment_len)
	var n := s.size()
	if n < 2:
		return
	var out := PackedVector2Array()
	var dist := 0.0
	for i in range(n):
		var tangent: Vector2
		if i == 0:
			tangent = (s[1] - s[0]).normalized()
		elif i == n - 1:
			tangent = (s[n - 1] - s[n - 2]).normalized()
		else:
			tangent = (s[i + 1] - s[i - 1]).normalized()
		var perp := Vector2(-tangent.y, tangent.x)
		out.append(s[i] + perp * _noise.get_noise_2d(salt, dist * wobble_scale) * wobble_amp)
		if i < n - 1:
			dist += s[i].distance_to(s[i + 1])
	draw_polyline(out, color, width, true)

# Splits a polyline into points spaced ~`step` px apart so the wobble has enough
# vertices to show along straight shoulders.
func _resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in range(n - 1):
		var a := points[i]
		var b := points[i + 1]
		var seg := a.distance_to(b)
		var count := maxi(1, int(seg / step))
		for k in range(count):
			out.append(a.lerp(b, float(k) / float(count)))
	out.append(points[n - 1])
	return out

# Fills an arbitrary (possibly concave) polygon by triangulating it first;
# draw_colored_polygon alone assumes convex.
func _fill(poly: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([poly[idx[t]], poly[idx[t + 1]], poly[idx[t + 2]]]), color)

# Deterministic per-cell pseudo-random in [0, 1) from the cell coords + a salt.
func _rand01(x: int, y: int, salt: int) -> float:
	return float(hash(Vector3i(x, y, salt)) & 0xFFFFFF) / float(0x1000000)
