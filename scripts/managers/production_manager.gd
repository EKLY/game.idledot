extends Node
class_name ProductionManager

# Manages all production cycles in the game
# Updates buildings and handles production logic

signal production_update()

var buildings: Array[BuildingBase] = []

func _ready():
	pass

# Register a building for production management
func register_building(building: BuildingBase):
	if building not in buildings:
		buildings.append(building)

# Unregister a building
func unregister_building(building: BuildingBase):
	buildings.erase(building)

# Update all productions (called by main game loop)
func update_productions(_delta: float):
	for building in buildings:
		if building and building.is_active and building.is_producing:
			_check_production_status(building)

	production_update.emit()

# Check production status and handle storage
func _check_production_status(building: BuildingBase):
	# For mines and farms, check if storage is full
	if building is Mine or building is Farm:
		if building.is_storage_full():
			building.stop_production()
		elif not building.is_producing:
			building.start_production()

	# For factories, check if inputs are available
	elif building is Factory:
		if not building.is_producing and building._has_required_inputs():
			building.start_production()

# Calculate delivery time between two buildings
func calculate_delivery_time(from: BuildingBase, to: BuildingBase, transport_mgr: TransportManager) -> float:
	if not from or not to:
		return -1.0

	# Get path
	var path = transport_mgr.find_transport_path(from, to)
	if path.is_empty():
		return -1.0

	# Calculate transport time
	var distance = path.size()
	var transport_time = transport_mgr.calculate_transport_time(distance)

	return transport_time

# Get production statistics
func get_production_stats() -> Dictionary:
	var stats = {
		"total_buildings": buildings.size(),
		"producing": 0,
		"idle": 0,
		"full_storage": 0
	}

	for building in buildings:
		if building.is_producing:
			stats["producing"] += 1
		else:
			stats["idle"] += 1

		if building.is_storage_full():
			stats["full_storage"] += 1

	return stats

# Clear all buildings
func clear_buildings():
	buildings.clear()
