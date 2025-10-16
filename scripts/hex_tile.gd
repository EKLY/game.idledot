extends Node2D
class_name HexTile

# Hexagonal tile representation
# Uses axial coordinates (q, r) for hex positioning

signal tile_clicked(tile)
signal tile_hovered(tile)

# Axial coordinates
var q: int = 0
var r: int = 0

# Cube coordinates (derived from axial)
var cube_x: int:
	get:
		return q
var cube_y: int:
	get:
		return -q - r
var cube_z: int:
	get:
		return r

# Tile properties
var terrain_type: int = Buildings.TerrainType.EMPTY
var building: Node = null
var is_selected: bool = false
var is_highlighted: bool = false

# Visual properties
var hex_size: float = 32.0
var color_normal: Color = Color.WHITE
var color_hover: Color = Color(1.0, 1.0, 0.8)
var color_selected: Color = Color(1.0, 0.8, 0.0)

# Terrain colors
const TERRAIN_COLORS = {
	0: Color(0.8, 0.8, 0.8),  # EMPTY - Gray
	1: Color(0.5, 0.4, 0.3),  # MOUNTAIN - Brown
	2: Color(0.4, 0.7, 0.3),  # FARMLAND - Green
	3: Color(0.3, 0.5, 0.9)   # WATER - Blue
}

# Neighbors (cached)
var neighbors: Array = []

# Node references (set manually or via @onready)
var polygon: Polygon2D = null
var collision_shape: CollisionPolygon2D = null
var area_2d: Area2D = null

func _ready():
	# Get node references if not already set
	if not polygon:
		polygon = get_node_or_null("Polygon2D")
	if not area_2d:
		area_2d = get_node_or_null("Area2D")
	if not collision_shape and area_2d:
		collision_shape = area_2d.get_node_or_null("CollisionPolygon2D")

	_setup_hex_shape()
	_update_visual()

	# Connect area signals
	if area_2d:
		area_2d.mouse_entered.connect(_on_mouse_entered)
		area_2d.mouse_exited.connect(_on_mouse_exited)
		area_2d.input_event.connect(_on_input_event)

# Initialize tile with coordinates and terrain
func init(q_coord: int, r_coord: int, terrain: int):
	q = q_coord
	r = r_coord
	terrain_type = terrain

	# Get node references if not already set
	if not polygon:
		polygon = get_node_or_null("Polygon2D")
	if not area_2d:
		area_2d = get_node_or_null("Area2D")
	if not collision_shape and area_2d:
		collision_shape = area_2d.get_node_or_null("CollisionPolygon2D")

	# Setup visuals
	_setup_hex_shape()
	_update_visual()

# Setup hexagon shape
func _setup_hex_shape():
	var points = _get_hex_corners()

	if polygon:
		polygon.polygon = points

	if collision_shape:
		collision_shape.polygon = points

# Get hexagon corner points (flat-top orientation)
func _get_hex_corners() -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var x = hex_size * cos(angle_rad)
		var y = hex_size * sin(angle_rad)
		corners.append(Vector2(x, y))
	return corners

# Update visual appearance
func _update_visual():
	if not polygon:
		return

	# Set base color based on terrain
	var base_color = TERRAIN_COLORS.get(terrain_type, Color.WHITE)

	# Apply state modifications
	if is_selected:
		polygon.color = color_selected
	elif is_highlighted:
		polygon.color = color_hover
	else:
		polygon.color = base_color

	# Add black border for visibility
	polygon.texture = null
	polygon.antialiased = true

# Highlight tile
func highlight():
	is_highlighted = true
	_update_visual()

# Remove highlight
func unhighlight():
	is_highlighted = false
	_update_visual()

# Select tile
func select():
	is_selected = true
	_update_visual()

# Deselect tile
func deselect():
	is_selected = false
	_update_visual()

# Check if tile can have building placed
func can_build() -> bool:
	return building == null

# Place building on tile
func place_building(new_building: Node):
	if not can_build():
		return false

	building = new_building
	add_child(building)
	return true

# Remove building from tile
func remove_building():
	if building:
		remove_child(building)
		building.queue_free()
		building = null

# Get world position from hex coordinates (flat-top)
static func hex_to_pixel(q: int, r: int, size: float) -> Vector2:
	var x = size * (3.0/2.0 * q)
	var y = size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	return Vector2(x, y)

# Convert pixel position to hex coordinates
static func pixel_to_hex(pos: Vector2, size: float) -> Vector2i:
	var q = (2.0/3.0 * pos.x) / size
	var r = (-1.0/3.0 * pos.x + sqrt(3.0)/3.0 * pos.y) / size
	return _round_hex(q, r)

# Round fractional hex coordinates to nearest hex
static func _round_hex(q: float, r: float) -> Vector2i:
	var x = q
	var z = r
	var y = -x - z

	var rx = round(x)
	var ry = round(y)
	var rz = round(z)

	var x_diff = abs(rx - x)
	var y_diff = abs(ry - y)
	var z_diff = abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(int(rx), int(rz))

# Get distance to another tile
func distance_to(other: HexTile) -> int:
	return (abs(q - other.q) + abs(r - other.r) + abs(cube_y - other.cube_y)) / 2

# Touch/tap detection
var touch_start_pos: Vector2 = Vector2.ZERO
var is_touch_started: bool = false
const TAP_THRESHOLD: float = 20.0  # Maximum movement to count as tap

# Input handlers
func _on_mouse_entered():
	if not is_selected:
		highlight()
	tile_hovered.emit(self)

func _on_mouse_exited():
	if not is_selected:
		unhighlight()

func _on_input_event(_viewport, event, _shape_idx):
	# Handle mouse click (for desktop testing)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(self)

	# Handle touch tap (for mobile)
	elif event is InputEventScreenTouch:
		if event.pressed:
			is_touch_started = true
			touch_start_pos = event.position
		elif is_touch_started:
			# Check if this is a tap (minimal movement)
			var distance = touch_start_pos.distance_to(event.position)
			if distance < TAP_THRESHOLD:
				tile_clicked.emit(self)
			is_touch_started = false

# Get string representation (override for debugging)
func _to_string() -> String:
	return "HexTile(%d, %d) - %s" % [q, r, Buildings.TerrainType.keys()[terrain_type]]
