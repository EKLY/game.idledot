extends Node
class_name EconomyManager

# Manages the game economy
# Handles money, selling products, and market prices

signal money_changed(new_amount: int)
signal cash_changed(new_amount: int)
signal product_sold(resource_id: String, amount: int, value: int)

var money: int = 1000  # Starting money (coins - earned from selling)
var cash: int = 0  # Premium currency (bought with real money or earned as reward)
var total_earnings: int = 0

# Sales tracking for offline earnings
var sales_history: Array = []  # Array of {time: float, amount: int}
const HISTORY_DURATION: float = 600.0  # Track last 10 minutes

func _ready():
	pass

# Add money
func add_money(amount: int):
	money += amount
	total_earnings += amount
	money_changed.emit(money)

# Remove money
func spend_money(amount: int) -> bool:
	if money < amount:
		return false

	money -= amount
	money_changed.emit(money)
	return true

# Check if player can afford something
func can_afford(cost: int) -> bool:
	return money >= cost

# Add cash (premium currency)
func add_cash(amount: int):
	cash += amount
	cash_changed.emit(cash)

# Spend cash (premium currency)
func spend_cash(amount: int) -> bool:
	if cash < amount:
		return false

	cash -= amount
	cash_changed.emit(cash)
	return true

# Check if player has enough cash
func can_afford_cash(cost: int) -> bool:
	return cash >= cost

# Sell a product
func sell_product(resource_id: String, amount: int) -> bool:
	var value = Resources.get_resource_value(resource_id)
	var total_value = value * amount

	add_money(total_value)

	# Record sale for offline earnings
	_record_sale(total_value)

	product_sold.emit(resource_id, amount, total_value)
	return true

# Auto-sell resources from a building
func auto_sell_from_building(building: BuildingBase):
	if building is Factory:
		# Sell from output storage
		for resource_id in building.output_storage.keys():
			var amount = building.output_storage[resource_id]
			if amount > 0:
				sell_product(resource_id, amount)
				building.output_storage[resource_id] = 0
	else:
		# Sell from regular storage
		for resource_id in building.storage.keys():
			var amount = building.storage[resource_id]
			if amount > 0:
				sell_product(resource_id, amount)
				building.storage[resource_id] = 0

# Record a sale for offline earnings calculation
func _record_sale(amount: int):
	var current_time = Time.get_ticks_msec() / 1000.0
	sales_history.append({"time": current_time, "amount": amount})

	# Remove old entries
	_cleanup_sales_history()

# Clean up old sales history entries
func _cleanup_sales_history():
	var current_time = Time.get_ticks_msec() / 1000.0
	var cutoff_time = current_time - HISTORY_DURATION

	sales_history = sales_history.filter(func(sale): return sale["time"] > cutoff_time)

# Calculate average sales per minute
func get_average_sales_per_minute() -> float:
	if sales_history.is_empty():
		return 0.0

	var total_sales = 0
	for sale in sales_history:
		total_sales += sale["amount"]

	var duration = HISTORY_DURATION / 60.0  # Convert to minutes
	return total_sales / duration

# Calculate offline earnings
func calculate_offline_earnings(minutes_offline: float) -> int:
	# Cap at 8 hours (480 minutes)
	var capped_minutes = min(minutes_offline, 480.0)

	# Get average sales per minute
	var avg_per_minute = get_average_sales_per_minute()

	# Apply 50% efficiency penalty for offline time
	var offline_earnings = int(avg_per_minute * capped_minutes * 0.5)

	return offline_earnings

# Award offline earnings
func award_offline_earnings(amount: int):
	add_money(amount)

# Get economy info
func get_economy_info() -> Dictionary:
	return {
		"money": money,
		"cash": cash,
		"total_earnings": total_earnings,
		"avg_sales_per_minute": get_average_sales_per_minute()
	}

# Reset economy (for new game)
func reset_economy():
	money = 1000
	cash = 0
	total_earnings = 0
	sales_history.clear()
	money_changed.emit(money)
	cash_changed.emit(cash)
