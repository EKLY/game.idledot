extends Node
class_name SaveLoadManager

# Manages game save/load and offline earnings calculation

signal game_saved()
signal game_loaded()
signal offline_earnings_calculated(amount: int, minutes: float)

const SAVE_FILE_PATH: String = "user://savegame.json"

var last_save_time: float = 0.0

func _ready():
	pass

# Save game state
func save_game(hex_grid: HexGridManager, economy: EconomyManager, production: ProductionManager) -> bool:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"money": economy.money,
		"total_earnings": economy.total_earnings,
		"tiles": [],
		"buildings": []
	}

	# Save tiles with buildings
	for tile in hex_grid.get_all_tiles():
		if tile.building:
			var tile_data = {
				"q": tile.q,
				"r": tile.r,
				"terrain": tile.terrain_type,
				"building": tile.building.get_save_data()
			}
			save_data["tiles"].append(tile_data)

	# Convert to JSON
	var json_string = JSON.stringify(save_data, "\t")

	# Write to file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		last_save_time = Time.get_unix_time_from_system()
		game_saved.emit()
		return true
	else:
		print("Error saving game: ", FileAccess.get_open_error())
		return false

# Load game state
func load_game(hex_grid: HexGridManager, economy: EconomyManager) -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("Save file does not exist")
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("Error opening save file: ", FileAccess.get_open_error())
		return false

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error parsing save file")
		return false

	var save_data = json.data

	# Calculate offline earnings
	var save_time = save_data.get("timestamp", 0)
	var current_time = Time.get_unix_time_from_system()
	var offline_seconds = current_time - save_time
	var offline_minutes = offline_seconds / 60.0

	if offline_minutes > 0:
		var offline_earnings = economy.calculate_offline_earnings(offline_minutes)
		economy.award_offline_earnings(offline_earnings)
		offline_earnings_calculated.emit(offline_earnings, offline_minutes)

	# Restore economy
	economy.money = save_data.get("money", 1000)
	economy.total_earnings = save_data.get("total_earnings", 0)
	economy.money_changed.emit(economy.money)

	# Restore buildings
	for tile_data in save_data.get("tiles", []):
		var q = tile_data["q"]
		var r = tile_data["r"]
		var tile = hex_grid.get_tile_at(q, r)

		if tile:
			var building_data = tile_data["building"]
			_restore_building(tile, building_data)

	game_loaded.emit()
	return true

# Restore a building from save data
func _restore_building(tile: HexTile, building_data: Dictionary):
	var building_id = building_data.get("building_id", "")

	if building_id.is_empty():
		return

	# Create appropriate building type
	var building: BuildingBase = null

	if building_id.contains("mine"):
		building = Mine.new()
	elif building_id.contains("farm"):
		building = Farm.new()
	elif building_id == "factory":
		building = Factory.new()
	elif building_id == "road":
		building = Road.new()

	if building:
		# Initialize and load data
		var init_data = Buildings.get_building(building_id)
		init_data["id"] = building_id
		building.init(init_data)
		building.load_from_save(building_data)

		# Place on tile
		tile.place_building(building)

# Check if save file exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# Delete save file
func delete_save_file() -> bool:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		return true
	return false

# Auto-save game (call periodically)
func auto_save(hex_grid: HexGridManager, economy: EconomyManager, production: ProductionManager):
	save_game(hex_grid, economy, production)
