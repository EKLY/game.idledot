extends Control

@onready var money_label: Label = $HUD/MoneyLabel
@onready var trend_label: Label = $HUD/TrendLabel
@onready var income_label: Label = $HUD/IncomeLabel
@onready var offline_label: Label = $HUD/OfflineLabel
@onready var map_container: Control = $MapContainer
@onready var map_root: Control = $MapContainer/MapRoot
@onready var grid: GridContainer = $MapContainer/MapRoot/Grid
@onready var grid_lines: Control = $MapContainer/MapRoot/GridLines
@onready var bottom_sheet: PanelContainer = $BottomSheet
@onready var sheet_icon: TextureRect = $BottomSheet/SheetHBox/Icon
@onready var sheet_name: Label = $BottomSheet/SheetHBox/RightVBox/HeaderRow/NameLabel
@onready var sheet_level: Label = $BottomSheet/SheetHBox/RightVBox/LevelLabel
@onready var sheet_income: Label = $BottomSheet/SheetHBox/RightVBox/IncomeLabel
@onready var sheet_next_income: Label = $BottomSheet/SheetHBox/RightVBox/NextIncomeLabel
@onready var upgrade_button: Button = $BottomSheet/SheetHBox/RightVBox/UpgradeRow/UpgradeButton
@onready var qty_x1: Button = $BottomSheet/SheetHBox/RightVBox/QtyRow/QtyX1
@onready var qty_x10: Button = $BottomSheet/SheetHBox/RightVBox/QtyRow/QtyX10
@onready var qty_xmax: Button = $BottomSheet/SheetHBox/RightVBox/QtyRow/QtyXMax
@onready var close_button: Button = $BottomSheet/SheetHBox/RightVBox/HeaderRow/CloseButton

var _buttons: Dictionary = {}
var _tile_textures: Dictionary = {}
var _icon_textures: Dictionary = {}
var _badges: Dictionary = {}
var _cell_size: int = 64
var _sheet_tween: Tween
var _sheet_visible: bool = false
var _dragging: bool = false
var _last_drag_pos: Vector2 = Vector2.ZERO
var _selected_id: String = ""
var _upgrade_qty: int = 1

func _ready() -> void:
	_apply_theme()
	_build_map()
	_connect_signals()
	_set_qty(1)
	_refresh_ui()
	_setup_autosave()
	call_deferred("_hide_sheet_immediate")
	map_container.mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	Economy.tick(delta)
	_refresh_ui()

func _connect_signals() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	qty_x1.pressed.connect(func(): _set_qty(1))
	qty_x10.pressed.connect(func(): _set_qty(10))
	qty_xmax.pressed.connect(func(): _set_qty(-1))
	close_button.pressed.connect(_on_close_pressed)
	Events.offline_award.connect(_on_offline_award)

func _build_map() -> void:
	for child in grid.get_children():
		child.queue_free()
	_buttons.clear()
	_tile_textures.clear()
	_icon_textures.clear()
	_badges.clear()

	var cfg = ConfigService.get_config("buildings")
	var grid_cfg = cfg.get("grid", {"cols": 7, "rows": 7})
	var cols = int(grid_cfg.get("cols", 7))
	var rows = int(grid_cfg.get("rows", 7))
	grid.columns = cols
	var map_size = Vector2(cols * _cell_size, rows * _cell_size)
	grid.custom_minimum_size = map_size
	grid_lines.custom_minimum_size = map_size
	map_root.custom_minimum_size = map_size
	grid_lines.set("cols", cols)
	grid_lines.set("rows", rows)
	grid_lines.set("cell_size", _cell_size)
	grid_lines.queue_redraw()

	var by_pos := {}
	for b in Economy.get_buildings():
		var tile = b.get("tile", {})
		var key = "%d,%d" % [int(tile.get("x", -1)), int(tile.get("y", -1))]
		by_pos[key] = b

	for y in range(rows):
		for x in range(cols):
			var btn = TextureButton.new()
			btn.custom_minimum_size = Vector2(_cell_size, _cell_size)
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_filter = Control.MOUSE_FILTER_PASS
			var key = "%d,%d" % [x, y]
			if by_pos.has(key):
				var b = by_pos[key]
				var id = b.get("id", "")
				_apply_tile_texture(btn, id)
				btn.pressed.connect(func(): _on_tile_pressed(id))
				_buttons[id] = btn
				var badge = Label.new()
				badge.text = ""
				badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				badge.anchor_left = 0.0
				badge.anchor_top = 0.0
				badge.anchor_right = 1.0
				badge.anchor_bottom = 1.0
				badge.offset_left = 0.0
				badge.offset_top = 0.0
				badge.offset_right = 0.0
				badge.offset_bottom = 0.0
				btn.add_child(badge)
				_badges[id] = badge
			else:
				btn.disabled = true
				btn.texture_normal = null
			grid.add_child(btn)

