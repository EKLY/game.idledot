extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var last_offline_award: float = 0.0
var last_offline_seconds: float = 0.0

func _ready() -> void:
	call_deferred("load_or_init")

func load_or_init() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_load()
	else:
		_save_new()

func _load() -> void:
	var text = FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(text)
	if data == null:
		push_error("Invalid save JSON, creating new save.")
		_save_new()
		return
	Economy.set_state(data)
	_apply_offline(data)
	_save()

func _save_new() -> void:
	Economy.money = 0.0
	Economy.trend = 1.0
	Economy.prestige_currency = 0
	Economy.lifetime_earnings = 0.0
	Economy.building_levels = {}
	Economy._init_levels()
	_save()

func _apply_offline(data: Dictionary) -> void:
	var economy_cfg = ConfigService.get_config("economy")
	var pacing = economy_cfg.get("pacing", {})
	var cap_hours = float(pacing.get("offlineCapHours", 12))
	var efficiency = float(pacing.get("offlineEfficiency", 0.7))

	var last_active = float(data.get("lastActiveAt", 0.0))
	if last_active <= 0.0:
		return
	var now = Time.get_unix_time_from_system()
	var elapsed = max(0.0, now - last_active)
	var cap_seconds = cap_hours * 3600.0
	var clamped = min(elapsed, cap_seconds)
	last_offline_seconds = clamped
	last_offline_award = Economy.apply_offline(clamped, efficiency)
	Events.emit_signal("offline_award", last_offline_award, last_offline_seconds)

func save() -> void:
	_save()

func _save() -> void:
	var data = Economy.get_state()
	data["version"] = SAVE_VERSION
	data["lastActiveAt"] = Time.get_unix_time_from_system()
	data["seasonState"] = data.get("seasonState", {})
	var json = JSON.stringify(data, "  ")
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(json)
	f.close()
