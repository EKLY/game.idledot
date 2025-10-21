extends PanelContainer

# Bottom Sheet UI Controller - Redesigned
# Displays tile info, buildable buildings, upgrades, production info with progress bar, and tools

signal build_requested(building_id: String)
signal upgrade_requested(building_id: String)
signal sell_requested()
signal destroy_requested()
signal close_requested()

# Header
@onready var tile_name_label: Label = $MarginContainer/VBoxContainer/HeaderSection/TileNameLabel
@onready var location_label: Label = $MarginContainer/VBoxContainer/HeaderSection/LocationLabel

# Detail
@onready var detail_label: Label = $MarginContainer/VBoxContainer/DetailLabel

# Build/Upgrade section
@onready var build_upgrade_section: VBoxContainer = $MarginContainer/VBoxContainer/BuildUpgradeSection
@onready var build_container: HBoxContainer = $MarginContainer/VBoxContainer/BuildUpgradeSection/BuildScroll/BuildContainer

# Production section
@onready var production_section: PanelContainer = $MarginContainer/VBoxContainer/ProductionSection
@onready var production_label: Label = $MarginContainer/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/ProductionLabel
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/ProgressContainer/ProgressBar
@onready var time_label: Label = $MarginContainer/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/ProgressContainer/TimeLabel
@onready var storage_label: Label = $MarginContainer/VBoxContainer/ProductionSection/MarginContainer/VBoxContainer/StorageLabel

# Tools
@onready var tools_section: HBoxContainer = $MarginContainer/VBoxContainer/ToolsSection
@onready var sell_button: TextureButton = $MarginContainer/VBoxContainer/ToolsSection/SellButton
@onready var destroy_button: TextureButton = $MarginContainer/VBoxContainer/ToolsSection/DestroyButton
@onready var close_button: TextureButton = $MarginContainer/VBoxContainer/ToolsSection/CloseButton

# Buildable item scene
const BuildableItemScene = preload("res://scenes/ui/buildable_item.tscn")

# Current tile reference
var current_tile: HexTile = null
var current_money: int = 0

# Animation
var sheet_tween: Tween = null

func _ready():
	# Connect button signals
	sell_button.pressed.connect(_on_sell_pressed)
	destroy_button.pressed.connect(_on_destroy_pressed)
	close_button.pressed.connect(_on_close_pressed)

