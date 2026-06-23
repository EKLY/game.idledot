extends Node2D

## Map — a large, pannable / zoomable pencil-sketch grid, drawn procedurally
## (no image assets). A Camera2D handles pan and zoom, so the grid is drawn once
## and never needs to be re-rendered while the player moves around.
## World origin (0,0) is the top-left tile; x increases right, y increases down.

@export var cols: int = 100
@export var rows: int = 100
@export var cell_size: int = 32

@export_group("World Gen")
# Seed + densities/counts the map is generated from. Resources & scatter layout
# are baked into `world` once on _ready; renderers read it (see WorldData).
@export var world_seed: int = 2024
@export var mountain_clusters: int = 3
@export var mountain_per_cluster: int = 6
@export var mountain_spread: int = 4
@export var pond_count: int = 3
@export_range(0.0, 1.0) var grass_density: float = 0.22
@export_range(0.0, 1.0) var pebble_density: float = 0.07
@export_range(0.0, 1.0) var tree_density: float = 0.04
@export_range(0.0, 1.0) var boulder_density: float = 0.03

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
# How far past the top / bottom edge you can pan, in screen-heights — lets tiles
# hidden behind the top bar / bottom sheet scroll into view.
@export var pan_overscroll: float = 0.5

@onready var _camera: Camera2D = $Camera2D

var _noise := FastNoiseLite.new()
var _dragging := false
var _pan_enabled := true
var _drag_moved := 0.0
var _touches := {}
var _pinch_dist := 0.0
# A screen rect (set by the UI for the open bottom sheet) whose gestures must NOT
# reach the map. Touches that press inside it are tracked so their drag/release are
# ignored too — keeping the map from panning under the panel.
var _ui_block_rect := Rect2()
var _blocked_touches := {}
var _mouse_blocked := false

## The generated world (resources + per-cell scatter). Read by Terrain / TileDecorator.
var world: WorldData

## Emitted when the player taps a tile (a tap, not a drag).
signal tile_selected(tile_x: int, tile_y: int)
## Emitted when the current selection is cleared (e.g. the panel is closed).
signal tile_deselected
## Emitted when build-mode state changes (ghost moved, building placed, mode toggled).
signal build_changed

## Building catalog, loaded once; placed buildings reference entries by id.
var catalog: Array[Dictionary] = []
var catalog_by_id: Dictionary = {}

## TEMP placeholder for the player's money (matches the top-bar mockup) — the build
## list shows only affordable buildings. Replace when the Economy/GameState lands.
var money: float = 1200.0

## Build mode (placement). build_active=false means normal tap-to-select.
var build_active := false
var build_entry: Dictionary = {}
var build_ghost := Vector2i(-1, -1)
var build_valid := false

func _ready() -> void:
	# Paint the viewport background the same as the grid paper, so the area shown
	# when overscrolling past the map edge blends in instead of a grey void.
	RenderingServer.set_default_clear_color(paper_color)
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = 1337
	_setup_camera()
	# Generate the world once, then ask the drawing children to render from it.
	# (Children _ready before the parent, so they draw empty until this runs.)
	world = WorldData.generate(world_seed, cols, rows, _gen_config())
	catalog = BuildingCatalog.load_all()
	catalog_by_id.clear()
	for e in catalog:
		catalog_by_id[e.id] = e
	for c in get_children():
		if c is CanvasItem:
			c.queue_redraw()

func _map_size() -> Vector2:
	return Vector2(cols * cell_size, rows * cell_size)

# Centres the camera on the map and recomputes its pan limits (used on first load
# and whenever the map is regenerated at a new size).
func _setup_camera() -> void:
	var ms := _map_size()
	_camera.position = ms * 0.5
	_camera.zoom = Vector2.ONE
	# Widen the top/bottom render limits so the overscroll (panning past the edge)
	# isn't clamped away by Camera2D. _clamp_camera does the real per-zoom limiting.
	var over_max := get_viewport().get_visible_rect().size.y * pan_overscroll / min_zoom
	_camera.limit_left = 0
	_camera.limit_top = int(-over_max)
	_camera.limit_right = int(ms.x)
	_camera.limit_bottom = int(ms.y + over_max)
	_camera.make_current()
	_clamp_camera()

func _gen_config() -> Dictionary:
	return {
		"mountain_clusters": mountain_clusters,
		"mountain_per_cluster": mountain_per_cluster,
		"mountain_spread": mountain_spread,
		"pond_count": pond_count,
		"tree_density": tree_density, "boulder_density": boulder_density,
		"grass_density": grass_density, "pebble_density": pebble_density,
	}

# Rebuilds the whole world at a new size + seed (placed buildings/roads live in
# `world`, so they reset too) and redraws every layer. Driven by the Settings dialog.
func regenerate_map(p_cols: int, p_rows: int, p_seed: int) -> void:
	exit_build_mode()
	clear_selection()
	cols = p_cols
	rows = p_rows
	world_seed = p_seed
	world = WorldData.generate(world_seed, cols, rows, _gen_config())
	_setup_camera()
	queue_redraw()
	for c in get_children():
		if c is CanvasItem:
			c.queue_redraw()

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
	if not _pan_enabled:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _dragging:
		_pan(event.relative)
		_drag_moved += event.relative.length()
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

