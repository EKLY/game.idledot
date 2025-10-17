extends Node
class_name HexGridManager

# Manages the hexagonal grid system
# Handles grid creation, tile management, and hex math

signal tile_selected(tile: HexTile)
signal tile_deselected(tile: HexTile)

# Grid properties
var grid_width: int = 8   # Horizontal radius (q-axis)
var grid_height: int = 24  # Vertical radius (r-axis) - 3x taller for portrait mode
var hex_size: float = 60.0  # Larger for mobile touch

# Terrain generation percentages (must sum to 100)
@export_range(0, 100) var terrain_empty_percent: float = 20.0
@export_range(0, 100) var terrain_field_percent: float = 25.0
@export_range(0, 100) var terrain_sand_percent: float = 20.0
@export_range(0, 100) var terrain_water_percent: float = 25.0
@export_range(0, 100) var terrain_snow_percent: float = 8.0
@export_range(0, 100) var terrain_volcanic_percent: float = 2.0

# Grid data
var tiles: Dictionary = {}  # {Vector2i(q, r): HexTile}
var selected_tile: HexTile = null

# Scene references
var tile_container: Node2D = null

# Noise for terrain generation
var noise: FastNoiseLite = FastNoiseLite.new()

# Weighted random for terrain distribution
var terrain_weights: Array[float] = []
var terrain_types: Array[int] = []

# Noise value cache for percentile-based distribution
var noise_cache: Dictionary = {}  # {Vector2i(q,r): float}
var sorted_noise_values: Array[float] = []

func _ready():
	_setup_noise()
	_setup_terrain_weights()

# Setup noise for terrain generation
func _setup_noise():
	noise.seed = randi()
	noise.frequency = 0.04  # Lower frequency = larger clusters
	noise.fractal_octaves = 3  # More octaves = more natural looking
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH  # Smoother transitions

# Setup weighted terrain distribution
func _setup_terrain_weights():
	terrain_types = [
		Buildings.TerrainType.EMPTY,
		Buildings.TerrainType.FIELD,
		Buildings.TerrainType.SAND,
		Buildings.TerrainType.WATER,
		Buildings.TerrainType.SNOW,
		Buildings.TerrainType.VOLCANIC
	]

	terrain_weights = [
		terrain_empty_percent,
		terrain_field_percent,
		terrain_sand_percent,
		terrain_water_percent,
		terrain_snow_percent,
		terrain_volcanic_percent
	]

# Create the hex grid (hexagonal ellipse shape - taller for portrait mode)
func create_grid(container: Node2D):
	tile_container = container

	print("Creating hexagonal grid: %d (w) x %d (h)" % [grid_width, grid_height])

	# PASS 1: Generate and cache all noise values
	noise_cache.clear()
	sorted_noise_values.clear()

	for q in range(-grid_width, grid_width + 1):
		for r in range(-grid_height, grid_height + 1):
			var s = -q - r  # Third cube coordinate

			if abs(q) <= grid_width and abs(r) <= grid_height and abs(s) <= max(grid_width, grid_height):
				var noise_val = noise.get_noise_2d(float(q), float(r))
				noise_cache[Vector2i(q, r)] = noise_val
				sorted_noise_values.append(noise_val)

	# Sort noise values for percentile calculation
	sorted_noise_values.sort()

	print("Generated %d noise values" % sorted_noise_values.size())

	# PASS 2: Create tiles with terrain assigned by percentile
	var tile_count = 0
	for q in range(-grid_width, grid_width + 1):
		for r in range(-grid_height, grid_height + 1):
			var s = -q - r

			if abs(q) <= grid_width and abs(r) <= grid_height and abs(s) <= max(grid_width, grid_height):
				_create_tile(q, r)
				tile_count += 1

	print("Created %d tiles in hexagonal ellipse shape" % tile_count)

# Create a single hex tile
func _create_tile(q: int, r: int):
	# Create tile node with required children
	var tile = HexTile.new()
	tile.hex_size = hex_size

	# Create Polygon2D for visual (base color)
	var polygon = Polygon2D.new()
	polygon.name = "Polygon2D"
	tile.add_child(polygon)

	# Create Sprite2D for terrain texture
	var terrain_sprite = Sprite2D.new()
	terrain_sprite.name = "TerrainSprite"
	terrain_sprite.centered = true
	terrain_sprite.z_index = 1  # Above polygon
	tile.add_child(terrain_sprite)

	# Create Sprite2D for object sprite (mountain, tree, etc.)
	var object_sprite = Sprite2D.new()
	object_sprite.name = "ObjectSprite"
	object_sprite.centered = true
	object_sprite.z_index = 2  # Above terrain, below buildings
	object_sprite.visible = false  # Hidden by default
	tile.add_child(object_sprite)

	# Create Sprite2D for building sprite
	var building_sprite = Sprite2D.new()
	building_sprite.name = "BuildingSprite"
	building_sprite.centered = true
	building_sprite.z_index = 3  # Above objects
	building_sprite.visible = false  # Hidden by default
	tile.add_child(building_sprite)

	# Create Area2D for mouse interaction
	var area = Area2D.new()
	area.name = "Area2D"
	tile.add_child(area)

	# Create CollisionPolygon2D for Area2D
	var collision = CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	area.add_child(collision)

	# Generate terrain type
	var terrain = _generate_terrain(q, r)

	# Generate random sprite variation (0-3)
	var variation = randi() % 4

	# Generate random object based on terrain
	var object_type = _generate_object(terrain)

	# Add to container first (before init to ensure nodes are in tree)
	if tile_container:
		tile_container.add_child(tile)

	# Initialize tile (this will setup hex shape and visuals)
	tile.init(q, r, terrain, variation, object_type)

	# Set position (with perspective scale)
	var pos = HexTile.hex_to_pixel(q, r, hex_size, tile.perspective_scale)
	tile.position = pos

	# Store tile
	tiles[Vector2i(q, r)] = tile

	# Connect signals
	tile.tile_clicked.connect(_on_tile_clicked)

	return tile

