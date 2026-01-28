extends Node

const CONFIG_DIR := "res://config"

var _cache: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	_cache.clear()
	_load_json("economy")
	_load_json("buildings")
	_load_json("missions")
	_load_json("events")
	_load_json("upgrades_permanent")

func get_config(name: String) -> Dictionary:
	return _cache.get(name, {})

func _load_json(name: String) -> void:
	var path = "%s/%s.json" % [CONFIG_DIR, name]
	if not FileAccess.file_exists(path):
		push_warning("Missing config: %s" % path)
		return
	var text = FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data == null:
		push_error("Invalid JSON in %s" % path)
		return
	_cache[name] = data
