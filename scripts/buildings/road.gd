extends BuildingBase
class_name Road

# Road building - connects other buildings for resource transport
# Does not produce anything but facilitates transport

var transport_speed: float = 2.0
var connected_buildings: Array = []

func _setup():
	super._setup()

# Override init to set transport properties
func init(building_data: Dictionary):
	super.init(building_data)
	transport_speed = building_data.get("transport_speed", 2.0)

# Add a connected building
func add_connection(building: BuildingBase):
	if building not in connected_buildings:
		connected_buildings.append(building)

# Remove a connected building
func remove_connection(building: BuildingBase):
	connected_buildings.erase(building)

# Get all connected buildings
func get_connections() -> Array:
	return connected_buildings

# Calculate transport time based on distance
func calculate_transport_time(distance: int) -> float:
	return float(distance) * 0.5 / transport_speed

# Get road-specific info
func get_info() -> Dictionary:
	var info = super.get_info()
	info["transport_speed"] = transport_speed
	info["connections"] = connected_buildings.size()
	return info

# Override production (roads don't produce)
func _update_production(_delta: float):
	pass
