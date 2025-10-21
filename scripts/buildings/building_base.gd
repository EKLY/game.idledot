extends Node2D
class_name BuildingBase

# Base class for all buildings in the game
# Handles common properties and methods for production, storage, and resource management

signal production_completed(resource_id: String, amount: int)
signal storage_changed(resource_id: String, amount: int)
signal storage_full(resource_id: String)

# Building identification
var building_id: String = ""
var building_name: String = ""

# Production properties
var production_time: float = 0.0
var production_timer: float = 0.0
var is_producing: bool = false

# Storage
var storage: Dictionary = {}  # {resource_id: amount}
var storage_capacity: int = 50

# Health and status
var health: float = 100.0
var max_health: float = 100.0
var is_active: bool = true

# Tile reference
var hex_tile: HexTile = null

# Visual
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready():
	_setup()

func _process(delta):
	if is_active and is_producing:
		_update_production(delta)

# Initialize building with data
func init(building_data: Dictionary):
	building_id = building_data.get("id", "")
	building_name = building_data.get("name", "")
	production_time = building_data.get("production_time", 0.0)
	storage_capacity = building_data.get("storage", 50)

# Setup building (override in child classes)
func _setup():
	pass

# Update production (override in child classes)
func _update_production(delta: float):
	pass

# Start production
func start_production():
	if not is_producing:
		is_producing = true
		production_timer = 0.0

# Stop production
func stop_production():
	is_producing = false
	production_timer = 0.0

# Add resource to storage
func add_resource(resource_id: String, amount: int) -> bool:
	var current_amount = storage.get(resource_id, 0)
	var new_amount = current_amount + amount

	if new_amount > storage_capacity:
		storage_full.emit(resource_id)
		return false

	storage[resource_id] = new_amount
	storage_changed.emit(resource_id, new_amount)
	return true

# Remove resource from storage
func remove_resource(resource_id: String, amount: int) -> bool:
	var current_amount = storage.get(resource_id, 0)

	if current_amount < amount:
		return false

	storage[resource_id] = current_amount - amount
	storage_changed.emit(resource_id, storage[resource_id])
	return true

# Check if resource is available in storage
func has_resource(resource_id: String, amount: int) -> bool:
	return storage.get(resource_id, 0) >= amount

# Get resource amount in storage
func get_resource_amount(resource_id: String) -> int:
	return storage.get(resource_id, 0)

# Check if storage is full
func is_storage_full() -> bool:
	var total = 0
	for amount in storage.values():
		total += amount
	return total >= storage_capacity

# Check if storage is empty
func is_storage_empty() -> bool:
	var total = 0
	for amount in storage.values():
		total += amount
	return total == 0

# Get available storage space
func get_available_storage() -> int:
	var used = 0
	for amount in storage.values():
		used += amount
	return storage_capacity - used

# Get storage fill percentage
func get_storage_percentage() -> float:
	var total = 0
	for amount in storage.values():
		total += amount
	return (float(total) / float(storage_capacity)) * 100.0

# Damage building
func take_damage(amount: float):
	health -= amount
	if health <= 0:
		health = 0
		destroy()

# Repair building
func repair(amount: float):
	health = min(health + amount, max_health)

# Destroy building
func destroy():
	is_active = false
	queue_free()

# Get save data
func get_save_data() -> Dictionary:
	return {
		"building_id": building_id,
		"position": {"x": position.x, "y": position.y},
		"storage": storage,
		"health": health,
		"is_producing": is_producing,
		"production_timer": production_timer
	}

# Load from save data
func load_from_save(data: Dictionary):
	storage = data.get("storage", {})
	health = data.get("health", max_health)
	is_producing = data.get("is_producing", false)
	production_timer = data.get("production_timer", 0.0)

# Get building info for UI
func get_info() -> Dictionary:
	return {
		"id": building_id,
		"name": building_name,
		"health": health,
		"max_health": max_health,
		"storage": storage,
		"storage_capacity": storage_capacity,
		"is_producing": is_producing,
		"production_time": production_time,
		"production_progress": (production_timer / production_time * 100.0) if production_time > 0 else 0.0
	}
