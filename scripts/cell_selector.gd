extends Node2D
class_name CellSelector

## Draws a blue highlight over the currently selected grid cell. It's a separate
## node so selecting a tile only redraws this small overlay — never the cached
## grid. Child of Map; listens to the Map's tile_selected / tile_deselected.

@export var fill_color: Color = Color(0.3, 0.6, 1.0, 0.25)
@export var border_color: Color = Color(0.2, 0.5, 0.95, 0.9)
@export var border_width: float = 2.0

var _selected := Vector2i(-1, -1)

func _ready() -> void:
	var map := get_parent()
	map.tile_selected.connect(_on_tile_selected)
	map.tile_deselected.connect(_on_tile_deselected)

func _on_tile_selected(x: int, y: int) -> void:
	_selected = Vector2i(x, y)
	queue_redraw()

func _on_tile_deselected() -> void:
	_selected = Vector2i(-1, -1)
	queue_redraw()

func _draw() -> void:
	if _selected.x < 0:
		return
	var cs: int = get_parent().cell_size
	var rect := Rect2(Vector2(_selected.x * cs, _selected.y * cs), Vector2(cs, cs))
	draw_rect(rect, fill_color)
	draw_rect(rect, border_color, false, border_width)