## Lets a modal (e.g. the dialog) freeze map pan/zoom/tap while it's open.
func set_pan_enabled(value: bool) -> void:
	_pan_enabled = value
	if not value:
		_dragging = false
		_touches.clear()
		_pinch_dist = 0.0

## The UI marks the open bottom sheet's screen rect so gestures over the panel are
## swallowed instead of moving the map. Pass an empty Rect2 to clear it.
func set_ui_block_rect(r: Rect2) -> void:
	_ui_block_rect = r

func _in_block(pos: Vector2) -> bool:
	return _ui_block_rect.has_point(pos)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		if _in_block(event.position):
			return
		_zoom_at(event.position, zoom_step)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		if _in_block(event.position):
			return
		_zoom_at(event.position, 1.0 / zoom_step)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _in_block(event.position):
				_mouse_blocked = true
				return
			_mouse_blocked = false
			_dragging = true
			_drag_moved = 0.0
		else:
			if _mouse_blocked:
				_mouse_blocked = false
				return
			_dragging = false
			if _drag_moved < tap_threshold:
				_tap_at(_screen_to_world(event.position))

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _in_block(event.position):
			_blocked_touches[event.index] = true
			return
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_drag_moved = 0.0
	else:
		if _blocked_touches.has(event.index):
			_blocked_touches.erase(event.index)
			return
		var was_last := _touches.size() <= 1
		_touches.erase(event.index)
		if was_last and _drag_moved < tap_threshold:
			_tap_at(_screen_to_world(event.position))
		if _touches.size() < 2:
			_pinch_dist = 0.0

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if _blocked_touches.has(event.index):
		return
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
	# Allow panning `pan_overscroll` screens past the top & bottom edges, so tiles
	# behind the top bar / bottom sheet can be scrolled into view.
	var over_y := get_viewport().get_visible_rect().size.y * pan_overscroll / _camera.zoom.y
	pos.y = ms.y * 0.5 if half.y * 2.0 >= ms.y else clampf(pos.y, half.y - over_y, ms.y - half.y + over_y)
	_camera.position = pos

func _select_at(world_pos: Vector2) -> void:
	var ms := _map_size()
	if world_pos.x < 0.0 or world_pos.y < 0.0 or world_pos.x >= ms.x or world_pos.y >= ms.y:
		return
	var tx := int(world_pos.x / cell_size)
	var ty := int(world_pos.y / cell_size)
	print("[map] tile pressed (%d,%d)" % [tx, ty])
	tile_selected.emit(tx, ty)

func clear_selection() -> void:
	tile_deselected.emit()

# --- Build mode (placement) -----------------------------------------------------

# A tap either repositions the build ghost (build mode) or selects a tile.
func _tap_at(world_pos: Vector2) -> void:
	if build_active:
		var c := _world_to_cell(world_pos)
		if c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows:
			_set_ghost(c)
		return
	_select_at(world_pos)

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / cell_size)), int(floor(world_pos.y / cell_size)))

# Enters build mode with `entry` (a catalog dict). The ghost starts on `start_cell`
# (e.g. the tile the player tapped), or the screen centre if none is given.
func enter_build_mode(entry: Dictionary, start_cell := Vector2i(-1, -1)) -> void:
	build_active = true
	build_entry = entry
	var cell := start_cell
	if cell.x < 0:
		cell = _world_to_cell(_screen_to_world(get_viewport().get_visible_rect().size * 0.5))
	_set_ghost(cell)

# Swaps the building type without moving the ghost (cycling in the build bar).
func set_build_entry(entry: Dictionary) -> void:
	build_entry = entry
	_recompute_valid()
	build_changed.emit()

func exit_build_mode() -> void:
	build_active = false
	build_entry = {}
	build_ghost = Vector2i(-1, -1)
	build_changed.emit()

# Places the current building at the ghost cell if valid, staying in build mode so
# the player can place more (the ghost re-validates — its cell is now occupied).
func confirm_build() -> bool:
	if not build_active or not build_valid:
		return false
	var ok := world.place_building(build_entry.id, build_ghost, build_entry.size)
	if ok:
		_recompute_valid()
		build_changed.emit()
	return ok

func _set_ghost(cell: Vector2i) -> void:
	build_ghost = cell
	_recompute_valid()
	build_changed.emit()

# Valid = footprint placeable, plus terrain adjacency for extractors (`requires`).
func _recompute_valid() -> void:
	if not build_active or build_entry.is_empty():
		build_valid = false
		return
	var size: Vector2i = build_entry.size
	var ok := world.can_place(build_ghost, size)
	if ok and String(build_entry.requires) != "":
		ok = world.is_adjacent_to_terrain(build_ghost, size, build_entry.requires)
	build_valid = ok
