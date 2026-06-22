extends CanvasLayer
class_name CenterDialog

## Reusable centred modal dialog: a dim backdrop + a SketchBox panel in the middle
## of the screen. Call open(title) to show, close() to hide. Tapping the backdrop
## or the ✕ closes it. Swap the `Body` content per use case. Sits on a high
## CanvasLayer so it covers the map and the rest of the UI.

@onready var _backdrop: ColorRect = $Backdrop
@onready var _title: Label = $Panel/Margin/VBox/Header/Title
@onready var _close: Button = $Panel/Margin/VBox/Header/CloseButton

func _ready() -> void:
	visible = false
	_close.pressed.connect(close)
	_backdrop.gui_input.connect(_on_backdrop_input)

func open(title: String) -> void:
	_title.text = title
	visible = true
	_set_world_input(false)

func close() -> void:
	visible = false
	_set_world_input(true)

# Freeze/unfreeze the parent's pan/zoom/tap while the dialog is up.
func _set_world_input(enabled: bool) -> void:
	var p := get_parent()
	if p.has_method("set_pan_enabled"):
		p.set_pan_enabled(enabled)

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()
