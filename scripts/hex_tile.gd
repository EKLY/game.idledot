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
var terrain_variation: int = 0  # 0-3 for sprite variations
var object_type: String = ""  # Object ID (e.g., "mountain", "tree")
var building: Node = null
var is_selected: bool = false
var is_highlighted: bool = false

# Visual properties
var hex_size: float = 32.0
var perspective_scale: float = 0.5  # Y-axis scale for pseudo-3D perspective (0.5 = easy calculation)
var color_normal: Color = Color.WHITE
var color_hover: Color = Color(1.0, 1.0, 0.8)
var color_selected: Color = Color(1.0, 0.8, 0.0)

# Terrain colors
const TERRAIN_COLORS = {
	0: Color(0.8, 0.8, 0.8),   # EMPTY - Gray
	1: Color(0.4, 0.7, 0.3),   # FIELD - Green
	2: Color(0.9, 0.8, 0.5),   # SAND - Yellow
	3: Color(0.3, 0.5, 0.9),   # WATER - Blue
	4: Color(0.95, 0.95, 1.0), # SNOW - White
	5: Color(0.83, 0.18, 0.18) # VOLCANIC - Red (ลาวา/ความร้อนใต้ดิน)
}

# Neighbors (cached)
var neighbors: Array = []

# Node references (set manually or via @onready)
var polygon: Polygon2D = null
var collision_shape: CollisionPolygon2D = null
var area_2d: Area2D = null
var terrain_sprite: Sprite2D = null  # For terrain texture
var object_sprite: Sprite2D = null   # For object sprite (mountain, tree, etc.)
var building_sprite: Sprite2D = null  # For building sprite

func _ready():
	# Get node references if not already set
	if not polygon:
		polygon = get_node_or_null("Polygon2D")
	if not area_2d:
		area_2d = get_node_or_null("Area2D")
	if not collision_shape and area_2d:
		collision_shape = area_2d.get_node_or_null("CollisionPolygon2D")
	if not terrain_sprite:
		terrain_sprite = get_node_or_null("TerrainSprite")
	if not object_sprite:
		object_sprite = get_node_or_null("ObjectSprite")
	if not building_sprite:
		building_sprite = get_node_or_null("BuildingSprite")

	_setup_hex_shape()
	_update_visual()

	# Connect area signals
	if area_2d:
		area_2d.mouse_entered.connect(_on_mouse_entered)
		area_2d.mouse_exited.connect(_on_mouse_exited)
		area_2d.input_event.connect(_on_input_event)

# Initialize tile with coordinates and terrain
func init(q_coord: int, r_coord: int, terrain: int, variation: int = 0, obj_type: String = ""):
	q = q_coord
	r = r_coord
	terrain_type = terrain
	terrain_variation = variation  # Store sprite variation (0-3)
	object_type = obj_type  # Store object type (e.g., "mountain", "tree")

	# Get node references if not already set
	if not polygon:
		polygon = get_node_or_null("Polygon2D")
	if not area_2d:
		area_2d = get_node_or_null("Area2D")
	if not collision_shape and area_2d:
		collision_shape = area_2d.get_node_or_null("CollisionPolygon2D")
	if not terrain_sprite:
		terrain_sprite = get_node_or_null("TerrainSprite")
	if not object_sprite:
		object_sprite = get_node_or_null("ObjectSprite")
	if not building_sprite:
		building_sprite = get_node_or_null("BuildingSprite")

	# Setup visuals
	_setup_hex_shape()
	_load_terrain_sprite()
	_load_object_sprite()
	_update_visual()

# Setup hexagon shape
func _setup_hex_shape():
	var points = _get_hex_corners()

	if polygon:
		polygon.polygon = points

	if collision_shape:
		collision_shape.polygon = points

# Get hexagon corner points (flat-top orientation with perspective)
func _get_hex_corners() -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60.0 * i
		var angle_rad = deg_to_rad(angle_deg)
		var x = hex_size * cos(angle_rad)
		var y = hex_size * sin(angle_rad) * perspective_scale  # Apply perspective scale
		corners.append(Vector2(x, y))
	return corners

# Load terrain sprite based on terrain type
func _load_terrain_sprite():
	if not terrain_sprite:
		return

	# Define terrain type names
	const TERRAIN_NAMES = {
		0: "empty",
		1: "field",
		2: "sand",
		3: "water",
		4: "snow",
		5: "volcanic"
	}

	# Build sprite path with variation: terrain_farmland-0.png
	var terrain_name = TERRAIN_NAMES.get(terrain_type, "")
	if terrain_name.is_empty():
		# Unknown terrain type
		terrain_sprite.visible = false
		if polygon:
			polygon.visible = true
		return

	var sprite_path = "res://assets/sprites/terrain_%s-%d.png" % [terrain_name, terrain_variation]

	# If variation sprite doesn't exist, try fallback without variation
	if not ResourceLoader.exists(sprite_path):
		sprite_path = "res://assets/sprites/terrain_%s.png" % terrain_name

	if not ResourceLoader.exists(sprite_path):
		# If sprite doesn't exist, hide sprite and show colored polygon
		terrain_sprite.visible = false
		if polygon:
			polygon.visible = true
		return

	# Load and display sprite
	var texture = load(sprite_path)
	if texture:
		terrain_sprite.texture = texture
		terrain_sprite.visible = true

		# Scale sprite to fit hex size
		# Terrain sprite is 256x128 px (width x height)
		# Flat-top hexagon dimensions:
		# - Width = hex_size * 2
		# - Height = sqrt(3) * hex_size * perspective_scale
		var hex_width = hex_size * 2.0
		var hex_height = sqrt(3.0) * hex_size * perspective_scale

		var sprite_scale_x = hex_width / 256.0
		var sprite_scale_y = hex_height / 128.0
		terrain_sprite.scale = Vector2(sprite_scale_x, sprite_scale_y)

		# Hide polygon when sprite is shown (or make it semi-transparent)
		if polygon:
			polygon.modulate.a = 0.3  # Make polygon semi-transparent under sprite