func _select_first_unlocked() -> void:
	for b in Economy.get_buildings():
		var id = b.get("id", "")
		if _is_unlocked(b):
			_selected_id = id
			return

func _on_tile_pressed(building_id: String) -> void:
	_selected_id = building_id
	Events.emit_signal("building_selected", building_id)
	_refresh_ui()
	_show_sheet()

func _refresh_ui() -> void:
	money_label.text = "Money: %s" % _fmt(Economy.money)
	trend_label.text = "Trend: %.2f" % Economy.trend
	income_label.text = "Income/sec: %s" % _fmt(Economy.income_per_sec)
	_update_buttons()
	_update_sheet()

func _update_buttons() -> void:
	for b in Economy.get_buildings():
		var id = b.get("id", "")
		if not _buttons.has(id):
			continue
		var btn: TextureButton = _buttons[id]
		var unlocked = _is_unlocked(b)
		var cost = Economy.get_upgrade_cost(id)
		var can_upgrade = unlocked and Economy.money >= cost and cost > 0.0
		btn.disabled = not unlocked
		btn.modulate = _tile_color(unlocked, can_upgrade)
		if _badges.has(id):
			var badge: Label = _badges[id]
			badge.text = _tile_badge_text(unlocked, can_upgrade)
			badge.visible = badge.text != ""

func _update_sheet() -> void:
	if _selected_id == "":
		sheet_icon.texture = null
		sheet_name.text = "Select a building"
		sheet_level.text = ""
		sheet_income.text = ""
		sheet_next_income.text = ""
		upgrade_button.disabled = true
		return

	var b = Economy.get_building_by_id(_selected_id)
	if b.is_empty():
		return
	var level = Economy.get_level(_selected_id)
	var name = b.get("name", _selected_id)
	var cost = Economy.get_upgrade_cost(_selected_id)
	_apply_icon_texture(_selected_id)

	sheet_name.text = name
	sheet_level.text = "Level: %d" % level
	var curr = _building_income_per_sec(b, level)
	var next = _building_income_per_sec(b, level + 1)
	sheet_income.text = "Income/sec: %s" % _fmt(curr)
	sheet_next_income.text = "Next: %s" % _fmt(next)

	upgrade_button.text = "Upgrade (%s)" % _fmt(cost)
	upgrade_button.disabled = not _is_unlocked(b) or Economy.money < cost

func _building_income_per_sec(b: Dictionary, level: int) -> float:
	if level <= 0:
		return 0.0
	var output = b.get("output", {})
	if output.get("type", "money") != "money":
		return 0.0
	var base = float(output.get("basePerSec", 0.0))
	var rate = float(output.get("rate", 1.0))
	var raw = base * pow(rate, level)
	var trend_scale = b.get("trendScaling", {})
	if trend_scale.get("enabled", false):
		var weight = float(trend_scale.get("weight", 1.0))
		return raw * Economy.trend * weight
	return raw

func _on_upgrade_pressed() -> void:
	if _selected_id == "":
		return
	if _upgrade_qty == -1:
		while Economy.upgrade(_selected_id):
			pass
		return
	var count = _upgrade_qty
	for i in range(count):
		if not Economy.upgrade(_selected_id):
			break

func _set_qty(qty: int) -> void:
	_upgrade_qty = qty
	qty_x1.disabled = qty == 1
	qty_x10.disabled = qty == 10
	qty_xmax.disabled = qty == -1

func _setup_autosave() -> void:
	var t = Timer.new()
	t.wait_time = 10.0
	t.autostart = true
	t.one_shot = false
	t.timeout.connect(SaveService.save)
	add_child(t)

func _on_offline_award(amount: float, seconds: float) -> void:
	if amount <= 0.0:
		return
	offline_label.text = "Offline: +%s (%ds)" % [_fmt(amount), int(seconds)]