# Generate object type based on terrain and spawn chances
func _generate_object(terrain: int) -> String:
	# Get all objects that can spawn on this terrain
	var possible_objects = Buildings.get_objects_for_terrain(terrain)

	if possible_objects.is_empty():
		return ""  # No objects for this terrain

	# Roll for each object with its spawn chance
	for object_id in possible_objects:
		var spawn_chance = Buildings.get_object_spawn_chance(object_id, terrain)
		var roll = randf()  # Random float between 0.0 and 1.0

		if roll < spawn_chance:
			return object_id  # Spawn this object

	return ""  # No object spawned

# Generate terrain type using percentile-based distribution for accurate percentages
func _generate_terrain(q: int, r: int) -> int:
	# Get cached noise value
	var coord = Vector2i(q, r)
	var noise_val = noise_cache.get(coord, 0.0)

	# Find percentile rank of this noise value
	var rank = sorted_noise_values.bsearch(noise_val)
	var total = sorted_noise_values.size()
	var percentile = (float(rank) / float(total)) * 100.0

	# Map percentile to terrain types based on exact percentages
	# This guarantees accurate distribution while maintaining clustering
	var cumulative = 0.0

	cumulative += terrain_empty_percent
	if percentile < cumulative:
		return Buildings.TerrainType.EMPTY

	cumulative += terrain_field_percent
	if percentile < cumulative:
		return Buildings.TerrainType.FIELD

	cumulative += terrain_sand_percent
	if percentile < cumulative:
		return Buildings.TerrainType.SAND

	cumulative += terrain_water_percent
	if percentile < cumulative:
		return Buildings.TerrainType.WATER

	cumulative += terrain_snow_percent
	if percentile < cumulative:
		return Buildings.TerrainType.SNOW

	# Remaining is volcanic
	return Buildings.TerrainType.VOLCANIC

# Get tile at coordinates
func get_tile_at(q: int, r: int) -> HexTile:
	return tiles.get(Vector2i(q, r), null)

# Get tile at world position
func get_tile_at_position(world_pos: Vector2) -> HexTile:
	var hex_coords = HexTile.pixel_to_hex(world_pos, hex_size, 0.5)  # Use same perspective
	return get_tile_at(hex_coords.x, hex_coords.y)

# Get neighbors of a tile
func get_neighbors(tile: HexTile) -> Array[HexTile]:
	var neighbors: Array[HexTile] = []

	# Axial direction vectors for flat-top hexagons
	const DIRECTIONS = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]

	for dir in DIRECTIONS:
		var neighbor_coord = Vector2i(tile.q + dir.x, tile.r + dir.y)
		var neighbor = tiles.get(neighbor_coord, null)
		if neighbor:
			neighbors.append(neighbor)

	return neighbors

# Select a tile
func select_tile(tile: HexTile):
	if selected_tile == tile:
		return

	# Deselect previous
	if selected_tile:
		selected_tile.deselect()
		tile_deselected.emit(selected_tile)

	# Select new
	selected_tile = tile
	if selected_tile:
		selected_tile.select()
		tile_selected.emit(selected_tile)

# Deselect current tile
func deselect_current_tile():
	if selected_tile:
		selected_tile.deselect()
		tile_deselected.emit(selected_tile)
		selected_tile = null

# Find path between two tiles using A*
func find_path(start: HexTile, end: HexTile) -> Array[HexTile]:
	if not start or not end:
		return []

	var open_set: Array[HexTile] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: start.distance_to(end)}

	while open_set.size() > 0:
		# Get tile with lowest f_score
		var current = open_set[0]
		for tile in open_set:
			if f_score.get(tile, INF) < f_score.get(current, INF):
				current = tile

		if current == end:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			# Skip tiles with non-road buildings (except start and end)
			if neighbor != start and neighbor != end:
				if neighbor.building and not neighbor.building is Road:
					continue

			var tentative_g_score = g_score.get(current, INF) + 1

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + neighbor.distance_to(end)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []  # No path found

# Reconstruct path from A* result
func _reconstruct_path(came_from: Dictionary, current: HexTile) -> Array[HexTile]:
	var path: Array[HexTile] = [current]
	while current in came_from:
		current = came_from[current]
		path.insert(0, current)
	return path

# Get all tiles
func get_all_tiles() -> Array:
	return tiles.values()

# Handle tile click
func _on_tile_clicked(tile: HexTile):
	select_tile(tile)

# Get grid dimensions
func get_grid_width() -> int:
	return grid_width

func get_grid_height() -> int:
	return grid_height

# Legacy function for compatibility
func get_grid_radius() -> int:
	return max(grid_width, grid_height)

# Clear grid
func clear_grid():
	for tile in tiles.values():
		if tile:
			tile.queue_free()
	tiles.clear()
	selected_tile = null
