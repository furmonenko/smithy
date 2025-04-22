extends Node

# Basic forge data
var forge_name: String = "Novice Forge"
var forge_prestige: int = 0  # 0-1000
var forge_reputation: Dictionary = {
	"city_guard": 0,    # -100 to +100
	"merchants": 0,     # -100 to +100
	"nobility": 0,      # -100 to +100
	"church": 0,        # -100 to +100
	"thieves": 0,       # -100 to +100
	"smugglers": 0,     # -100 to +100
	"bandits": 0,       # -100 to +100
	"secret_cults": 0   # -100 to +100
}

# Economic indicators
var forge_money: int = 100
var price_premium: float = 0.0  # Price premium percentage (added to base price)
var supplier_discount: float = 0.0  # Discount from suppliers

# Current orders and inventory
var active_orders: Array[Order] = []
var completed_orders: Array[Order] = []
var failed_orders: Array[Order] = []

var materials_inventory: Dictionary = {}  # {material_id: {material: CraftMaterial, quantity: int}}
var components_inventory: Dictionary = {} # {component_id: {component: SimpleItem, quantity: int}}
var products_inventory: Dictionary = {}   # {product_id: {product: ComplexItem, quantity: int}}

# Signals
signal money_changed(new_amount: int)
signal prestige_changed(new_amount: int)
signal reputation_changed(faction: String, new_value: int)

# Initialize the forge
func _ready() -> void:
	# Default initialization
	pass

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
	if forge_prestige < 50:
		price_premium = 0.0
	elif forge_prestige < 150:
		price_premium = 0.01  # 1%
	elif forge_prestige < 300:
		price_premium = 0.02  # 2%
	elif forge_prestige < 500:
		price_premium = 0.05  # 5%
	elif forge_prestige < 700:
		price_premium = 0.08  # 8%
	elif forge_prestige < 900:
		price_premium = 0.12  # 12%
	else:
		price_premium = 0.15  # 15%
		
	# Update supplier discount based on prestige
	if forge_prestige < 300:
		supplier_discount = 0.0
	elif forge_prestige < 500:
		supplier_discount = 0.03  # 3%
	elif forge_prestige < 700:
		supplier_discount = 0.05  # 5%
	elif forge_prestige < 900:
		supplier_discount = 0.07  # 7%
	else:
		supplier_discount = 0.10  # 10%

# Add a new order
func add_order(order: Order) -> void:
	active_orders.append(order)

# Complete an order
func complete_order(order_id: String, item: ItemData) -> bool:
	for i in range(active_orders.size()):
		if active_orders[i].order_id == order_id:
			var order = active_orders[i]
			
			# Validate item against order requirements
			if order.validate_item(item):
				# Complete the order
				var item_quality = int(item.get_quality())
				if order.complete(item_quality, item.name):
					# Move to completed orders
					active_orders.remove_at(i)
					completed_orders.append(order)
					
					# Update forge stats
					update_money(order.get_money_reward())
					update_prestige(order.get_prestige_gain())
					update_reputation(order.customer_id.split("-")[0], order.get_reputation_impact())
					
					return true
			
			return false
	
	return false

# Fail an order
func fail_order(order_id: String) -> bool:
	for i in range(active_orders.size()):
		if active_orders[i].order_id == order_id:
			var order = active_orders[i]
			order.fail()
			
			# Move to failed orders
			active_orders.remove_at(i)
			failed_orders.append(order)
			
			# Apply reputation penalty
			update_reputation(order.customer_id.split("-")[0], -abs(order.get_reputation_impact()))
			
			return true
	
	return false

# Add material to inventory
func add_material(material: CraftMaterial, quantity: int) -> void:
	var material_id = material.name
	
	if material_id in materials_inventory:
		materials_inventory[material_id].quantity += quantity
	else:
		materials_inventory[material_id] = {
			"material": material,
			"quantity": quantity
		}

# Add component to inventory
func add_component(component: SimpleItem, quantity: int = 1) -> void:
	var component_id = component.name
	
	if component_id in components_inventory:
		components_inventory[component_id].quantity += quantity
	else:
		components_inventory[component_id] = {
			"component": component,
			"quantity": quantity
		}

# Add product to inventory
func add_product(product: ComplexItem, quantity: int = 1) -> void:
	var product_id = product.name
	
	if product_id in products_inventory:
		products_inventory[product_id].quantity += quantity
	else:
		products_inventory[product_id] = {
			"product": product,
			"quantity": quantity
		}

# Remove material from inventory
func remove_material(material_id: String, quantity: int) -> bool:
	if material_id in materials_inventory:
		if materials_inventory[material_id].quantity >= quantity:
			materials_inventory[material_id].quantity -= quantity
			
			# Remove entry if quantity is zero
			if materials_inventory[material_id].quantity <= 0:
				materials_inventory.erase(material_id)
				
			return true
	
	return false

# Remove component from inventory
func remove_component(component_id: String, quantity: int = 1) -> bool:
	if component_id in components_inventory:
		if components_inventory[component_id].quantity >= quantity:
			components_inventory[component_id].quantity -= quantity
			
			# Remove entry if quantity is zero
			if components_inventory[component_id].quantity <= 0:
				components_inventory.erase(component_id)
				
			return true
	
	return false

# Remove product from inventory
func remove_product(product_id: String, quantity: int = 1) -> bool:
	if product_id in products_inventory:
		if products_inventory[product_id].quantity >= quantity:
			products_inventory[product_id].quantity -= quantity
			
			# Remove entry if quantity is zero
			if products_inventory[product_id].quantity <= 0:
				products_inventory.erase(product_id)
				
			return true
	
	return false

# Calculate mismatch penalty for a product
func calculate_mismatch_penalty(product: ComplexItem) -> int:
	# Mismatch = (Prestige_Forge / 100) - Prestige_Product
	var normalized_forge_prestige = forge_prestige / 100.0
	var product_prestige = product.get_prestige()
	
	var mismatch = normalized_forge_prestige - product_prestige
	
	# No penalty if mismatch is within acceptable range (-3 to 3)
	if abs(mismatch) <= 3:
		return 0
		
	# Calculate penalty for positive mismatch (forge prestige too high for product)
	if mismatch > 3:
		var penalty_multiplier = get_mismatch_level_multiplier()
		return int((mismatch - 3) * penalty_multiplier)
		
	# Calculate bonus for negative mismatch (product prestige higher than forge)
	if mismatch < -3:
		return int((mismatch + 3) * 0.5)
		
	return 0

# Get multiplier based on forge prestige level
func get_mismatch_level_multiplier() -> float:
	if forge_prestige < 500:
		return 0.5
	elif forge_prestige < 700:
		return 1.0
	elif forge_prestige < 900:
		return 1.5
	else:
		return 2.0

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
	if forge_prestige >= 900:
		return "Legendary Smith"
	elif forge_prestige >= 700:
		return "Master Craftsman"
	elif forge_prestige >= 500:
		return "Master Smith"
	elif forge_prestige >= 300:
		return "Known Smith"
	elif forge_prestige >= 150:
		return "Local Smith"
	elif forge_prestige >= 50:
		return "Novice Smith"
	else:
		return "Unknown Smith"
