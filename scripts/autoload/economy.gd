extends Node

var money: float = 0.0
var trend: float = 1.0
var prestige_currency: int = 0
var lifetime_earnings: float = 0.0

var building_levels: Dictionary = {}

var _economy_cfg: Dictionary = {}
var _buildings_cfg: Dictionary = {}
var _buildings: Array = []

var income_per_sec: float = 0.0

func _ready() -> void:
	_load_configs()

func _load_configs() -> void:
	_economy_cfg = ConfigService.get_config("economy")
	_buildings_cfg = ConfigService.get_config("buildings")
	_buildings = _buildings_cfg.get("buildings", [])
	_init_levels()

func _init_levels() -> void:
	for b in _buildings:
		var id = b.get("id", "")
		if id != "" and not building_levels.has(id):
			building_levels[id] = 0

func tick(delta: float) -> void:
	if _buildings.is_empty():
		return

	var trend_cfg = _economy_cfg.get("trend", {})
	var decay_per_min = float(trend_cfg.get("decayPerMinute", 0.0))
	var min_trend = float(trend_cfg.get("minMultiplier", 0.8))
	var max_trend = float(trend_cfg.get("maxMultiplier", 5.0))

	var trend_gain_per_sec = _compute_trend_gain_per_sec()
	trend += trend_gain_per_sec * delta
	trend -= (decay_per_min / 60.0) * delta
	trend = clamp(trend, min_trend, max_trend)

	income_per_sec = _compute_income_per_sec()
	var earned = income_per_sec * delta
	money += earned
	lifetime_earnings += earned

	Events.emit_signal("money_changed", money)
	Events.emit_signal("trend_changed", trend)
	Events.emit_signal("income_changed", income_per_sec)

func _compute_income_per_sec() -> float:
	var total = 0.0
	for b in _buildings:
		var id = b.get("id", "")
		var lvl = int(building_levels.get(id, 0))
		if lvl <= 0:
			continue
		var output = b.get("output", {})
		if output.has("type") and output["type"] != "money":
			continue
		var base = float(output.get("basePerSec", 0.0))
		var rate = float(output.get("rate", 1.0))
		var raw = base * pow(rate, lvl)
		var trend_scale = b.get("trendScaling", {})
		if trend_scale.get("enabled", false):
			var weight = float(trend_scale.get("weight", 1.0))
			raw *= trend * weight
		total += raw
	return total

func _compute_trend_gain_per_sec() -> float:
	var total = 0.0
	for b in _buildings:
		var output = b.get("output", {})
		if output.get("type", "money") != "trend":
			continue
		var id = b.get("id", "")
		var lvl = int(building_levels.get(id, 0))
		if lvl <= 0:
			continue
		var base = float(output.get("trendPerSec", 0.0))
		var rate = float(output.get("rate", 1.0))
		var raw = base * pow(rate, lvl)
		total += raw
	return total

func get_buildings() -> Array:
	return _buildings

func get_building_by_id(building_id: String) -> Dictionary:
	for b in _buildings:
		if b.get("id", "") == building_id:
			return b
	return {}

func get_level(building_id: String) -> int:
	return int(building_levels.get(building_id, 0))

func get_upgrade_cost(building_id: String) -> float:
	var b = get_building_by_id(building_id)
	if b.is_empty():
		return 0.0
	var lvl = get_level(building_id)
	var cost_cfg = b.get("cost", {})
	var base = float(cost_cfg.get("base", 0.0))
	var rate = float(cost_cfg.get("rate", 1.0))
	var raw = base * pow(rate, lvl)
	return raw * _upgrade_cost_multiplier()

func upgrade(building_id: String) -> bool:
	var cost = get_upgrade_cost(building_id)
	if money < cost or cost <= 0.0:
		return false
	money -= cost
	building_levels[building_id] = get_level(building_id) + 1
	Events.emit_signal("building_upgraded", building_id, get_level(building_id))
	Events.emit_signal("money_changed", money)
	return true

func apply_offline(seconds: float, efficiency: float) -> float:
	if seconds <= 0.0:
		return 0.0
	income_per_sec = _compute_income_per_sec()
	var award = income_per_sec * seconds * efficiency
	money += award
	lifetime_earnings += award
	Events.emit_signal("money_changed", money)
	Events.emit_signal("income_changed", income_per_sec)
	return award

func _upgrade_cost_multiplier() -> float:
	var mult = 1.0
	for b in _buildings:
		var output = b.get("output", {})
		if output.get("type", "") != "modifier":
			continue
		var id = b.get("id", "")
		var lvl = get_level(id)
		if lvl <= 0:
			continue
		for effect in output.get("effects", []):
			if effect.get("kind", "") != "upgrade_cost_multiplier":
				continue
			var value = float(effect.get("value", 1.0))
			mult *= pow(value, lvl)
	return mult

func set_state(state: Dictionary) -> void:
	money = float(state.get("money", 0.0))
	trend = float(state.get("trend", 1.0))
	prestige_currency = int(state.get("prestigeCurrency", 0))
	lifetime_earnings = float(state.get("lifetimeEarnings", 0.0))
	building_levels = state.get("buildingLevels", {})
	_init_levels()

func get_state() -> Dictionary:
	return {
		"money": money,
		"trend": trend,
		"prestigeCurrency": prestige_currency,
		"lifetimeEarnings": lifetime_earnings,
		"buildingLevels": building_levels
	}
