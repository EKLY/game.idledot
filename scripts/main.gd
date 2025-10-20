extends Node2D

# Main game script for mobile portrait mode
# Orchestrates all managers and game systems

@onready var camera: CameraController = $Camera2D
@onready var tile_container: Node2D = $TileContainer
@onready var building_container: Node2D = $BuildingContainer

# Managers
@onready var hex_grid_manager: HexGridManager = $HexGridManager
@onready var production_manager: ProductionManager = $ProductionManager
@onready var transport_manager: TransportManager = $TransportManager
@onready var economy_manager: EconomyManager = $EconomyManager
@onready var save_load_manager: SaveLoadManager = $SaveLoadManager

# UI - Top Bar
@onready var coins_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/CoinsContainer/CoinsLabel
@onready var cash_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/CashContainer/CashLabel
@onready var settings_button: TextureButton = $UI/TopBar/MarginContainer/HBoxContainer/SettingsButton

# UI - Bottom Sheet
@onready var bottom_sheet: PanelContainer = $UI/BottomSheet
@onready var tile_info_label: Label = $UI/BottomSheet/MarginContainer/VBoxContainer/TileInfoLabel
@onready var building_info_label: Label = $UI/BottomSheet/MarginContainer/VBoxContainer/BuildingInfoLabel
@onready var storage_label: Label = $UI/BottomSheet/MarginContainer/VBoxContainer/StorageLabel
@onready var build_button: Button = $UI/BottomSheet/MarginContainer/VBoxContainer/ButtonContainer/BuildButton
@onready var sell_button: Button = $UI/BottomSheet/MarginContainer/VBoxContainer/ButtonContainer/SellButton
@onready var destroy_button: Button = $UI/BottomSheet/MarginContainer/VBoxContainer/ButtonContainer/DestroyButton
@onready var close_button: Button = $UI/BottomSheet/MarginContainer/VBoxContainer/ButtonContainer/CloseButton

# UI - Quick Info
@onready var quick_info_panel: PanelContainer = $UI/QuickInfoPanel
@onready var quick_info_label: Label = $UI/QuickInfoPanel/MarginContainer/QuickInfoLabel

# Auto-save timer
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 60.0

# Bottom sheet animation
var bottom_sheet_tween: Tween = null
const BOTTOM_SHEET_SHOW_POS: float = -300.0
const BOTTOM_SHEET_HIDE_POS: float = 0.0

func _ready():
	# Initialize managers
	_setup_managers()

	# Create grid
	hex_grid_manager.create_grid(tile_container)

	# Setup camera bounds
	_setup_camera_bounds()

	# Connect signals
	_connect_signals()

	# Try to load save
	if save_load_manager.has_save_file():
		save_load_manager.load_game(hex_grid_manager, economy_manager)

	# Update UI
	_update_ui()

	# Show quick info initially
	_show_quick_info("Tap any tile to start", 3.0)

func _process(delta):
	# Update production
	production_manager.update_productions(delta)

	# Update transport
	transport_manager.update_transports(delta)

	# Auto-save
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		save_load_manager.auto_save(hex_grid_manager, economy_manager, production_manager)

func _setup_managers():
	# Initialize transport manager with grid
	transport_manager.init(hex_grid_manager)

