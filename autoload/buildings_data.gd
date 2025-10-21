extends Node

# Unified Building Data
# Contains all buildings: Natural, Manual, and Upgrade types
#
# Building Types (determined by properties):
# 1. NATURAL: Has spawn_chance - randomly spawned on map generation
# 2. MANUAL: Has terrain or referenced in buildable_on - player can build
# 3. UPGRADE: Referenced in buildable_on of other buildings - upgrade only

enum TerrainType {
	EMPTY,    # Gray , พื้นที่ว่างเปล่า
	FIELD,    # Green , พื้นที่ทุ่งหญ้า
	SAND,     # Yellow , พื้นที่ทะเลทราย
	WATER,    # Blue , พื้นที่ทะเล
	SNOW,     # White , พื้นที่หิมะ ความเย็น
	VOLCANIC  # Red , พื้นที่ลาวา ความร้อน
}

const BUILDINGS: Dictionary[Variant, Variant] = {
	# ========================================
	# NATURAL BUILDINGS (มี spawn_chance)
	# Random spawn บนแผนที่ตอน generate
	# ========================================

	"mountain": {
		"name": "Mountain",
		"description": "Rich mineral deposit",
		"buildable_on": ["mine", "mountain_waterfall"],
		"spawn_chance": { TerrainType.FIELD: 0.15, TerrainType.SAND: 0.25, TerrainType.SNOW: 0.10, },
	},

	"forest_deep": {
		"name": "Tree",
		"description": "Harvestable trees",
		"buildable_on": ["wood_log"],
		"spawn_chance": { TerrainType.FIELD: 0.05, },
	},

	"rock": {
		"name": "Rock Formation",
		"description": "Stone deposits",
		"buildable_on": ["quarry"],
		"spawn_chance": { TerrainType.SAND: 0.15, TerrainType.EMPTY: 0.05, },
	},

	"rock_ice": {
		"name": "Ice Rock",
		"description": "Stone deposits in frozen areas",
		"buildable_on": ["quarry"],
		"spawn_chance": { TerrainType.SNOW: 0.15, },
	},

	"coral": {
		"name": "Coral Reef",
		"description": "Underwater coral formation",
		"buildable_on": ["fishing_dock"],
		"spawn_chance": { TerrainType.WATER: 0.15, },
	},

	"ice": {
		"name": "Ice Formation",
		"description": "Frozen water deposits",
		"buildable_on": ["ice_harvester"],
		"spawn_chance": { TerrainType.SNOW: 0.20, },
	},

	"lava_vent": {
		"name": "Lava Vent",
		"description": "Underground heat source",
		"buildable_on": ["geothermal_plant"],
		"spawn_chance": { TerrainType.VOLCANIC: 0.30, },
	},

	# --- Buildings on Empty Terrain ---
	"farm": {
		"name": "Farm",
		"description": "Grows crops on fertile land",
		"cost": 150,
		"terrain": [TerrainType.FIELD],
		"buildable_on": ["advanced_farm"],
		"production": "wheat",
		"production_time": 10.0,
		"storage": 100,
	},
	
	"road": {
		"name": "Road",
		"description": "Connects buildings for transport",
		"cost": 10,
		"terrain": [TerrainType.EMPTY, TerrainType.FIELD, TerrainType.SAND],
		"buildable_on": [],
		"transport_speed": 1.0,  # tiles per second
	},

	"factory": {
		"name": "Factory",
		"description": "Processes resources into products",
		"cost": 300,
		"terrain": [TerrainType.EMPTY, TerrainType.FIELD],
		"buildable_on": ["advanced_factory"],
		"input_storage": 100,
		"output_storage": 50,
		"processing_time": 5.0,
	},

	# ========================================
	# MANUAL BUILDINGS (มี terrain หรือ ถูก reference ใน buildable_on)
	# สร้างได้เองโดย player
	# ========================================

	"iron_mine": {
		"name": "Iron Mine",
		"description": "Extracts iron ore from mountains",
		"cost": 100,
		"buildable_on": ["advanced_iron_mine"],  # อัพเกรดต่อได้
		"production": "iron_ore",
		"production_time": 5.0,
		"storage": 50,
	},

	"copper_mine": {
		"name": "Copper Mine",
		"description": "Extracts copper ore from mountains",
		"cost": 120,
		"buildable_on": [],
		"production": "copper_ore",
		"production_time": 6.0,
		"storage": 50,
	},

	"gold_mine": {
		"name": "Gold Mine",
		"description": "Extracts gold ore from mountains",
		"cost": 300,
		"buildable_on": [],
		"production": "gold_ore",
		"production_time": 10.0,
		"storage": 30,
	},

	"coal_mine": {
		"name": "Coal Mine",
		"description": "Extracts coal from mountains",
		"cost": 80,
		"buildable_on": [],
		"production": "coal",
		"production_time": 4.0,
		"storage": 60,
	},

	# --- Resource Extractors (สร้างบนโครงสร้างธรรมชาติ) ---
	"quarry": {
		"name": "Quarry",
		"description": "Extracts stone from rock formations",
		"cost": 90,
		"buildable_on": [],
		"production": "stone",
		"production_time": 5.0,
		"storage": 50,
	},

	"lumber_mill": {
		"name": "Lumber Mill",
		"description": "Harvests wood from trees",
		"cost": 70,
		"buildable_on": [],
		"production": "wood",
		"production_time": 4.0,
		"storage": 60,
	},

	"fishing_dock": {
		"name": "Fishing Dock",
		"description": "Catches fish from coral reefs",
		"cost": 100,
		"buildable_on": [],
		"production": "fish",
		"production_time": 6.0,
		"storage": 40,
	},

	"ice_harvester": {
		"name": "Ice Harvester",
		"description": "Harvests ice from frozen deposits",
		"cost": 85,
		"buildable_on": [],
		"production": "ice",
		"production_time": 5.0,
		"storage": 45,
	},

	"geothermal_plant": {
		"name": "Geothermal Plant",
		"description": "Harnesses heat from lava vents",
		"cost": 400,
		"buildable_on": [],
		"production": "energy",
		"production_time": 3.0,
		"storage": 100,
	},

	# ========================================
	# UPGRADE BUILDINGS (ถูก reference ใน buildable_on)
	# อัพเกรดจากอาคารอื่นเท่านั้น
	# ========================================

	"advanced_iron_mine": {
		"name": "Advanced Iron Mine",
		"description": "Enhanced iron mining with better efficiency",
		"cost": 500,
		"buildable_on": [],  # สามารถเพิ่มอัพเกรดต่อได้
		"production": "iron_ore",
		"production_time": 2.5,  # เร็วกว่าเดิม 2 เท่า
		"storage": 100,  # มากกว่าเดิม 2 เท่า
	},

	"advanced_farm": {
		"name": "Advanced Farm",
		"description": "Modern farming with increased yield",
		"cost": 700,
		"buildable_on": [],
		"production": "wheat",
		"production_time": 5.0,  # เร็วกว่าเดิม 2 เท่า
		"storage": 200,  # มากกว่าเดิม 2 เท่า
	},

	"advanced_factory": {
		"name": "Advanced Factory",
		"description": "Automated processing facility",
		"cost": 1500,
		"buildable_on": [],
		"input_storage": 200,  # มากกว่าเดิม 2 เท่า
		"output_storage": 100,  # มากกว่าเดิม 2 เท่า
		"processing_time": 2.5,  # เร็วกว่าเดิม 2 เท่า
	},
}
