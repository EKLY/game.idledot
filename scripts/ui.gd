extends CanvasLayer

## UI host: a fixed top bar and a bottom sheet that slides up when a map tile is
## tapped. The bottom sheet is a 3-step flow driven by the header back-arrow:
##   info   — tile details + a "Build here" button
##   list   — a 2-column grid of affordable buildings; tap one to see it
##   detail — the picked building's info (incl. footprint size) + Confirm to place
## A ghost preview runs on the map during the detail step (tap the map to reposition;
## footprint size is honoured). Content is mostly placeholder — no economy yet.

const SHEET_H := 320.0
const ANIM := 0.22
const SHEET_MARGIN := 14.0
const DETAIL_COLOR := Color(0.541, 0.498, 0.42)

@onready var _sheet: SketchBox = $Root/BottomSheet
@onready var _back_arrow: Button = $Root/BottomSheet/Margin/VBox/Header/BackArrow
@onready var _name: Label = $Root/BottomSheet/Margin/VBox/Header/HeaderText/Name
@onready var _level: Label = $Root/BottomSheet/Margin/VBox/Header/HeaderText/Level
@onready var _close: Button = $Root/BottomSheet/Margin/VBox/Header/CloseButton
@onready var _info_view: VBoxContainer = $Root/BottomSheet/Margin/VBox/InfoView
@onready var _sheet_build: Button = $Root/BottomSheet/Margin/VBox/InfoView/Build
@onready var _list_view: VBoxContainer = $Root/BottomSheet/Margin/VBox/BuildView
@onready var _grid: GridContainer = $Root/BottomSheet/Margin/VBox/BuildView/Scroll/Grid
@onready var _detail_view: VBoxContainer = $Root/BottomSheet/Margin/VBox/DetailView
@onready var _d_swatch: ColorRect = $Root/BottomSheet/Margin/VBox/DetailView/Row/DSwatch
@onready var _d_chain: Label = $Root/BottomSheet/Margin/VBox/DetailView/Row/DInfo/DChain
@onready var _d_size: Label = $Root/BottomSheet/Margin/VBox/DetailView/Row/DInfo/DSize
@onready var _d_cost: Label = $Root/BottomSheet/Margin/VBox/DetailView/Row/DInfo/DCost
@onready var _d_needs: Label = $Root/BottomSheet/Margin/VBox/DetailView/Row/DInfo/DNeeds
@onready var _d_status: Label = $Root/BottomSheet/Margin/VBox/DetailView/DStatus
@onready var _confirm: Button = $Root/BottomSheet/Margin/VBox/DetailView/Confirm
@onready var _settings: Button = $Root/TopBar/HBox/Settings
@onready var _size1: Button = $"../Dialog/Panel/Margin/VBox/SizeRow/Size1"
@onready var _size2: Button = $"../Dialog/Panel/Margin/VBox/SizeRow/Size2"
@onready var _size3: Button = $"../Dialog/Panel/Margin/VBox/SizeRow/Size3"
@onready var _recreate: Button = $"../Dialog/Panel/Margin/VBox/Recreate"

var _tween: Tween
var _open := false
var _dialog: CenterDialog
var _view := "info"
var _sel_size := 100
var _sel := Vector2i(-1, -1)
var _sel_label := "empty"

func _ready() -> void:
	var map := get_parent()
	if map.has_signal("tile_selected"):
		map.tile_selected.connect(_on_tile_selected)
	if map.has_signal("build_changed"):
		map.build_changed.connect(_on_build_changed)
	_dialog = get_node("../Dialog")
	_settings.pressed.connect(_on_settings_pressed)
	_close.pressed.connect(hide_sheet)
	_back_arrow.pressed.connect(_on_back_arrow)
	_sheet_build.pressed.connect(_enter_build_list)
	_confirm.pressed.connect(_on_confirm)
	_recreate.pressed.connect(_on_recreate)
	_size1.toggled.connect(_on_size_toggled.bind(50))
	_size2.toggled.connect(_on_size_toggled.bind(100))
	_size3.toggled.connect(_on_size_toggled.bind(150))
	_sheet.offset_top = 0.0
	_sheet.offset_bottom = SHEET_H
	show_sheet()  # open the sheet on launch (Info view, default content)

func _on_settings_pressed() -> void:
	_sync_size_buttons()
	_dialog.open("Settings")

# --- Settings: map size / recreate ----------------------------------------------

func _sync_size_buttons() -> void:
	var cur: int = get_parent().cols
	_sel_size = cur
	_size1.button_pressed = cur == 50
	_size2.button_pressed = cur == 100
	_size3.button_pressed = cur == 150

func _on_size_toggled(toggled_on: bool, size: int) -> void:
	if toggled_on:
		_sel_size = size

func _on_recreate() -> void:
	hide_sheet()
	get_parent().regenerate_map(_sel_size, _sel_size, randi())
	_dialog.close()

func _on_tile_selected(x: int, y: int) -> void:
	var world: WorldData = get_parent().world
	_sel = Vector2i(x, y)
	_sel_label = world.label_at(x, y) if world != null else "empty"
	_show_info()
	show_sheet()