func _connect_signals():
	# Grid manager signals
	hex_grid_manager.tile_selected.connect(_on_tile_selected)
	hex_grid_manager.tile_deselected.connect(_on_tile_deselected)

	# Economy signals
	economy_manager.money_changed.connect(_on_money_changed)
	economy_manager.cash_changed.connect(_on_cash_changed)

	# UI signals
	build_button.pressed.connect(_on_build_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	destroy_button.pressed.connect(_on_destroy_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)

	# Save/Load signals
	save_load_manager.offline_earnings_calculated.connect(_on_offline_earnings_calculated)

func _on_tile_selected(tile: HexTile):
	_update_tile_info(tile)
	_show_bottom_sheet()

func _on_tile_deselected(_tile: HexTile):
	_hide_bottom_sheet()

func _update_tile_info(tile: HexTile):
	var terrain_name = Buildings.TerrainType.keys()[tile.terrain_type]
	tile_info_label.text = "Tile (%d, %d) - %s" % [tile.q, tile.r, terrain_name]

	if tile.building:
		var info = tile.building.get_info()
		building_info_label.text = "%s" % info["name"]

		# Show storage info
		var storage_text = "Storage: "
		if tile.building is Factory:
			storage_text += "\nInput: %d/%d" % [_get_total_storage(info["input_storage"]), info["input_capacity"]]
			storage_text += "\nOutput: %d/%d" % [_get_total_storage(info["output_storage"]), info["output_capacity"]]
		else:
			storage_text += "%d/%d" % [_get_total_storage(info["storage"]), info["storage_capacity"]]

		storage_label.text = storage_text

		# Button states
		build_button.disabled = true
		sell_button.disabled = false
		destroy_button.disabled = false
	else:
		building_info_label.text = "Empty"
		storage_label.text = ""
		build_button.disabled = false
		sell_button.disabled = true
		destroy_button.disabled = true

func _get_total_storage(storage: Dictionary) -> int:
	var total = 0
	for amount in storage.values():
		total += amount
	return total

func _on_build_button_pressed():
	var selected = hex_grid_manager.selected_tile
	if not selected:
		return

	# Determine building type based on terrain
	var building_id = ""

	match selected.terrain_type:
		Buildings.TerrainType.SAND:
			building_id = "iron_mine"
		Buildings.TerrainType.FIELD:
			building_id = "wheat_farm"
		Buildings.TerrainType.EMPTY:
			building_id = "road"
		Buildings.TerrainType.WATER:
			building_id = "fishing_dock"

	if building_id.is_empty():
		return

	# Check cost
	var cost = Buildings.get_building_cost(building_id)
	if not economy_manager.can_afford(cost):
		_show_quick_info("Not enough money!", 2.0)
		return

	# Spend money
	economy_manager.spend_money(cost)

	# Create building
	_create_building(selected, building_id)

	# Update UI
	_update_tile_info(selected)
	_show_quick_info("Built " + Buildings.get_building_name(building_id), 2.0)

func _on_sell_button_pressed():
	var selected = hex_grid_manager.selected_tile
	if not selected or not selected.building:
		return

	economy_manager.auto_sell_from_building(selected.building)
	_update_tile_info(selected)
	_show_quick_info("Resources sold!", 2.0)

func _on_destroy_button_pressed():
	var selected = hex_grid_manager.selected_tile
	if not selected or not selected.building:
		return

	# Remove building
	production_manager.unregister_building(selected.building)
	selected.remove_building()

	# Update UI
	_update_tile_info(selected)
	_show_quick_info("Building destroyed", 2.0)

func _on_close_button_pressed():
	hex_grid_manager.deselect_current_tile()

func _on_settings_button_pressed():
	# TODO: Show settings menu
	_show_quick_info("Settings coming soon", 2.0)

func _create_building(tile: HexTile, building_id: String):
	var building: BuildingBase = null
	# Duplicate to avoid read-only error
	var building_data = Buildings.get_building(building_id).duplicate()
	building_data["id"] = building_id

	# Create appropriate building type
	if building_id.contains("mine"):
		building = Mine.new()
	elif building_id.contains("farm"):
		building = Farm.new()
	elif building_id == "factory":
		building = Factory.new()
	elif building_id == "road":
		building = Road.new()
	elif building_id.contains("fishing") or building_id.contains("water"):
		building = Mine.new()

	if building:
		building.init(building_data)
		building.hex_tile = tile
		tile.place_building(building)

		# Register with production manager
		production_manager.register_building(building)

func _on_money_changed(new_amount: int):
	coins_label.text = _format_currency(new_amount)

func _on_cash_changed(new_amount: int):
	cash_label.text = _format_currency(new_amount)

# Format currency with thousands separator
func _format_currency(amount: int) -> String:
	var text = str(amount)
	var result = ""
	var count = 0

	# Add commas for thousands
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[i] + result
		count += 1

	return result

func _on_offline_earnings_calculated(amount: int, minutes: float):
	var hours = int(minutes / 60)
	var mins = int(minutes) % 60
	_show_quick_info("Offline: +$%d (%dh %dm)" % [amount, hours, mins], 5.0)

func _update_ui():
	_on_money_changed(economy_manager.money)
	_on_cash_changed(economy_manager.cash)

# Show bottom sheet with animation
func _show_bottom_sheet():
	if bottom_sheet_tween:
		bottom_sheet_tween.kill()

	bottom_sheet.visible = true
	bottom_sheet_tween = create_tween()
	bottom_sheet_tween.tween_property(bottom_sheet, "offset_top", BOTTOM_SHEET_SHOW_POS, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Hide bottom sheet with animation
func _hide_bottom_sheet():
	if bottom_sheet_tween:
		bottom_sheet_tween.kill()

	bottom_sheet_tween = create_tween()
	bottom_sheet_tween.tween_property(bottom_sheet, "offset_top", BOTTOM_SHEET_HIDE_POS, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	bottom_sheet_tween.finished.connect(func(): bottom_sheet.visible = false)

# Show quick info message
func _show_quick_info(message: String, duration: float = 2.0):
	quick_info_label.text = message
	quick_info_panel.visible = true

	# Auto-hide after duration
	await get_tree().create_timer(duration).timeout
	quick_info_panel.visible = false

# Setup camera bounds based on grid size
func _setup_camera_bounds():
	var grid_w = hex_grid_manager.grid_width
	var grid_h = hex_grid_manager.grid_height
	var hex_size = hex_grid_manager.hex_size
	var perspective = 0.5  # Same as tile perspective_scale

	# Calculate corner positions of the grid
	# Top-left corner: (-grid_w, -grid_h)
	# Top-right corner: (+grid_w, -grid_h)
	# Bottom-left corner: (-grid_w, +grid_h)
	# Bottom-right corner: (+grid_w, +grid_h)

	var top_left = HexTile.hex_to_pixel(-grid_w, -grid_h, hex_size, perspective)
	var top_right = HexTile.hex_to_pixel(grid_w, -grid_h, hex_size, perspective)
	var bottom_left = HexTile.hex_to_pixel(-grid_w, grid_h, hex_size, perspective)
	var bottom_right = HexTile.hex_to_pixel(grid_w, grid_h, hex_size, perspective)

	# Find actual min/max bounds
	var min_x = min(min(top_left.x, top_right.x), min(bottom_left.x, bottom_right.x))
	var max_x = max(max(top_left.x, top_right.x), max(bottom_left.x, bottom_right.x))
	var min_y = min(min(top_left.y, top_right.y), min(bottom_left.y, bottom_right.y))
	var max_y = max(max(top_left.y, top_right.y), max(bottom_left.y, bottom_right.y))

	# Add margin of 1.5 tiles (compromise between 1-2 tiles as requested)
	var margin = hex_size * 1.5

	var bounds_min = Vector2(min_x - margin, min_y - margin)
	var bounds_max = Vector2(max_x + margin, max_y + margin)

	# Set camera bounds
	camera.set_bounds(bounds_min, bounds_max)

	print("Camera bounds set: min=%s, max=%s" % [bounds_min, bounds_max])

# Save game on exit
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_load_manager.save_game(hex_grid_manager, economy_manager, production_manager)
		get_tree().quit()
