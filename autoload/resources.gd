extends Node

# Global resource definitions for the game
# Contains all resource types, their values, and properties

const RESOURCES = {
	"iron_ore": {
		"name": "Iron Ore",
		"value": 5,
		"icon": "res://assets/icons/iron_ore.png",
		"description": "Raw iron ore extracted from mountains"
	},
	"copper_ore": {
		"name": "Copper Ore",
		"value": 4,
		"icon": "res://assets/icons/copper_ore.png",
		"description": "Raw copper ore for processing"
	},
	"gold_ore": {
		"name": "Gold Ore",
		"value": 10,
		"icon": "res://assets/icons/gold_ore.png",
		"description": "Valuable gold ore"
	},
	"coal": {
		"name": "Coal",
		"value": 3,
		"icon": "res://assets/icons/coal.png",
		"description": "Fuel for processing and smelting"
	},
	"iron_bar": {
		"name": "Iron Bar",
		"value": 15,
		"icon": "res://assets/icons/iron_bar.png",
		"description": "Processed iron bar"
	},
	"copper_wire": {
		"name": "Copper Wire",
		"value": 12,
		"icon": "res://assets/icons/copper_wire.png",
		"description": "Processed copper wire"
	},
	"steel": {
		"name": "Steel",
		"value": 40,
		"icon": "res://assets/icons/steel.png",
		"description": "High-quality steel alloy"
	},
	"wheat": {
		"name": "Wheat",
		"value": 3,
		"icon": "res://assets/icons/wheat.png",
		"description": "Basic grain crop"
	},
	"vegetables": {
		"name": "Vegetables",
		"value": 4,
		"icon": "res://assets/icons/vegetables.png",
		"description": "Fresh vegetables"
	},
	"cotton": {
		"name": "Cotton",
		"value": 5,
		"icon": "res://assets/icons/cotton.png",
		"description": "Cotton for textile production"
	},
	"flour": {
		"name": "Flour",
		"value": 8,
		"icon": "res://assets/icons/flour.png",
		"description": "Processed wheat flour"
	},
	"bread": {
		"name": "Bread",
		"value": 25,
		"icon": "res://assets/icons/bread.png",
		"description": "Baked bread product"
	},
	"fish": {
		"name": "Fish",
		"value": 6,
		"icon": "res://assets/icons/fish.png",
		"description": "Fresh caught fish"
	},
	"water": {
		"name": "Water",
		"value": 1,
		"icon": "res://assets/icons/water.png",
		"description": "Clean water resource"
	}
}

# Get resource data by ID
func get_resource(resource_id: String) -> Dictionary:
	if RESOURCES.has(resource_id):
		return RESOURCES[resource_id]
	return {}

# Get resource name by ID
func get_resource_name(resource_id: String) -> String:
	var resource_data = get_resource(resource_id)
	return resource_data.get("name", "Unknown")

# Get resource value by ID
func get_resource_value(resource_id: String) -> int:
	var resource_data = get_resource(resource_id)
	return resource_data.get("value", 0)