# --- View switching -------------------------------------------------------------

func _set_view(v: String) -> void:
	_view = v
	_info_view.visible = v == "info"
	_list_view.visible = v == "list"
	_detail_view.visible = v == "detail"
	_back_arrow.visible = v != "info"

func _show_info() -> void:
	if get_parent().build_active:
		get_parent().exit_build_mode()
	_name.text = _display_name(_sel_label)
	_level.text = "Tile (%d, %d)" % [_sel.x, _sel.y]
	_set_view("info")

func _enter_build_list() -> void:
	if get_parent().build_active:
		get_parent().exit_build_mode()
	_name.text = "Build"
	_level.text = "Pick a building"
	_set_view("list")
	_populate_grid()

# Header back-arrow: detail -> list -> info.
func _on_back_arrow() -> void:
	if _view == "detail":
		_enter_build_list()
	elif _view == "list":
		_show_info()

func _display_name(key: String) -> String:
	match key:
		"mountain":
			return "Mountain"
		"pond":
			return "Pond"
		"tree":
			return "Forest"
		"boulder":
			return "Boulder"
		"grass":
			return "Grassland"
		"pebble":
			return "Pebbles"
	return "Empty plot"

# --- Build list (grid) ----------------------------------------------------------

# One card per AFFORDABLE building. Tapping a card opens its detail page.
func _populate_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var cat: Array = get_parent().catalog
	var money: float = get_parent().money
	for i in cat.size():
		var e: Dictionary = cat[i]
		if e.cost > money:
			continue  # only show what the player can afford
		_grid.add_child(_make_card(e, i))

# A card is a Button (whole thing tappable) with an ignore-mouse overlay:
# colour swatch + three lines (name / production detail / cost).
func _make_card(e: Dictionary, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 76)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var swatch := ColorRect.new()
	swatch.color = e.color
	swatch.custom_minimum_size = Vector2(32, 32)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	col.add_child(_card_label(e.id, 15, _name_color()))
	col.add_child(_card_label(_detail_text(e), 12, DETAIL_COLOR))
	col.add_child(_card_label("cost %d" % int(e.cost), 12, _name_color()))
	row.add_child(swatch)
	row.add_child(col)
	pad.add_child(row)
	btn.add_child(pad)
	btn.pressed.connect(_open_detail.bind(idx))
	return btn

func _card_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _name_color() -> Color:
	return Color(0.29, 0.259, 0.204)

# Builds the "detail" line from the chain: terrain/inputs -> outputs.
func _detail_text(e: Dictionary) -> String:
	var src: String = e.requires
	if src == "":
		src = "+".join(e.inputs.map(func(i): return i.resource))
	var dst: String = "+".join(e.outputs.map(func(o): return "$" if o.resource == "money" else o.resource))
	if src == "" and dst == "":
		return "infrastructure"
	if src == "":
		return "→ %s" % dst
	if dst == "":
		return src
	return "%s → %s" % [src, dst]

# --- Build detail ---------------------------------------------------------------

func _open_detail(idx: int) -> void:
	var e: Dictionary = get_parent().catalog[idx]
	_name.text = e.id
	_level.text = e.tier
	_d_swatch.color = e.color
	_d_chain.text = "Chain:  %s" % _detail_text(e)
	_d_size.text = "Size:  %d x %d" % [e.size.x, e.size.y]
	_d_cost.text = "Cost:  %d" % int(e.cost)
	_d_needs.text = "Needs:  %s (adjacent)" % e.requires if String(e.requires) != "" else "Needs:  open land"
	_set_view("detail")
	get_parent().enter_build_mode(e, _sel)  # ghost starts on the selected tile

func _on_confirm() -> void:
	if get_parent().confirm_build():
		hide_sheet()

func _on_build_changed() -> void:
	if _view != "detail":
		return
	var ok: bool = get_parent().build_valid
	_confirm.disabled = not ok
	_d_status.text = "Ready — Confirm to place" if ok else "Move to a valid spot (tap the map)"

# --- Sheet slide ----------------------------------------------------------------

func show_sheet() -> void:
	if _open:
		return
	_open = true
	_update_block_rect()
	_slide(-(SHEET_H + SHEET_MARGIN), -SHEET_MARGIN)

func hide_sheet() -> void:
	if not _open:
		return
	_open = false
	if get_parent().build_active:
		get_parent().exit_build_mode()
	get_parent().set_ui_block_rect(Rect2())
	_slide(0.0, SHEET_H)
	get_parent().clear_selection()

# Tells the map the screen rect the open sheet occupies, so touches/drags on the
# panel don't pan or zoom the map underneath.
func _update_block_rect() -> void:
	var vp := get_viewport().get_visible_rect().size
	get_parent().set_ui_block_rect(Rect2(SHEET_MARGIN, vp.y - SHEET_H - SHEET_MARGIN, vp.x - 2.0 * SHEET_MARGIN, SHEET_H))

func _slide(top: float, bottom: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sheet, "offset_top", top, ANIM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sheet, "offset_bottom", bottom, ANIM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
