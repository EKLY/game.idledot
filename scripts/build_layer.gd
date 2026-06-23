extends Node2D
class_name BuildLayer

## Draws player-placed buildings as flat coloured rounded rects (placeholder),
## plus the build-mode ghost preview tinted valid/invalid. Child of Map, sitting
## between Terrain and Selection. Colour + size come from the catalog (by id).
## Keep the per-footprint drawing in `_draw_footprint` so swapping to a sprite
## (`draw_texture`) later is a one-spot change.

@export var inset: float = 2.0
@export var corner_radius: float = 5.0
@export var edge_color: Color = Color(0.18, 0.16, 0.12, 0.85)
@export var edge_width: float = 1.5
@export var ghost_valid_color: Color = Color(0.36, 0.82, 0.46, 0.55)
@export var ghost_invalid_color: Color = Color(0.92, 0.35, 0.3, 0.55)

@onready var _map: Node2D = get_parent()

func _ready() -> void:
	_map.build_changed.connect(queue_redraw)

func _draw() -> void:
	var world: WorldData = _map.world
	if world == null:
		return
	var cs: int = _map.cell_size
	# Placed buildings (read their colour from the catalog by id).
	for b in world.buildings:
		var entry: Dictionary = _map.catalog_by_id.get(b.type, {})
		var col: Color = entry.get("color", Color.WHITE)
		_draw_footprint(b.origin, b.size, cs, col)
	# Ghost preview while building.
	if _map.build_active and not _map.build_entry.is_empty() and _map.build_ghost.x >= 0:
		var tint: Color = ghost_valid_color if _map.build_valid else ghost_invalid_color
		_draw_footprint(_map.build_ghost, _map.build_entry.size, cs, tint, false)

# Draws one w×h footprint. `outline` adds the graphite edge (placed buildings);
# the ghost skips it so the tint reads as a flat swatch.
func _draw_footprint(origin: Vector2i, size: Vector2i, cs: int, color: Color, outline: bool = true) -> void:
	var rect := Rect2(Vector2(origin.x * cs, origin.y * cs), Vector2(size.x * cs, size.y * cs)).grow(-inset)
	var pts := _rounded_rect(rect, corner_radius)
	draw_colored_polygon(pts, color)
	if outline:
		var loop := pts
		loop.append(pts[0])
		draw_polyline(loop, edge_color, edge_width, true)

# Perimeter of a rounded rectangle as a point loop (5 steps per corner).
func _rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
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
	_arc(pts, c_tl, rad, PI, PI * 1.5)
	_arc(pts, c_tr, rad, PI * 1.5, TAU)
	_arc(pts, c_br, rad, 0.0, PI * 0.5)
	_arc(pts, c_bl, rad, PI * 0.5, PI)
	return pts

func _arc(pts: PackedVector2Array, center: Vector2, radius: float, from_a: float, to_a: float) -> void:
	var steps := 5
	for i in range(steps + 1):
		var a := lerpf(from_a, to_a, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
