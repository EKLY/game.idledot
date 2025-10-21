extends PanelContainer

# Buildable item UI component
# Shows building icon, name, and cost

signal item_clicked(building_id: String)

@onready var button: Button = $VBoxContainer/Button
@onready var icon_rect: TextureRect = $VBoxContainer/Button/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel

var building_id: String = ""
var building_cost: int = 0

func _ready():
	button.pressed.connect(_on_button_pressed)

func setup(p_building_id: String):
	building_id = p_building_id

	# Get building data
	var building_data = Buildings.get_building(building_id)

	# Set name
	name_label.text = building_data.get("name", "Unknown")

	# Set cost
	building_cost = building_data.get("cost", 0)
	if building_cost > 0:
		cost_label.text = "$%d" % building_cost
		cost_label.visible = true
	else:
		cost_label.visible = false

	# Load icon
	var icon_path = "res://assets/sprites/building_%s.png" % building_id
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	else:
		# Fallback: create colored rectangle if no sprite exists
		var fallback_texture = _create_fallback_texture()
		icon_rect.texture = fallback_texture

func _create_fallback_texture() -> ImageTexture:
	# Create a simple colored square as fallback
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1.0))
	return ImageTexture.create_from_image(img)

func _on_button_pressed():
	item_clicked.emit(building_id)

func set_affordable(can_afford: bool):
	# Visual feedback for affordability
	if can_afford:
		modulate = Color.WHITE
		button.disabled = false
	else:
		modulate = Color(0.6, 0.6, 0.6, 1.0)
		button.disabled = true