func _exit_tree() -> void:
	SaveService.save()

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		print("[map] touch pressed=", touch.pressed, " pos=", touch.position)
		_dragging = touch.pressed
		_last_drag_pos = touch.position
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		print("[map] touch drag pos=", drag.position)
		_apply_drag(drag.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("[map] mouse button pressed=", event.pressed, " pos=", event.position)
		_dragging = event.pressed
		_last_drag_pos = event.position
	elif event is InputEventMouseMotion and _dragging:
		print("[map] mouse drag pos=", event.position)
		_apply_drag(event.position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if _point_in_map(touch.position):
			print("[map] unhandled touch pressed=", touch.pressed, " pos=", touch.position)
			_dragging = touch.pressed
			_last_drag_pos = touch.position
		elif not touch.pressed:
			_dragging = false
	elif event is InputEventScreenDrag:
		if _dragging:
			var drag = event as InputEventScreenDrag
			print("[map] unhandled touch drag pos=", drag.position)
			_apply_drag(drag.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _point_in_map(event.position):
			print("[map] unhandled mouse pressed pos=", event.position)
			_dragging = true
			_last_drag_pos = event.position
		elif not event.pressed:
			print("[map] unhandled mouse released pos=", event.position)
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		print("[map] unhandled mouse drag pos=", event.position)
		_apply_drag(event.position)

func _apply_drag(pos: Vector2) -> void:
	var delta = pos - _last_drag_pos
	print("[map] apply drag delta=", delta)
	_last_drag_pos = pos
	var view = map_container.size
	var map_size = map_root.custom_minimum_size
	var min_x = min(0.0, view.x - map_size.x)
	var min_y = min(0.0, view.y - map_size.y)
	var new_pos = map_root.position + delta
	new_pos.x = clamp(new_pos.x, min_x, 0.0)
	new_pos.y = clamp(new_pos.y, min_y, 0.0)
	map_root.position = new_pos

func _point_in_map(pos: Vector2) -> bool:
	return map_container.get_global_rect().has_point(pos)

func _on_close_pressed() -> void:
	_hide_sheet()

func _hide_sheet_immediate() -> void:
	_sheet_visible = false
	var view_h = get_viewport_rect().size.y
	bottom_sheet.position.y = view_h

func _show_sheet() -> void:
	if _sheet_visible:
		return
	_sheet_visible = true
	_animate_sheet(true)

func _hide_sheet() -> void:
	if not _sheet_visible:
		return
	_sheet_visible = false
	_animate_sheet(false)

func _animate_sheet(show: bool) -> void:
	if _sheet_tween and _sheet_tween.is_running():
		_sheet_tween.kill()
	_sheet_tween = create_tween()
	var view_h = get_viewport_rect().size.y
	var sheet_h = max(160.0, bottom_sheet.size.y)
	var target_y = view_h - sheet_h if show else view_h
	_sheet_tween.tween_property(bottom_sheet, "position:y", target_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _is_unlocked(b: Dictionary) -> bool:
	var unlock = b.get("unlock", {"type": "start"})
	var t = unlock.get("type", "start")
	if t == "start":
		return true
	if t == "money":
		return Economy.money >= float(unlock.get("moneyRequired", 0.0))
	if t == "trend":
		return Economy.trend >= float(unlock.get("trendRequired", 0.0))
	if t == "level":
		var other = unlock.get("buildingId", "")
		var req = int(unlock.get("levelRequired", 0))
		return Economy.get_level(other) >= req
	if t == "mission":
		return true
	return true

func _fmt(value: float) -> String:
	return String.num(value, 2)

func _apply_theme() -> void:
	var theme = ThemeHelper.build_theme()
	self.theme = theme

func _apply_tile_texture(btn: TextureButton, building_id: String) -> void:
	var tex = _load_tile_texture(building_id)
	if tex != null:
		btn.texture_normal = tex
		btn.texture_disabled = tex

func _apply_icon_texture(building_id: String) -> void:
	var tex = _load_icon_texture(building_id)
	sheet_icon.texture = tex

func _load_tile_texture(building_id: String) -> Texture2D:
	if _tile_textures.has(building_id):
		return _tile_textures[building_id]
	var path = "res://assets/sprites/buildings/%s_tile.png" % building_id.to_lower()
	if ResourceLoader.exists(path):
		var tex = load(path)
		_tile_textures[building_id] = tex
		return tex
	return null

func _load_icon_texture(building_id: String) -> Texture2D:
	if _icon_textures.has(building_id):
		return _icon_textures[building_id]
	var path = "res://assets/sprites/buildings/%s.png" % building_id.to_lower()
	if ResourceLoader.exists(path):
		var tex = load(path)
		_icon_textures[building_id] = tex
		return tex
	return null

func _tile_color(unlocked: bool, can_upgrade: bool) -> Color:
	if not unlocked:
		return Color(0.5, 0.5, 0.5, 0.8)
	if can_upgrade:
		return Color(1.05, 1.05, 1.05, 1.0)
	return Color(0.9, 0.9, 0.9, 1.0)

func _tile_badge_text(unlocked: bool, can_upgrade: bool) -> String:
	if not unlocked:
		return "LOCK"
	if can_upgrade:
		return "UP"
	return ""
