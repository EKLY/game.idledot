extends Node

# Building Manager - Helper functions for accessing unified building data
# All buildings (Natural, Manual, Upgrade) are defined in buildings_data.gd
#
# Building Types:
# - NATURAL: Has spawn_chance (spawned during map generation)
# - MANUAL: Has terrain or referenced in buildable_on (player can build)
# - UPGRADE: Referenced in buildable_on only (upgrade from other buildings)

# Reference to data file
const BuildingData = preload("res://autoload/buildings_data.gd")

# Expose TerrainType enum for easy access
const TerrainType = BuildingData.TerrainType

# Access to buildings dictionary
var BUILDINGS: Dictionary:
	get:
		return BuildingData.BUILDINGS

# Legacy support - STRUCTURES now refers to same BUILDINGS
var STRUCTURES: Dictionary:
	get:
		return BuildingData.BUILDINGS

# Get building data by ID
func get_building(building_id: String) -> Dictionary:
	if BUILDINGS.has(building_id):
		return BUILDINGS[building_id]
	return {}

# Get building cost
func get_building_cost(building_id: String) -> int:
	var building = get_building(building_id)
	return building.get("cost", 0)

# Check if building can be placed on terrain
func can_place_on_terrain(building_id: String, terrain: int) -> bool:
	var building = get_building(building_id)
	var allowed_terrain = building.get("terrain", [])
	return terrain in allowed_terrain

# Get all buildings that can be placed on terrain
func get_buildings_for_terrain(terrain: int) -> Array:
	var result = []
	for building_id in BUILDINGS.keys():
		if can_place_on_terrain(building_id, terrain):
			result.append(building_id)
	return result

# Get building name
func get_building_name(building_id: String) -> String:
	var building = get_building(building_id)
	return building.get("name", "Unknown")

# Get building description
func get_building_description(building_id: String) -> String:
	var building = get_building(building_id)
	return building.get("description", "")

# ==================== BUILDING TYPE CHECKING ====================

# Check if building is NATURAL type (has spawn_chance)
func is_natural(building_id: String) -> bool:
	var building = get_building(building_id)
	return building.has("spawn_chance")

# Check if building is MANUAL type (has terrain or is referenced in buildable_on of natural)
func is_manual(building_id: String) -> bool:
	var building = get_building(building_id)

	# Has terrain = manual buildable
	if building.has("terrain"):
		return true

	# Check if referenced in any natural building's buildable_on
	for other_id in BUILDINGS.keys():
		if is_natural(other_id):
			var buildable = BUILDINGS[other_id].get("buildable_on", [])
			if building_id in buildable:
				return true

	return false

# Check if building is UPGRADE type (only referenced in buildable_on of manual/upgrade)
func is_upgrade(building_id: String) -> bool:
	var building = get_building(building_id)

	# Cannot have spawn_chance or terrain
	if building.has("spawn_chance") or building.has("terrain"):
		return false

	# Must be referenced in someone's buildable_on
	for other_id in BUILDINGS.keys():
		if other_id == building_id:
			continue
		var other_building = BUILDINGS[other_id]
		var buildable = other_building.get("buildable_on", [])
		if building_id in buildable:
			return true

	return false

# ==================== NATURAL BUILDING FUNCTIONS ====================

# Get all natural buildings (have spawn_chance)
func get_natural_buildings() -> Array:
	var result = []
	for building_id in BUILDINGS.keys():
		if is_natural(building_id):
			result.append(building_id)
	return result

# Get all natural buildings that can spawn on terrain
func get_natural_buildings_for_terrain(terrain: int) -> Array:
	var result = []
	for building_id in BUILDINGS.keys():
		if can_spawn_on_terrain(building_id, terrain):
			result.append(building_id)
	return result

# Check if natural building can spawn on terrain
func can_spawn_on_terrain(building_id: String, terrain: int) -> bool:
	var building = get_building(building_id)
	var spawn_chance = building.get("spawn_chance", {})
	return terrain in spawn_chance

# Get spawn chance for natural building on terrain
func get_spawn_chance(building_id: String, terrain: int) -> float:
	var building = get_building(building_id)
	var spawn_chance = building.get("spawn_chance", {})
	return spawn_chance.get(terrain, 0.0)

# Get building sprite path (generated from key: building_{key}.png)
func get_building_sprite(building_id: String) -> String:
	if BUILDINGS.has(building_id):
		return "building_" + building_id + ".png"
	return ""

# ==================== MANUAL BUILDING FUNCTIONS ====================

# Get all manual buildings
func get_manual_buildings() -> Array:
	var result = []
	for building_id in BUILDINGS.keys():
		if is_manual(building_id):
			result.append(building_id)
	return result

# Get buildings that can be built on this structure (natural building)
func get_buildable_on_structure(structure_id: String) -> Array:
	var structure = get_building(structure_id)
	return structure.get("buildable_on", [])

# Check if building can be built on this structure
func can_build_on_structure(structure_id: String, building_id: String) -> bool:
	var buildable = get_buildable_on_structure(structure_id)
	return building_id in buildable

# ==================== UPGRADE BUILDING FUNCTIONS ====================

# Get all upgrade buildings
func get_upgrade_buildings() -> Array:
	var result = []
	for building_id in BUILDINGS.keys():
		if is_upgrade(building_id):
			result.append(building_id)
	return result

# Get buildings that this building can upgrade to
func get_upgrades_for(building_id: String) -> Array:
	var building = get_building(building_id)
	return building.get("buildable_on", [])

# Check if can upgrade from one building to another
func can_upgrade_to(from_building_id: String, to_building_id: String) -> bool:
	var upgrades = get_upgrades_for(from_building_id)
	return to_building_id in upgrades

# ==================== LEGACY SUPPORT (for backward compatibility) ====================

# Legacy: Get object data by ID (now same as get_building)
func get_object(object_id: String) -> Dictionary:
	return get_building(object_id)

# Legacy: Get object name (now same as get_building_name)
func get_object_name(object_id: String) -> String:
	return get_building_name(object_id)

# Legacy: Get object sprite path (now same as get_building_sprite)
func get_object_sprite(object_id: String) -> String:
	return get_building_sprite(object_id)

# Legacy: Get buildings that can be built on this object (now get_buildable_on_structure)
func get_buildable_on_object(object_id: String) -> Array:
	return get_buildable_on_structure(object_id)

# Legacy: Check if building can be built on this object (now can_build_on_structure)
func can_build_on_object(object_id: String, building_id: String) -> bool:
	return can_build_on_structure(object_id, building_id)

# Legacy: Get all objects that can spawn on terrain (now get_natural_buildings_for_terrain)
func get_objects_for_terrain(terrain: int) -> Array:
	return get_natural_buildings_for_terrain(terrain)

# Legacy: Get spawn chance for object on terrain (now get_spawn_chance)
func get_object_spawn_chance(object_id: String, terrain: int) -> float:
	return get_spawn_chance(object_id, terrain)
