extends Node
class_name HexGridManager

# Manages the hexagonal grid system
# Handles grid creation, tile management, and hex math

signal tile_selected(tile: HexTile)
signal tile_deselected(tile: HexTile)

# Grid properties
var grid_width: int = 10
var grid_height: int = 14
var hex_size: float = 60.0  # Larger for mobile touch

# Grid data
var tiles: Dictionary = {}  # {Vector2i(q, r): HexTile}
var selected_tile: HexTile = null

# Scene references
var tile_container: Node2D = null

# Noise for terrain generation
var noise: FastNoiseLite = FastNoiseLite.new()

func _ready():
	_setup_noise()

# Setup noise for terrain generation
func _setup_noise():
	noise.seed = randi()
	noise.frequency = 0.1
	noise.fractal_octaves = 3

# Create the hex grid
func create_grid(container: Node2D):
	tile_container = container

	print("Creating hex grid: %d x %d" % [grid_width, grid_height])
	var tile_count = 0

	for q in range(-grid_width / 2, grid_width / 2):
		for r in range(-grid_height / 2, grid_height / 2):
			_create_tile(q, r)
			tile_count += 1

	print("Created %d tiles" % tile_count)

# Create a single hex tile
func _create_tile(q: int, r: int):
	# Create tile node with required children
	var tile = HexTile.new()
	tile.hex_size = hex_size

	# Create Polygon2D for visual
	var polygon = Polygon2D.new()
	polygon.name = "Polygon2D"
	tile.add_child(polygon)

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

	# Add to container first (before init to ensure nodes are in tree)
	if tile_container:
		tile_container.add_child(tile)

	# Initialize tile (this will setup hex shape and visuals)
	tile.init(q, r, terrain)

	# Set position
	var pos = HexTile.hex_to_pixel(q, r, hex_size)
	tile.position = pos

	# Store tile
	tiles[Vector2i(q, r)] = tile

	# Connect signals
	tile.tile_clicked.connect(_on_tile_clicked)

	return tile

# Generate terrain type based on noise
func _generate_terrain(q: int, r: int) -> int:
	var noise_val = noise.get_noise_2d(float(q), float(r))

	# Distribute terrain types
	if noise_val > 0.3:
		return Buildings.TerrainType.MOUNTAIN
	elif noise_val > 0.0:
		return Buildings.TerrainType.FARMLAND
	elif noise_val > -0.3:
		return Buildings.TerrainType.EMPTY
	else:
		return Buildings.TerrainType.WATER

# Get tile at coordinates
func get_tile_at(q: int, r: int) -> HexTile:
	return tiles.get(Vector2i(q, r), null)

# Get tile at world position
func get_tile_at_position(world_pos: Vector2) -> HexTile:
	var hex_coords = HexTile.pixel_to_hex(world_pos, hex_size)
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
func get_grid_size() -> Vector2i:
	return Vector2i(grid_width, grid_height)

# Clear grid
func clear_grid():
	for tile in tiles.values():
		if tile:
			tile.queue_free()
	tiles.clear()
	selected_tile = null
