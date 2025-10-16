extends BuildingBase
class_name Factory

# Factory building - processes resources using recipes
# Has input and output storage, consumes inputs to produce outputs

signal recipe_assigned(recipe_id: String)
signal recipe_completed(output_resource: String, amount: int)
signal inputs_insufficient()

var recipe_id: String = ""
var recipe_data: Dictionary = {}

var input_storage: Dictionary = {}
var output_storage: Dictionary = {}

var input_storage_capacity: int = 100
var output_storage_capacity: int = 50

func _setup():
	super._setup()

# Override production update
func _update_production(delta: float):
	if recipe_id.is_empty():
		return

	# Check if we have enough inputs
	if not _has_required_inputs():
		stop_production()
		inputs_insufficient.emit()
		return

	production_timer += delta

	if production_timer >= production_time:
		_complete_production()
		production_timer = 0.0

# Check if factory has required inputs
func _has_required_inputs() -> bool:
	var inputs = recipe_data.get("inputs", {})
	for resource_id in inputs.keys():
		var required_amount = inputs[resource_id]
		if input_storage.get(resource_id, 0) < required_amount:
			return false
	return true

# Consume inputs for production
func _consume_inputs() -> bool:
	var inputs = recipe_data.get("inputs", {})
	for resource_id in inputs.keys():
		var required_amount = inputs[resource_id]
		if input_storage.get(resource_id, 0) < required_amount:
			return false
		input_storage[resource_id] -= required_amount
	return true

# Complete a production cycle
func _complete_production():
	# Consume inputs
	if not _consume_inputs():
		stop_production()
		return

	# Produce output
	var output = recipe_data.get("output", {})
	for resource_id in output.keys():
		var amount = output[resource_id]
		var current = output_storage.get(resource_id, 0)

		if current + amount > output_storage_capacity:
			stop_production()
			return

		output_storage[resource_id] = current + amount
		recipe_completed.emit(resource_id, amount)
		production_completed.emit(resource_id, amount)

# Assign a recipe to the factory
func assign_recipe(new_recipe_id: String) -> bool:
	if not Recipes.has_recipe(new_recipe_id):
		return false

	recipe_id = new_recipe_id
	recipe_data = Recipes.get_recipe(recipe_id)
	production_time = recipe_data.get("time", 0.0)
	production_timer = 0.0

	recipe_assigned.emit(recipe_id)

	# Try to start production if inputs available
	if _has_required_inputs():
		start_production()

	return true

# Add resource to input storage
func add_input_resource(resource_id: String, amount: int) -> bool:
	var current = input_storage.get(resource_id, 0)
	if current + amount > input_storage_capacity:
		return false

	input_storage[resource_id] = current + amount

	# Check if we can start production now
	if not is_producing and _has_required_inputs():
		start_production()

	return true

# Remove resource from output storage
func remove_output_resource(resource_id: String, amount: int) -> bool:
	var current = output_storage.get(resource_id, 0)
	if current < amount:
		return false

	output_storage[resource_id] = current - amount
	return true

# Get input storage amount
func get_input_amount(resource_id: String) -> int:
	return input_storage.get(resource_id, 0)

# Get output storage amount
func get_output_amount(resource_id: String) -> int:
	return output_storage.get(resource_id, 0)

# Override get_save_data
func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["recipe_id"] = recipe_id
	data["input_storage"] = input_storage
	data["output_storage"] = output_storage
	return data

# Override load_from_save
func load_from_save(data: Dictionary):
	super.load_from_save(data)
	input_storage = data.get("input_storage", {})
	output_storage = data.get("output_storage", {})

	var saved_recipe = data.get("recipe_id", "")
	if not saved_recipe.is_empty():
		assign_recipe(saved_recipe)

# Get factory-specific info
func get_info() -> Dictionary:
	var info = super.get_info()
	info["recipe_id"] = recipe_id
	info["recipe_name"] = recipe_data.get("name", "No Recipe")
	info["input_storage"] = input_storage
	info["output_storage"] = output_storage
	info["input_capacity"] = input_storage_capacity
	info["output_capacity"] = output_storage_capacity
	return info
