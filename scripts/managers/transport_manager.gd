extends Node
class_name TransportManager

# Manages resource transport between buildings via roads
# Handles pathfinding and transport calculations

signal transport_started(from: BuildingBase, to: BuildingBase, resource_id: String, amount: int)
signal transport_completed(from: BuildingBase, to: BuildingBase, resource_id: String, amount: int)

var hex_grid_manager: HexGridManager = null
var active_transports: Array = []

const BASE_TRANSPORT_TIME: float = 0.5  # Seconds per hex

func _ready():
	pass

# Initialize with grid manager
func init(grid_manager: HexGridManager):
	hex_grid_manager = grid_manager

# Find path between two buildings
func find_transport_path(from: BuildingBase, to: BuildingBase) -> Array[HexTile]:
	if not hex_grid_manager or not from or not to:
		return []

	var from_tile = from.hex_tile
	var to_tile = to.hex_tile

	if not from_tile or not to_tile:
		return []

	return hex_grid_manager.find_path(from_tile, to_tile)

# Calculate transport time based on distance and speed
func calculate_transport_time(distance: int, speed: float = 1.0) -> float:
	return (distance * BASE_TRANSPORT_TIME) / speed

# Start transport of resources
func start_transport(from: BuildingBase, to: BuildingBase, resource_id: String, amount: int):
	var path = find_transport_path(from, to)
	if path.is_empty():
		return false

	# Check if source has resources
	if not from.has_resource(resource_id, amount):
		return false

	# Remove from source
	if not from.remove_resource(resource_id, amount):
		return false

	# Calculate transport time
	var distance = path.size()
	var transport_time = calculate_transport_time(distance)

	# Create transport data
	var transport = {
		"from": from,
		"to": to,
		"resource_id": resource_id,
		"amount": amount,
		"time_remaining": transport_time,
		"path": path
	}

	active_transports.append(transport)
	transport_started.emit(from, to, resource_id, amount)

	return true

# Update active transports
func update_transports(delta: float):
	var completed = []

	for transport in active_transports:
		transport["time_remaining"] -= delta

		if transport["time_remaining"] <= 0:
			_complete_transport(transport)
			completed.append(transport)

	# Remove completed transports
	for transport in completed:
		active_transports.erase(transport)

# Complete a transport
func _complete_transport(transport: Dictionary):
	var to = transport["to"]
	var resource_id = transport["resource_id"]
	var amount = transport["amount"]

	# Add to destination (if it's a factory with input storage)
	if to is Factory:
		to.add_input_resource(resource_id, amount)
	else:
		to.add_resource(resource_id, amount)

	transport_completed.emit(transport["from"], to, resource_id, amount)

# Get active transport count
func get_active_transport_count() -> int:
	return active_transports.size()

# Clear all transports
func clear_transports():
	active_transports.clear()
