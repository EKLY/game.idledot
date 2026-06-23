class_name WorldData
extends RefCounted

## In-memory source of truth for the generated map (see KB [[Map Objects]]).
## Big placed objects (mountains, ponds) live in `resources` and reserve cells in
## `occupancy`. Small per-cell scatter (grass / pebble / tree / boulder) lives in
## `cell_kind`, one kind per free cell. Renderers READ this instead of rolling
## their own noise; fine detail (sub-positions, sizes, counts) is still derived by
## hashing the cell at draw time — so we store the layout, not every blade.

enum Kind { EMPTY, GRASS, PEBBLE, TREE, BOULDER }

var world_seed: int
var cols: int
var rows: int
var resources: Array[Dictionary] = []  # {type:String, cell:Vector2i, size:int}
var cell_kind: PackedByteArray = PackedByteArray()
var occupancy: Dictionary = {}  # Vector2i -> index into resources

# Player-placed structures (runtime, not part of generation). Buildings reserve a
# w x h block; roads reserve single cells. Both validate the same way terrain does:
# a cell must be in-bounds, free of resources / buildings / roads, and not a hard
# obstacle (tree / boulder). Grass, pebble and empty cells are buildable.
var buildings: Array[Dictionary] = []  # {type:String, origin:Vector2i, size:Vector2i}
var building_cells: Dictionary = {}  # Vector2i -> index into buildings
var roads: Dictionary = {}  # Vector2i -> true (set of road cells)

func kind_at(x: int, y: int) -> int:
	return cell_kind[y * cols + x]

func is_occupied(x: int, y: int) -> bool:
	return occupancy.has(Vector2i(x, y))

# What occupies a cell: a resource type ("mountain"/"pond"), a scatter kind
# ("grass"/"pebble"/"tree"/"boulder"), or "empty".
func label_at(x: int, y: int) -> String:
	var c := Vector2i(x, y)
	if occupancy.has(c):
		return resources[occupancy[c]].type
	match cell_kind[y * cols + x]:
		Kind.GRASS:
			return "grass"
		Kind.PEBBLE:
			return "pebble"
		Kind.TREE:
			return "tree"
		Kind.BOULDER:
			return "boulder"
	return "empty"

# --- Player-placed structures (buildings & roads) -------------------------------

