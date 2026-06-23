class_name BuildingCatalog
extends RefCounted

## Loads the building catalog from config/buildings.json — the config-driven source
## of placeable building types and the production chain that links them (see spec
## Economy Model). Kept small: load directly now, fold into a ConfigService when the
## economy ticks. Entries are typed so placement, the placeholder render, and the
## chain read them as-is. Later fields (cost, sprite) slot into the same JSON + parse.

const PATH := "res://config/buildings.json"

# Reads the catalog into typed dictionaries:
#   {id, name:String, size:Vector2i, color:Color, tier:String, requires:String,
#    inputs:Array[Dictionary], outputs:Array[Dictionary]}
# where each input/output is {resource:String, rate:float}. `requires` is the
# terrain an extractor must sit adjacent to ("mountain"/"tree"/"pond"), "" for none.
# Returns an empty array (and logs) on any problem.
static func load_all(path: String = PATH) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_error("BuildingCatalog: missing %s" % path)
		return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_ARRAY:
		push_error("BuildingCatalog: %s is not a JSON array" % path)
		return out
	for entry in data:
		out.append({
			"id": entry.get("id", ""),
			"name": entry.get("name", ""),
			"size": Vector2i(int(entry["size"][0]), int(entry["size"][1])),
			"color": Color(entry.get("color", "#ffffff")),
			"tier": entry.get("tier", ""),
			"requires": entry.get("requires", ""),
			"cost": float(entry.get("cost", 0.0)),
			"inputs": _parse_io(entry.get("inputs", [])),
			"outputs": _parse_io(entry.get("outputs", [])),
		})
	return out

# Normalises an inputs/outputs JSON array into typed {resource, rate} dictionaries.
static func _parse_io(arr: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for io in arr:
		out.append({"resource": io.get("resource", ""), "rate": float(io.get("rate", 0.0))})
	return out
