extends Node

# Посилання на конфігурацію
var config: GameConfig

# Basic forge data
var forge_name: String = "Novice Forge"
var forge_prestige: int = 0  # 0-1000
var forge_reputation: Dictionary = {
	"city_guard": 0,  # -100 to +100
	"merchants": 0,
	"nobility": 0,
	"church": 0,
	"thieves": 0,
	"smugglers": 0,
	"bandits": 0,
	"secret_cults": 0
}

# Economic indicators
var forge_money: int = 0
var price_premium: float = 0.0  # Price premium percentage (added to base price)
var supplier_discount: float = 0.0  # Discount from suppliers
var materials_in_stock: Dictionary = {}  # materials in stock {material_id: quantity}

# Orders collections
var active_orders: Array[Order] = []
var completed_orders: Array[Order] = []
var failed_orders: Array[Order] = []
var max_active_orders: int = 5

# Signals
signal money_changed(new_amount: int)
signal prestige_changed(new_amount: int)
signal reputation_changed(faction: String, new_value: int)
signal order_accepted(order: Order)
signal order_completed(order: Order)
signal order_failed(order: Order)

# Ініціалізація
func _ready() -> void:
	# Завантаження конфігурації
	config = Global.get_config()
	
	# Встановлення початкових значень з конфігурації
	forge_money = config.starting_money
	forge_prestige = config.starting_prestige
	max_active_orders = config.max_active_orders

# Update prestige
func update_prestige(amount: int) -> void:
	var old_prestige = forge_prestige
	forge_prestige += amount
	forge_prestige = clamp(forge_prestige, 0, 1000)
	
	prestige_changed.emit(forge_prestige)
	
	# Update benefits based on new prestige
	update_prestige_benefits()

# Update reputation with a faction
func update_reputation(faction: String, amount: int) -> void:
	if faction in forge_reputation:
		var old_rep = forge_reputation[faction]
		forge_reputation[faction] += amount
		forge_reputation[faction] = clamp(forge_reputation[faction], -100, 100)
		
		reputation_changed.emit(faction, forge_reputation[faction])

# Update money
func update_money(amount: int) -> void:
	forge_money += amount
	money_changed.emit(forge_money)

# Update benefits based on prestige level
func update_prestige_benefits() -> void:
	# Update price premium based on prestige
	if forge_prestige < config.prestige_level_1:
		price_premium = 0.0
	elif forge_prestige < config.prestige_level_2:
		price_premium = config.price_premium_level_1
	elif forge_prestige < config.prestige_level_3:
		price_premium = config.price_premium_level_2
	elif forge_prestige < config.prestige_level_4:
		price_premium = config.price_premium_level_3
	elif forge_prestige < config.prestige_level_5:
		price_premium = config.price_premium_level_4
	elif forge_prestige < config.prestige_level_6:
		price_premium = config.price_premium_level_5
	else:
		price_premium = config.price_premium_level_6
		
	# Update supplier discount based on prestige
	if forge_prestige < config.supplier_discount_level_1:
		supplier_discount = 0.0
	elif forge_prestige < config.supplier_discount_level_2:
		supplier_discount = config.supplier_discount_value_1
	elif forge_prestige < config.supplier_discount_level_3:
		supplier_discount = config.supplier_discount_value_2
	elif forge_prestige < config.supplier_discount_level_4:
		supplier_discount = config.supplier_discount_value_3
	else:
		supplier_discount = config.supplier_discount_value_4

# Add a new order
func add_order(order: Order) -> void:
	# Check if we can accept more orders
	if active_orders.size() >= max_active_orders:
		return
		
	# Accept the order
	order.accept()
	active_orders.append(order)
	
	# Emit signal
	order_accepted.emit(order)

