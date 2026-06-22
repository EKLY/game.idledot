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
	w._place(rng, "mountain", cfg.get("mountain_count", 4), cfg.get("mountain_max_w", 3))
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

# Tries to drop `count` resources of `type`, retrying placement until each one
# lands on a free footprint (or gives up after a few attempts).
func _place(rng: RandomNumberGenerator, type: String, count: int, max_w: int) -> void:
	for i in range(count):
		for attempt in range(30):
			var ww := rng.randi_range(1, max_w)
			var cx := rng.randi_range(2, cols - max_w - 2)
			var cy := rng.randi_range(3, rows - 3)
			var fp := _footprint(type, cx, cy, ww)
			if _all_free(fp):
				var idx := resources.size()
				resources.append({"type": type, "cell": Vector2i(cx, cy), "size": ww})
				for c in fp:
					occupancy[c] = idx
				break

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
