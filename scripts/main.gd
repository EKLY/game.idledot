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
@onready var bottom_sheet = $UI/BottomSheet

# UI - Quick Info
@onready var quick_info_panel: PanelContainer = $UI/QuickInfoPanel
@onready var quick_info_label: Label = $UI/QuickInfoPanel/MarginContainer/QuickInfoLabel

# Auto-save timer
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 60.0

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

	# Bottom sheet signals
	bottom_sheet.build_requested.connect(_on_build_requested)
	bottom_sheet.upgrade_requested.connect(_on_upgrade_requested)
	bottom_sheet.sell_requested.connect(_on_sell_requested)
	bottom_sheet.destroy_requested.connect(_on_destroy_requested)
	bottom_sheet.close_requested.connect(_on_close_requested)

	# UI signals
	settings_button.pressed.connect(_on_settings_button_pressed)

	# Save/Load signals
	save_load_manager.offline_earnings_calculated.connect(_on_offline_earnings_calculated)

func _on_tile_selected(tile: HexTile):
	bottom_sheet.update_tile_info(tile, economy_manager.money)
	bottom_sheet.show_sheet()

func _on_tile_deselected(_tile: HexTile):
	bottom_sheet.hide_sheet()

func _on_build_requested(building_id: String):
	var selected = hex_grid_manager.selected_tile
	if not selected:
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
	bottom_sheet.update_tile_info(selected, economy_manager.money)
	_show_quick_info("Built " + Buildings.get_building_name(building_id), 2.0)

func _on_upgrade_requested(building_id: String):
	var selected = hex_grid_manager.selected_tile
	if not selected or not selected.building:
		return

	# Check cost
	var cost = Buildings.get_building_cost(building_id)
	if not economy_manager.can_afford(cost):
		_show_quick_info("Not enough money!", 2.0)
		return

	# Spend money
	economy_manager.spend_money(cost)

	# Remove old building
	production_manager.unregister_building(selected.building)
	selected.remove_building()

	# Create upgraded building
	_create_building(selected, building_id)

	# Update UI
	bottom_sheet.update_tile_info(selected, economy_manager.money)
	_show_quick_info("Upgraded to " + Buildings.get_building_name(building_id), 2.0)

func _on_sell_requested():
	var selected = hex_grid_manager.selected_tile
	if not selected or not selected.building:
		return

	economy_manager.auto_sell_from_building(selected.building)
	bottom_sheet.update_tile_info(selected, economy_manager.money)
	_show_quick_info("Resources sold!", 2.0)

func _on_destroy_requested():
	var selected = hex_grid_manager.selected_tile
	if not selected:
		return

	var destroyed_name = ""

	# Check if there's a building to destroy
	if selected.building:
		# Destroy building
		destroyed_name = selected.building.building_name
		production_manager.unregister_building(selected.building)
		selected.remove_building()

		# Also clear the natural structure (if building was on top of one)
		# This makes the tile completely empty after destroying a building
		if selected.has_object():
			selected.remove_object()
	# Check if there's a natural structure to destroy
	elif selected.has_object():
		# Destroy natural structure
		destroyed_name = Buildings.get_object_name(selected.object_type)
		selected.remove_object()

	# Update UI
	bottom_sheet.update_tile_info(selected, economy_manager.money)
	if not destroyed_name.is_empty():
		_show_quick_info("%s destroyed" % destroyed_name, 2.0)
	else:
		_show_quick_info("Nothing to destroy", 2.0)

func _on_close_requested():
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