# Load object sprite based on object type
func _load_object_sprite():
	if not object_sprite:
		return

	# If no object type, hide sprite
	if object_type.is_empty():
		object_sprite.visible = false
		return

	# Get object sprite filename from Buildings autoload
	var sprite_filename = Buildings.get_object_sprite(object_type)
	if sprite_filename.is_empty():
		object_sprite.visible = false
		return

	# Build full path
	var sprite_path = "res://assets/sprites/" + sprite_filename

	if not ResourceLoader.exists(sprite_path):
		# Hide object sprite if not found
		object_sprite.visible = false
		return

	# Load and display sprite
	var texture = load(sprite_path)
	if texture:
		object_sprite.texture = texture
		object_sprite.visible = true

		# Scale sprite to fit hex size
		# Object sprite is 256x256 px (standard size)
		# We want it to fit within the hex tile
		var hex_width = hex_size * 2.0
		var sprite_scale = hex_width / 256.0
		object_sprite.scale = Vector2(sprite_scale, sprite_scale)

		# Position object sprite with bottom-center alignment
		# Align bottom of object (256px) to bottom of terrain (128px height)
		var terrain_half_height = 128.0 * sprite_scale * 0.5  # Half of terrain height
		var object_half_height = 256.0 * sprite_scale * 0.5   # Half of object height
		object_sprite.position = Vector2(0, -(object_half_height - terrain_half_height))

		# Set z-index to be above terrain but below buildings
		object_sprite.z_index = 2

# Update visual appearance
func _update_visual():
	if not polygon:
		return

	# Set base color based on terrain
	var base_color = TERRAIN_COLORS.get(terrain_type, Color.WHITE)

	# Apply state modifications
	if is_selected:
		polygon.color = color_selected
		# Highlight sprite too
		if terrain_sprite and terrain_sprite.visible:
			terrain_sprite.modulate = Color(1.0, 1.0, 0.7)  # Yellowish tint
	elif is_highlighted:
		polygon.color = color_hover
		if terrain_sprite and terrain_sprite.visible:
			terrain_sprite.modulate = Color(1.2, 1.2, 1.0)  # Bright tint
	else:
		polygon.color = base_color
		if terrain_sprite and terrain_sprite.visible:
			terrain_sprite.modulate = Color.WHITE  # Normal

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
	is_highlighted = false  # Clear highlight state when deselected
	_update_visual()

# Check if tile can have building placed
func can_build() -> bool:
	return building == null

# Set object on tile
func set_object(obj_type: String):
	object_type = obj_type
	_load_object_sprite()

# Remove object from tile
func remove_object():
	object_type = ""
	if object_sprite:
		object_sprite.visible = false

# Check if tile has object
func has_object() -> bool:
	return not object_type.is_empty()

# Get buildable buildings on this object
func get_buildable_buildings() -> Array:
	if object_type.is_empty():
		return []
	return Buildings.get_buildable_on_object(object_type)

# Place building on tile
func place_building(new_building: Node):
	if not can_build():
		return false

	building = new_building
	add_child(building)
	_load_building_sprite()
	return true

# Load building sprite
func _load_building_sprite():
	if not building or not building_sprite:
		return

	# Try to load building sprite based on building_id
	var building_id = building.building_id if "building_id" in building else ""
	if building_id.is_empty():
		return

	var sprite_path = "res://assets/sprites/building_%s.png" % building_id
	if not ResourceLoader.exists(sprite_path):
		# Hide building sprite if not found
		building_sprite.visible = false
		return

	var texture = load(sprite_path)
	if texture:
		building_sprite.texture = texture
		building_sprite.visible = true

		# Scale sprite to fit hex size (256px standard -> hex_size * 2)
		var sprite_scale = (hex_size * 2.0) / 256.0
		building_sprite.scale = Vector2(sprite_scale, sprite_scale)

		# Position building sprite with bottom-center alignment
		# Building sprite (256x256) aligned to bottom of terrain sprite (256x128)
		var terrain_half_height = 128.0 * sprite_scale * 0.5  # Half of terrain height
		var building_half_height = 256.0 * sprite_scale * 0.5  # Half of building height
		building_sprite.position = Vector2(0, -(building_half_height - terrain_half_height))

# Remove building from tile
func remove_building():
	if building:
		remove_child(building)
		building.queue_free()
		building = null

	# Hide building sprite
	if building_sprite:
		building_sprite.visible = false

# Get world position from hex coordinates (flat-top with perspective)
static func hex_to_pixel(q: int, r: int, size: float, perspective: float = 0.5) -> Vector2:
	var x = size * (3.0/2.0 * q)
	var y = size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r) * perspective  # Apply perspective
	return Vector2(x, y)

# Convert pixel position to hex coordinates (adjusted for perspective)
static func pixel_to_hex(pos: Vector2, size: float, perspective: float = 0.5) -> Vector2i:
	# Adjust y position for perspective
	var adjusted_y = pos.y / perspective
	var q = (2.0/3.0 * pos.x) / size
	var r = (-1.0/3.0 * pos.x + sqrt(3.0)/3.0 * adjusted_y) / size
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
