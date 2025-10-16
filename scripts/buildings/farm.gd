extends BuildingBase
class_name Farm

# Farm building - grows crops on farmland tiles
# Produces food/materials over time

var crop_type: String = "wheat"
var growth_time: float = 6.0

func _setup():
	super._setup()

# Override production update
func _update_production(delta: float):
	production_timer += delta

	if production_timer >= production_time:
		_complete_production()
		production_timer = 0.0

# Complete a production cycle (harvest)
func _complete_production():
	if is_storage_full():
		stop_production()
		return

	var harvested = 1
	if add_resource(crop_type, harvested):
		production_completed.emit(crop_type, harvested)
	else:
		stop_production()

# Start farming operation
func start_farming():
	start_production()

# Override init to set crop type
func init(building_data: Dictionary):
	super.init(building_data)
	crop_type = building_data.get("production", "wheat")
	growth_time = building_data.get("production_time", 6.0)
	production_time = growth_time

	# Auto-start production
	start_farming()

# Get farm-specific info
func get_info() -> Dictionary:
	var info = super.get_info()
	info["crop_type"] = crop_type
	info["growth_time"] = growth_time
	info["crop_name"] = Resources.get_resource_name(crop_type)
	return info
