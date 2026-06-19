extends Control

@export var cols: int = 7
@export var rows: int = 7
@export var cell_size: int = 64
@export var line_color: Color = Color(1, 1, 1, 0.2)
@export var line_width: float = 1.0

func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w = float(cols * cell_size)
	var h = float(rows * cell_size)
	for x in range(cols + 1):
		var px = float(x * cell_size)
		draw_line(Vector2(px, 0), Vector2(px, h), line_color, line_width)
	for y in range(rows + 1):
		var py = float(y * cell_size)
		draw_line(Vector2(0, py), Vector2(w, py), line_color, line_width)