func show_sheet():
	if sheet_tween:
		sheet_tween.kill()

	visible = true

	# Wait one frame for the UI to update its size
	await get_tree().process_frame

	# Calculate the actual height of the content
	var content_height = size.y

	# Animate from bottom (hidden) to visible position
	var start_pos = 0.0
	var end_pos = -content_height

	offset_top = start_pos
	sheet_tween = create_tween()
	sheet_tween.tween_property(self, "offset_top", end_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_sheet():
	if sheet_tween:
		sheet_tween.kill()

	sheet_tween = create_tween()
	sheet_tween.tween_property(self, "offset_top", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	sheet_tween.finished.connect(func(): visible = false)

func update_tile_info(tile: HexTile, money: int):
	current_tile = tile
	current_money = money

	if not tile:
		return

	# Update header - Location
	location_label.text = "(%d, %d)" % [tile.q, tile.r]

	# Check what's on the tile
	if tile.building:
		# Tile has a building on it
		_show_existing_building_info(tile)
	elif tile.has_object():
		# Tile has a natural structure
		_show_natural_structure_info(tile)
	else:
		# Empty tile
		_show_empty_tile_info(tile)

func _show_empty_tile_info(tile: HexTile):
	var terrain_name = Buildings.TerrainType.keys()[tile.terrain_type]

	# Header
	tile_name_label.text = "Empty Tile"

	# Detail
	detail_label.text = "Empty %s terrain" % terrain_name
	detail_label.visible = false  # Hide detail for empty tiles

	# Show buildable section
	build_upgrade_section.visible = true
	_populate_buildable_buildings(tile)

	# Hide production section
	production_section.visible = false

	# Show tools section but hide sell/destroy buttons
	tools_section.visible = true
	sell_button.visible = false
	destroy_button.visible = false
	close_button.modulate = Color.WHITE

func _show_natural_structure_info(tile: HexTile):
	# Get structure info
	var structure_id = tile.object_type
	var structure_name = Buildings.get_object_name(structure_id)
	var structure_desc = Buildings.get_building_description(structure_id)

	# Header
	tile_name_label.text = structure_name

	# Detail
	detail_label.text = structure_desc if structure_desc else "Natural structure"

	# Show buildable section - what can be built on this structure
	build_upgrade_section.visible = true
	_populate_buildable_on_structure(structure_id)

	# Hide production section
	production_section.visible = false

	# Show tools section with destroy button
	tools_section.visible = true
	sell_button.visible = false
	destroy_button.visible = true
	destroy_button.disabled = false
	destroy_button.modulate = Color.WHITE
	close_button.modulate = Color.WHITE

func _show_existing_building_info(tile: HexTile):
	var info = tile.building.get_info()

	# Header
	tile_name_label.text = info["name"]

	# Detail
	var building_id = tile.building.building_id if "building_id" in tile.building else ""
	var building_desc = Buildings.get_building_description(building_id)
	detail_label.text = building_desc if building_desc else "Building"

	# Check if there are upgrades available
	var upgrades = Buildings.get_upgrades_for(building_id)
	if upgrades.size() > 0:
		build_upgrade_section.visible = true
		_populate_upgrades(upgrades)
	else:
		build_upgrade_section.visible = false
		_clear_container(build_container)

	# Show production info with progress bar
	production_section.visible = true
	_update_production_info(tile.building, info)

	# Show all tools buttons
	tools_section.visible = true
	sell_button.visible = true
	var has_resources = _get_total_storage(info.get("storage", {})) > 0
	sell_button.disabled = not has_resources
	sell_button.modulate = Color.WHITE if has_resources else Color(0.5, 0.5, 0.5, 1.0)
	destroy_button.visible = true
	destroy_button.disabled = false
	destroy_button.modulate = Color.WHITE
	close_button.modulate = Color.WHITE

func _populate_buildable_buildings(tile: HexTile):
	_clear_container(build_container)

	# Get buildings that can be built on this terrain
	var buildable_ids = Buildings.get_buildings_for_terrain(tile.terrain_type)

	if buildable_ids.size() == 0:
		build_upgrade_section.visible = false
		return

	# Create buildable item for each building
	for building_id in buildable_ids:
		_create_buildable_item(building_id, false)

func _populate_buildable_on_structure(structure_id: String):
	_clear_container(build_container)

	var buildable_ids = Buildings.get_buildable_on_structure(structure_id)

	if buildable_ids.size() == 0:
		build_upgrade_section.visible = false
		return

	# Create buildable item for each building
	for building_id in buildable_ids:
		_create_buildable_item(building_id, false)

func _populate_upgrades(upgrade_ids: Array):
	_clear_container(build_container)

	for building_id in upgrade_ids:
		_create_buildable_item(building_id, true)

func _create_buildable_item(building_id: String, is_upgrade: bool):
	var item = BuildableItemScene.instantiate()
	build_container.add_child(item)

	# Setup item
	item.setup(building_id)

	# Check affordability
	var cost = Buildings.get_building_cost(building_id)
	item.set_affordable(current_money >= cost)

	# Connect signal
	if is_upgrade:
		item.item_clicked.connect(_on_upgrade_item_clicked)
	else:
		item.item_clicked.connect(_on_buildable_item_clicked)

func _update_production_info(building: BuildingBase, info: Dictionary):
	# Show production info
	var production_text = ""
	var progress = 0.0
	var time_remaining = 0.0

	if info.has("production"):
		var production_item = info.get("production", "unknown")
		var production_time = info.get("production_time", 0.0)
		var production_progress = info.get("production_progress", 0.0)

		production_text = "Producing: %s" % production_item
		progress = production_progress

		# Calculate time remaining
		if production_time > 0:
			time_remaining = production_time * (1.0 - production_progress / 100.0)
	elif info.has("recipe"):
		production_text = "Processing: %s" % info.get("recipe", "None")
		progress = info.get("production_progress", 0.0)
	else:
		production_text = "No production"
		progress = 0.0

	production_label.text = production_text
	progress_bar.value = progress

	# Format time remaining
	if time_remaining > 0:
		time_label.text = "%ds" % int(time_remaining)
	else:
		time_label.text = "0s"

	# Show storage
	var storage_text = ""
	if building is Factory:
		var input_total = _get_total_storage(info.get("input_storage", {}))
		var input_capacity = info.get("input_capacity", 0)
		var output_total = _get_total_storage(info.get("output_storage", {}))
		var output_capacity = info.get("output_capacity", 0)
		storage_text = "Input: %d/%d | Output: %d/%d" % [input_total, input_capacity, output_total, output_capacity]
	else:
		var total = _get_total_storage(info.get("storage", {}))
		var capacity = info.get("storage_capacity", 0)
		storage_text = "Storage: %d / %d" % [total, capacity]

	storage_label.text = storage_text

func _get_total_storage(storage: Dictionary) -> int:
	var total = 0
	for amount in storage.values():
		total += amount
	return total

func _clear_container(container: Container):
	for child in container.get_children():
		child.queue_free()

func _on_buildable_item_clicked(building_id: String):
	build_requested.emit(building_id)

func _on_upgrade_item_clicked(building_id: String):
	upgrade_requested.emit(building_id)

func _on_sell_pressed():
	sell_requested.emit()

func _on_destroy_pressed():
	destroy_requested.emit()

func _on_close_pressed():
	close_requested.emit()
