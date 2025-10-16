extends Node

# Global building definitions
# Contains all building types, costs, requirements, and properties

enum TerrainType {
	EMPTY,
	MOUNTAIN,
	FARMLAND,
	WATER
}

const BUILDINGS = {
	"iron_mine": {
		"name": "Iron Mine",
		"cost": 100,
		"terrain": [TerrainType.MOUNTAIN],
		"production": "iron_ore",
		"production_time": 5.0,
		"storage": 50,
		"description": "Extracts iron ore from mountains"
	},
	"copper_mine": {
		"name": "Copper Mine",
		"cost": 120,
		"terrain": [TerrainType.MOUNTAIN],
		"production": "copper_ore",
		"production_time": 5.0,
		"storage": 50,
		"description": "Extracts copper ore from mountains"
	},
	"gold_mine": {
		"name": "Gold Mine",
		"cost": 200,
		"terrain": [TerrainType.MOUNTAIN],
		"production": "gold_ore",
		"production_time": 8.0,
		"storage": 30,
		"description": "Extracts valuable gold ore"
	},
	"coal_mine": {
		"name": "Coal Mine",
		"cost": 80,
		"terrain": [TerrainType.MOUNTAIN],
		"production": "coal",
		"production_time": 4.0,
		"storage": 60,
		"description": "Extracts coal for fuel"
	},
	"wheat_farm": {
		"name": "Wheat Farm",
		"cost": 100,
		"terrain": [TerrainType.FARMLAND],
		"production": "wheat",
		"production_time": 6.0,
		"storage": 100,
		"description": "Grows wheat crops"
	},
	"vegetable_farm": {
		"name": "Vegetable Farm",
		"cost": 150,
		"terrain": [TerrainType.FARMLAND],
		"production": "vegetables",
		"production_time": 7.0,
		"storage": 100,
		"description": "Grows fresh vegetables"
	},
	"cotton_farm": {
		"name": "Cotton Farm",
		"cost": 120,
		"terrain": [TerrainType.FARMLAND],
		"production": "cotton",
		"production_time": 8.0,
		"storage": 100,
		"description": "Grows cotton plants"
	},
	"fishing_dock": {
		"name": "Fishing Dock",
		"cost": 150,
		"terrain": [TerrainType.WATER],
		"production": "fish",
		"production_time": 5.0,
		"storage": 50,
		"description": "Catches fish from water"
	},
	"water_pump": {
		"name": "Water Pump",
		"cost": 100,
		"terrain": [TerrainType.WATER],
		"production": "water",
		"production_time": 3.0,
		"storage": 100,
		"description": "Pumps clean water"
	},
	"factory": {
		"name": "Factory",
		"cost": 300,
		"terrain": [TerrainType.EMPTY, TerrainType.WATER],
		"production": null,
		"production_time": 0.0,
		"input_storage": 100,
		"output_storage": 50,
		"description": "Processes resources using recipes"
	},
	"road": {
		"name": "Road",
		"cost": 10,
		"terrain": [TerrainType.EMPTY],
		"transport_speed": 2.0,
		"description": "Connects buildings for resource transport"
	}
}

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