# True if a single cell can carry a building or road: in-bounds, not already taken
# by a resource / building / road, and its scatter isn't a hard obstacle.
func _cell_buildable(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows:
		return false
	if occupancy.has(c) or building_cells.has(c) or roads.has(c):
		return false
	var k := cell_kind[c.y * cols + c.x]
	return k != Kind.TREE and k != Kind.BOULDER

# True only if every cell of the w x h footprint at `origin` is buildable.
func can_place(origin: Vector2i, size: Vector2i) -> bool:
	for dy in range(size.y):
		for dx in range(size.x):
			if not _cell_buildable(Vector2i(origin.x + dx, origin.y + dy)):
				return false
	return true

# True if any cell bordering the footprint (8-neighbour ring) carries terrain
# `terrain` ("mountain"/"tree"/"pond"/...). Extractors use this to bind to the
# resource they harvest — e.g. a mine must touch a mountain.
func is_adjacent_to_terrain(origin: Vector2i, size: Vector2i, terrain: String) -> bool:
	for y in range(origin.y - 1, origin.y + size.y + 1):
		for x in range(origin.x - 1, origin.x + size.x + 1):
			if x >= origin.x and x < origin.x + size.x and y >= origin.y and y < origin.y + size.y:
				continue  # inside the footprint, not the surrounding ring
			if x < 0 or y < 0 or x >= cols or y >= rows:
				continue
			if label_at(x, y) == terrain:
				return true
	return false

# Reserves the footprint and records the building. Returns false (no-op) if the
# footprint isn't clear.
func place_building(type: String, origin: Vector2i, size: Vector2i) -> bool:
	if not can_place(origin, size):
		return false
	var idx := buildings.size()
	buildings.append({"type": type, "origin": origin, "size": size})
	for dy in range(size.y):
		for dx in range(size.x):
			building_cells[Vector2i(origin.x + dx, origin.y + dy)] = idx
	return true

# Lays one road cell. Returns false (no-op) if the cell isn't buildable.
func place_road(cell: Vector2i) -> bool:
	if not _cell_buildable(cell):
		return false
	roads[cell] = true
	return true

# Removes whatever the player placed on `cell` — a road, or the whole building it
# belongs to. Terrain is never removed. Returns true if something was removed.
func remove_at(cell: Vector2i) -> bool:
	if roads.has(cell):
		roads.erase(cell)
		return true
	if building_cells.has(cell):
		buildings.remove_at(building_cells[cell])
		_rebuild_building_cells()  # array shifted; rebuild the cell->index map
		return true
	return false

# Recomputes building_cells from the buildings array (cheap: buildings are sparse).
func _rebuild_building_cells() -> void:
	building_cells.clear()
	for idx in range(buildings.size()):
		var b := buildings[idx]
		var origin: Vector2i = b.origin
		var size: Vector2i = b.size
		for dy in range(size.y):
			for dx in range(size.x):
				building_cells[Vector2i(origin.x + dx, origin.y + dy)] = idx

# Builds the whole map from a seed: place big resources first (they reserve
# cells), then fill the free cells with one scatter kind each.
static func generate(p_seed: int, p_cols: int, p_rows: int, cfg: Dictionary) -> WorldData:
	var w := WorldData.new()
	w.world_seed = p_seed
	w.cols = p_cols
	w.rows = p_rows
	w.cell_kind.resize(p_cols * p_rows)
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	w._place(rng, "pond", cfg.get("pond_count", 3), cfg.get("pond_max_w", 2))
	w._place_clustered(rng, "mountain",
		cfg.get("mountain_clusters", 3), cfg.get("mountain_per_cluster", 6),
		cfg.get("mountain_spread", 4), cfg.get("mountain_max_w", 3))
	var dt: float = cfg.get("tree_density", 0.04)
	var db: float = cfg.get("boulder_density", 0.03)
	var dg: float = cfg.get("grass_density", 0.22)
	var dp: float = cfg.get("pebble_density", 0.07)
	for y in range(p_rows):
		for x in range(p_cols):
			if w.is_occupied(x, y):
				continue
			var roll := w._hash01(x, y, p_seed)
			var k := Kind.EMPTY
			if roll < dt:
				k = Kind.TREE
			elif roll < dt + db:
				k = Kind.BOULDER
			elif roll < dt + db + dg:
				k = Kind.GRASS
			elif roll < dt + db + dg + dp:
				k = Kind.PEBBLE
			w.cell_kind[y * p_cols + x] = k
	return w

# Tries to drop `count` resources of `type` at uniformly random spots, retrying
# until each lands on a free footprint (or gives up after a few attempts).
func _place(rng: RandomNumberGenerator, type: String, count: int, max_w: int) -> void:
	for i in range(count):
		for attempt in range(30):
			if _seat(type, rng.randi_range(2, cols - max_w - 2), rng.randi_range(3, rows - 3), rng.randi_range(1, max_w)):
				break

# Like _place, but groups resources into `clusters` tight ranges: pick a centre,
# then seat `per_cluster` of them within `spread` cells of it. Used for mountains so
# they read as ranges instead of lone peaks.
func _place_clustered(rng: RandomNumberGenerator, type: String, clusters: int, per_cluster: int, spread: int, max_w: int) -> void:
	for ci in range(clusters):
		var ccx := rng.randi_range(2, cols - max_w - 2)
		var ccy := rng.randi_range(3, rows - 3)
		for i in range(per_cluster):
			for attempt in range(20):
				var cx := clampi(ccx + rng.randi_range(-spread, spread), 2, cols - max_w - 2)
				var cy := clampi(ccy + rng.randi_range(-spread, spread), 3, rows - 3)
				if _seat(type, cx, cy, rng.randi_range(1, max_w)):
					break

# Seats one resource of `type` at (cx,cy) width `ww` if its footprint is free,
# recording it + reserving its cells. Returns whether it was placed.
func _seat(type: String, cx: int, cy: int, ww: int) -> bool:
	var fp := _footprint(type, cx, cy, ww)
	if not _all_free(fp):
		return false
	var idx := resources.size()
	resources.append({"type": type, "cell": Vector2i(cx, cy), "size": ww})
	for c in fp:
		occupancy[c] = idx
	return true

# Cells a resource reserves. Mountain: `ww` wide on its base row + the row above
# (it stands 2 cells tall). Pond: a square block radius `ww` around its centre.
func _footprint(type: String, cx: int, cy: int, ww: int) -> Array:
	var cells: Array = []
	if type == "pond":
		for dy in range(-ww, ww + 1):
			for dx in range(-ww, ww + 1):
				cells.append(Vector2i(cx + dx, cy + dy))
	else:
		for dx in range(ww):
			cells.append(Vector2i(cx + dx, cy))
			cells.append(Vector2i(cx + dx, cy - 1))
	return cells

func _all_free(cells: Array) -> bool:
	for c in cells:
		if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows:
			return false
		if occupancy.has(c):
			return false
	return true

func _hash01(x: int, y: int, salt: int) -> float:
	return float(hash(Vector3i(x, y, salt)) & 0xFFFFFF) / float(0x1000000)
