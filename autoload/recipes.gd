extends Node

# Global recipe definitions for factories
# Contains all production recipes with inputs, outputs, and processing times

const RECIPES = {
	"iron_bar": {
		"name": "Smelt Iron Bar",
		"inputs": {"iron_ore": 1},
		"output": {"iron_bar": 1},
		"time": 4.0,
		"description": "Smelt iron ore into iron bars"
	},
	"copper_wire": {
		"name": "Process Copper Wire",
		"inputs": {"copper_ore": 1},
		"output": {"copper_wire": 1},
		"time": 4.0,
		"description": "Process copper ore into wire"
	},
	"steel": {
		"name": "Forge Steel",
		"inputs": {"iron_bar": 1, "coal": 2},
		"output": {"steel": 1},
		"time": 5.0,
		"description": "Combine iron and coal to create steel"
	},
	"flour": {
		"name": "Mill Flour",
		"inputs": {"wheat": 1},
		"output": {"flour": 1},
		"time": 3.0,
		"description": "Mill wheat into flour"
	},
	"bread": {
		"name": "Bake Bread",
		"inputs": {"flour": 1, "water": 1},
		"output": {"bread": 1},
		"time": 7.0,
		"description": "Bake flour and water into bread"
	}
}

# Get recipe data by ID
func get_recipe(recipe_id: String) -> Dictionary:
	if RECIPES.has(recipe_id):
		return RECIPES[recipe_id]
	return {}

# Get all recipe IDs
func get_all_recipe_ids() -> Array:
	return RECIPES.keys()

# Check if recipe exists
func has_recipe(recipe_id: String) -> bool:
	return RECIPES.has(recipe_id)

# Get recipe processing time
func get_recipe_time(recipe_id: String) -> float:
	var recipe = get_recipe(recipe_id)
	return recipe.get("time", 0.0)

# Get recipe inputs
func get_recipe_inputs(recipe_id: String) -> Dictionary:
	var recipe = get_recipe(recipe_id)
	return recipe.get("inputs", {})

# Get recipe output
func get_recipe_output(recipe_id: String) -> Dictionary:
	var recipe = get_recipe(recipe_id)
	return recipe.get("output", {})
