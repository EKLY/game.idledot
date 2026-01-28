extends Control

@export var next_scene_path: String = "res://scenes/main.tscn"
@export var auto_advance_seconds: float = 1.5

var _advanced := false

func _ready() -> void:
	if auto_advance_seconds > 0.0:
		_advance_after_delay()

func _unhandled_input(event: InputEvent) -> void:
	if _advanced:
		return
	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event is InputEventMouseButton and event.pressed:
		_advance()

func _advance_after_delay() -> void:
	await get_tree().create_timer(auto_advance_seconds).timeout
	_advance()

func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	if next_scene_path.is_empty():
		return
	get_tree().change_scene_to_file(next_scene_path)
