extends CanvasLayer

# Settings Panel
# Shows game settings and options

signal new_game_requested()
signal closed()

@onready var overlay: ColorRect = $Overlay
@onready var new_game_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuContainer/NewGameButton
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

# Confirmation dialog reference
var confirmation_dialog: ConfirmationDialog = null

func _ready():
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	close_button.pressed.connect(_on_close_pressed)
	overlay.gui_input.connect(_on_overlay_input)

	# Create confirmation dialog
	_create_confirmation_dialog()

func show_panel():
	visible = true

func hide_panel():
	visible = false
	closed.emit()

func _create_confirmation_dialog():
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Are you sure you want to start a new game?\n\nThis will delete all your current progress!"
	confirmation_dialog.ok_button_text = "Yes, Start New Game"
	confirmation_dialog.cancel_button_text = "Cancel"

	# Style the dialog
	confirmation_dialog.min_size = Vector2(400, 150)

	# Connect signals
	confirmation_dialog.confirmed.connect(_on_new_game_confirmed)

	# Add to scene
	add_child(confirmation_dialog)

func _on_new_game_pressed():
	# Show confirmation dialog
	confirmation_dialog.popup_centered()

func _on_new_game_confirmed():
	# Emit signal to main script
	new_game_requested.emit()
	hide_panel()

func _on_close_pressed():
	hide_panel()

func _on_overlay_input(event: InputEvent):
	# Close when clicking on overlay
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_panel()
