extends BuildingBase
class_name Mine

# Mine building - extracts resources from mountain tiles
# Produces ore over time and stores in internal storage

var ore_type: String = "iron_ore"
var production_rate: float = 1.0

func _setup():
	super._setup()

# Override production update
func _update_production(delta: float):
	production_timer += delta

	if production_timer >= production_time:
		_complete_production()
		production_timer = 0.0

# Complete a production cycle
func _complete_production():
	if is_storage_full():
		stop_production()
		return

	var produced = int(production_rate)
	if add_resource(ore_type, produced):
		production_completed.emit(ore_type, produced)
	else:
		stop_production()

# Start mining operation
func start_mining():
	start_production()

# Override init to set ore type
func init(building_data: Dictionary):
	super.init(building_data)
	ore_type = building_data.get("production", "iron_ore")
	production_rate = building_data.get("production_rate", 1.0)

	# Auto-start production
	start_mining()

# Get mine-specific info
func get_info() -> Dictionary:
	var info = super.get_info()
	info["ore_type"] = ore_type
	info["production"] = ore_type  # For UI display
	info["production_rate"] = production_rate
	info["ore_name"] = Resources.get_resource_name(ore_type)
	return info
