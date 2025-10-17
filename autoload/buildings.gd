extends Node

# Global building definitions
# Contains all building types, costs, requirements, and properties

enum TerrainType {
	EMPTY,    # Gray , พื้นที่ว่างเปล่า
	FIELD,    # Green , พื้นที่ทุ่งหญ้า
	SAND,     # Yellow , พื้นที่ทะเลทราย
	WATER,    # Blue , พื้นที่ทะเล
	SNOW,     # White , พื้นที่หิมะ ความเย็น
	VOLCANIC  # Red , พื้นที่ลาวา ความร้อน
}

# Objects that spawn on terrain (pre-placed for player to build on)
const STRUCTURES: Dictionary[Variant, Variant] = {
	"mountain": {
		"name": "Mountain",
		"description": "Rich mineral deposit",
		"buildable": ["iron_mine", "copper_mine", "gold_mine", "coal_mine"],
		"spawn_chance": {
			TerrainType.FIELD: 0.15,
			TerrainType.SAND: 0.25,
			TerrainType.SNOW: 0.10,
		},
	},
	"rock_ice": {
		"name": "Ice Rock",
		"description": "Stone deposits",
		"buildable": ["quarry"],
		"spawn_chance": {
			TerrainType.SNOW: 0.15,
		},
	},
	"forest_deep": {
		"name": "Tree",
		"description": "Harvestable trees",
		"buildable": ["lumber_mill"],
		"spawn_chance": {
			TerrainType.FIELD: 0.05,
		},
	},
	"rock": {
		"name": "Rock Formation",
		"buildable": ["quarry"],
		"spawn_chance": {
			TerrainType.SAND: 0.15,
			TerrainType.EMPTY: 0.05,
		},
		"description": "Stone deposits"
	},
	"coral": {
		"name": "Coral Reef",
		"buildable": ["fishing_dock"],
		"spawn_chance": {
			TerrainType.WATER: 0.15,  # 15% only on WATER
		},
		"description": "Underwater coral formation"
	},
	"ice": {
		"name": "Ice Formation",
		"buildable": ["ice_harvester"],
		"spawn_chance": {
			TerrainType.SNOW: 0.20,  # 20% chance on SNOW
		},
		"description": "Frozen water deposits"
	},
	"lava_vent": {
		"name": "Lava Vent",
		"buildable": ["geothermal_plant"],
		"spawn_chance": {
			TerrainType.VOLCANIC: 0.30,  # 30% chance on VOLCANIC
		},
		"description": "Underground heat source"
	}
}

const BUILDINGS: Dictionary[Variant, Variant] = {
	"iron_mine": {
		"name": "Iron Mine",
		"cost": 100,
		"terrain": [TerrainType.SAND],
		"production": "iron_ore",
		"production_time": 5.0,
		"storage": 50,
		"description": "Extracts iron ore from sand"
	},
	"copper_mine": {
		"name": "Copper Mine",
		"cost": 120,
		"terrain": [TerrainType.SAND],
		"production": "copper_ore",
		"production_time": 5.0,
		"storage": 50,
		"description": "Extracts copper ore from sand"
	},
	"gold_mine": {
		"name": "Gold Mine",
		"cost": 200,
		"terrain": [TerrainType.SAND],
		"production": "gold_ore",
		"production_time": 8.0,
		"storage": 30,
		"description": "Extracts valuable gold ore"
	},
	"coal_mine": {
		"name": "Coal Mine",
		"cost": 80,
		"terrain": [TerrainType.SAND],
		"production": "coal",
		"production_time": 4.0,
		"storage": 60,
		"description": "Extracts coal for fuel"
	},
	"wheat_farm": {
		"name": "Wheat Farm",
		"cost": 100,
		"terrain": [TerrainType.FIELD],
		"production": "wheat",
		"production_time": 6.0,
		"storage": 100,
		"description": "Grows wheat crops"
	},
	"vegetable_farm": {
		"name": "Vegetable Farm",
		"cost": 150,
		"terrain": [TerrainType.FIELD],
		"production": "vegetables",
		"production_time": 7.0,
		"storage": 100,
		"description": "Grows fresh vegetables"
	},
	"cotton_farm": {
		"name": "Cotton Farm",
		"cost": 120,
		"terrain": [TerrainType.FIELD],
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

# ==================== OBJECT FUNCTIONS ====================

# Get object data by ID
func get_object(object_id: String) -> Dictionary:
	if STRUCTURES.has(object_id):
		return STRUCTURES[object_id]
	return {}

# Get object name
func get_object_name(object_id: String) -> String:
	var obj = get_object(object_id)
	return obj.get("name", "Unknown")

# Get object sprite path (generated from key: object_{key}.png)
func get_object_sprite(object_id: String) -> String:
	if STRUCTURES.has(object_id):
		return "building_" + object_id + ".png"
	return ""

# Get buildings that can be built on this object
func get_buildable_on_object(object_id: String) -> Array:
	var obj = get_object(object_id)
	return obj.get("buildable", [])

# Check if building can be built on this object
func can_build_on_object(object_id: String, building_id: String) -> bool:
	var buildable = get_buildable_on_object(object_id)
	return building_id in buildable

# Get all objects that can spawn on terrain
func get_objects_for_terrain(terrain: int) -> Array:
	var result = []
	for object_id in STRUCTURES.keys():
		var obj = STRUCTURES[object_id]
		var spawn_chance = obj.get("spawn_chance", {})
		if terrain in spawn_chance:
			result.append(object_id)
	return result

# Get spawn chance for object on terrain
func get_object_spawn_chance(object_id: String, terrain: int) -> float:
	var obj = get_object(object_id)
	var spawn_chance = obj.get("spawn_chance", {})
	return spawn_chance.get(terrain, 0.0)
