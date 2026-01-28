extends Node

signal money_changed(value: float)
signal trend_changed(value: float)
signal income_changed(value: float)
signal building_selected(building_id: String)
signal building_upgraded(building_id: String, level: int)
signal offline_award(amount: float, seconds: float)
