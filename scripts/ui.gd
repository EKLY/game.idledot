extends CanvasLayer

## Mockup UI host: a fixed top bar (always visible) and a bottom sheet that
## slides up when a map tile is tapped. Content is placeholder only — not wired
## to real economy data yet. The detail popup is planned (see KB), not built.

const SHEET_H := 320.0
const ANIM := 0.22

@onready var _sheet: Panel = $Root/BottomSheet
@onready var _name: Label = $Root/BottomSheet/Margin/VBox/Header/HeaderText/Name
@onready var _close: Button = $Root/BottomSheet/Margin/VBox/Header/CloseButton
@onready var _upgrade: Button = $Root/BottomSheet/Margin/VBox/Upgrade
@onready var _qty_x1: Button = $Root/BottomSheet/Margin/VBox/QtyRow/QtyX1
@onready var _qty_x10: Button = $Root/BottomSheet/Margin/VBox/QtyRow/QtyX10
@onready var _qty_xmax: Button = $Root/BottomSheet/Margin/VBox/QtyRow/QtyXMax

var _tween: Tween
var _open := false

func _ready() -> void:
	var map := get_parent()
	if map.has_signal("tile_selected"):
		map.tile_selected.connect(_on_tile_selected)
	_close.pressed.connect(hide_sheet)
	_qty_x1.pressed.connect(_set_qty.bind("x1"))
	_qty_x10.pressed.connect(_set_qty.bind("x10"))
	_qty_xmax.pressed.connect(_set_qty.bind("xMAX"))
	_sheet.offset_top = 0.0
	_sheet.offset_bottom = SHEET_H

func _on_tile_selected(x: int, y: int) -> void:
	_name.text = "Tile (%d, %d)" % [x, y]
	show_sheet()

func show_sheet() -> void:
	if _open:
		return
	_open = true
	_slide(-SHEET_H, 0.0)

func hide_sheet() -> void:
	if not _open:
		return
	_open = false
	_slide(0.0, SHEET_H)

func _slide(top: float, bottom: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sheet, "offset_top", top, ANIM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sheet, "offset_bottom", bottom, ANIM).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_qty(label: String) -> void:
	_upgrade.text = "Upgrade %s      (cost 100)" % label