# Complete an order
func complete_order(order_id: String, item: Recipe) -> bool:
	# Find the order in active orders
	var order_index = -1
	for i in range(active_orders.size()):
		if active_orders[i].order_id == order_id:
			order_index = i
			break
	
	if order_index == -1:
		return false
	
	var order = active_orders[order_index]
	
	# Validate the item against the order requirements
	if not order.validate_item(item):
		return false
	
	# Complete the order
	var item_quality = int(item.get_quality())
	if order.complete(item_quality, item.name):
		# Move to completed orders
		active_orders.remove_at(order_index)
		completed_orders.append(order)
		
		# Update forge stats
		update_money(order.get_money_reward())
		update_prestige(order.get_prestige_gain())
		update_reputation(order.customer_id.split("-")[0], order.get_reputation_impact())
		
		# Emit signal
		order_completed.emit(order)
		
		return true
	
	return false

# Fail an order
func fail_order(order_id: String) -> bool:
	# Find the order in active orders
	var order_index = -1
	for i in range(active_orders.size()):
		if active_orders[i].order_id == order_id:
			order_index = i
			break
	
	if order_index == -1:
		return false
	
	var order = active_orders[order_index]
	
	# Fail the order
	order.fail()
	
	# Move to failed orders
	active_orders.remove_at(order_index)
	failed_orders.append(order)
	
	# Update reputation
	update_reputation(order.customer_id.split("-")[0], order.get_reputation_impact())
	
	# Emit signal
	order_failed.emit(order)
	
	return true

# Can accept more orders check
func can_accept_more_orders() -> bool:
	return active_orders.size() < max_active_orders

# Get reputation level description
func get_reputation_level_description(faction: String) -> String:
	var rep_value = forge_reputation.get(faction, 0)
	
	if rep_value >= 80:
		return "Honored"
	elif rep_value >= 50:
		return "Respected"
	elif rep_value >= 20:
		return "Friendly"
	elif rep_value > -20:
		return "Neutral"
	elif rep_value > -50:
		return "Suspicious"
	elif rep_value > -80:
		return "Hostile"
	else:
		return "Hated"

# Get prestige level description
func get_prestige_level_description() -> String:
	if forge_prestige >= config.prestige_level_6:
		return "Legendary Smith"
	elif forge_prestige >= config.prestige_level_5:
		return "Master Craftsman"
	elif forge_prestige >= config.prestige_level_4:
		return "Master Smith"
	elif forge_prestige >= config.prestige_level_3:
		return "Known Smith"
	elif forge_prestige >= config.prestige_level_2:
		return "Local Smith"
	elif forge_prestige >= config.prestige_level_1:
		return "Novice Smith"
	else:
		return "Unknown Smith"

# Resource-based saving
class ForgeData extends Resource:
	@export var forge_name: String
	@export var forge_prestige: int
	@export var forge_reputation: Dictionary
	@export var forge_money: int
	@export var price_premium: float
	@export var supplier_discount: float

# Save forge data to a resource file
func save_game(save_path: String = "user://forge_save.tres") -> Error:
	var save_data = ForgeData.new()
	
	# Copy basic data
	save_data.forge_name = forge_name
	save_data.forge_prestige = forge_prestige
	save_data.forge_reputation = forge_reputation
	save_data.forge_money = forge_money
	save_data.price_premium = price_premium
	save_data.supplier_discount = supplier_discount
	
	# Save to disk
	return ResourceSaver.save(save_data, save_path)

# Load forge data from a resource file
func load_game(save_path: String = "user://forge_save.tres") -> Error:
	if not FileAccess.file_exists(save_path):
		return ERR_FILE_NOT_FOUND
		
	var save_data = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if not save_data:
		return ERR_FILE_CORRUPT
		
	# Copy data from resource
	if save_data is ForgeData:
		forge_name = save_data.forge_name
		forge_prestige = save_data.forge_prestige
		forge_reputation = save_data.forge_reputation
		forge_money = save_data.forge_money
		price_premium = save_data.price_premium
		supplier_discount = save_data.supplier_discount
		
		# Update any derived values
		update_prestige_benefits()
		
		return OK
	
	return ERR_INVALID_DATA
