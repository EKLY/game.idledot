extends Node2D
class_name TileDecorator

## Draws the grass / pebble scatter recorded in the parent Map's `world`
## (WorldData). Which cells get what is decided by the world generator; this node
## only reads `cell_kind` and draws the look, deriving each tuft's detail by
## hashing the cell. Cached & redrawn only when the world changes. Child of Map.

@export var decorate: bool = true:
	set(value):
		decorate = value
		queue_redraw()
# Overall size of grass tufts relative to a cell.
@export_range(0.2, 1.5) var grass_scale: float = 0.7:
	set(value):
		grass_scale = value
		queue_redraw()
# Default map decorations stay monochrome (grid-line tone, 6f6453); only
# player-built structures will get colour later.
@export var grass_color: Color = Color(0.435, 0.392, 0.325, 0.7)
@export var grass_width: float = 0.3:
	set(value):
		grass_width = value
		queue_redraw()
@export var pebble_color: Color = Color(0.435, 0.392, 0.325, 0.3)
@export var pebble_edge_color: Color = Color(0.435, 0.392, 0.325, 0.75)
@export var pebble_edge_width: float = 0.3:
	set(value):
		pebble_edge_width = value
		queue_redraw()

func _draw() -> void:
	if not decorate:
		return
	var world: WorldData = get_parent().world
	if world == null:
		return
	var cell_size: int = get_parent().cell_size
	for y in range(world.rows):
		for x in range(world.cols):
			match world.cell_kind[y * world.cols + x]:
				WorldData.Kind.GRASS:
					_draw_grass(x, y, cell_size)
				WorldData.Kind.PEBBLE:
					_draw_pebble(x, y, cell_size)

# A fan-shaped tuft: blades radiate from one base point, the centre blade tallest
# and the side ones shorter, each bowing slightly outward.
func _draw_grass(x: int, y: int, cell_size: int) -> void:
	var cs := float(cell_size)
	var origin := Vector2(x * cell_size, y * cell_size)
	var base := origin + Vector2(cs * (0.2 + 0.6 * _rand01(x, y, 11)), cs * (0.45 + 0.4 * _rand01(x, y, 12)))
	var blades := 5 + int(_rand01(x, y, 13) * 3.0)
	var spread := deg_to_rad(55.0)
	for b in range(blades):
		var t := float(b) / float(blades - 1)
		var ang := lerpf(-spread, spread, t) + (_rand01(x, y, 20 + b) - 0.5) * 0.15
		var h := cs * grass_scale * (0.3 + 0.18 * _rand01(x, y, 30 + b)) * (0.6 + 0.4 * sin(t * PI))
		var dir := Vector2(sin(ang), -cos(ang))
		var perp := Vector2(dir.y, -dir.x)
		var tip := base + dir * h
		var mid := base + dir * (h * 0.5) + perp * ((t - 0.5) * h * 0.3)
		draw_polyline(PackedVector2Array([base, mid, tip]), grass_color, grass_width, true)

func _draw_pebble(x: int, y: int, cell_size: int) -> void:
	var cs := float(cell_size)
	var origin := Vector2(x * cell_size, y * cell_size)
	var c := origin + Vector2(cs * (0.18 + 0.64 * _rand01(x, y, 41)), cs * (0.2 + 0.6 * _rand01(x, y, 42)))
	var rad := cs * (0.07 + 0.05 * _rand01(x, y, 43))
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0
		var rr := rad * (0.75 + 0.45 * _rand01(x, y, 50 + i))
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, pebble_color)
	pts.append(pts[0])
	draw_polyline(pts, pebble_edge_color, pebble_edge_width, true)

# Deterministic per-cell pseudo-random in [0, 1) from the cell coords + a salt.
func _rand01(x: int, y: int, salt: int) -> float:
	return float(hash(Vector3i(x, y, salt)) & 0xFFFFFF) / float(0x1000000)
