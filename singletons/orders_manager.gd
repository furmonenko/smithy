extends Node
class_name OrdersManager

# Configuration
var max_active_orders: int = 5
var max_orders_per_character: int = 3

# Orders collections
var active_orders: Array[Order] = []
var completed_orders: Array[Order] = []
var failed_orders: Array[Order] = []

# Characters who can provide orders
var characters: Dictionary = {}  # character_id: character_data

# Signals
signal order_accepted(order: Order)
signal order_completed(order: Order, quality: int)
signal order_failed(order: Order)
signal order_expired(order: Order)

# Initialize the manager
func _ready() -> void:
	# Connect to any required global signals
	pass

# Register a character who can provide orders
func register_character(character_id: String, faction: String, reputation: int = 0) -> void:
	characters[character_id] = {
		"id": character_id,
		"faction": faction,
		"reputation": reputation,
		"available_orders": []
	}

# Generate orders for a character
func generate_orders_for_character(character_id: String, templates: Array[ProductRecipe], count: int = 1) -> Array[Order]:
	if not character_id in characters:
		return []
	
	var character = characters[character_id]
	var generated_orders: Array[Order] = []
	
	# Clear previous orders if requested
	if count > 0:
		character.available_orders.clear()
	
	# Generate orders based on templates
	for i in range(min(count, templates.size())):
		var template = templates[i]
		
		# Calculate quality requirement based on character reputation
		var quality_min = 30 + (character.reputation / 10)
		
		# Create new order
		var order = SpecificItemOrder.create_from_item(template, character_id, quality_min)
		
		# Add to character's available orders
		character.available_orders.append(order)
		generated_orders.append(order)
	
	return generated_orders

# Accept an order
func accept_order(order_id: String) -> bool:
	# Check if we can accept more orders
	if active_orders.size() >= max_active_orders:
		return false
	
	# Find the order in any character's available orders
	var order_to_accept: Order = null
	var character_id: String = ""
	
	for char_id in characters:
		var character = characters[char_id]
		for i in range(character.available_orders.size()):
			if character.available_orders[i].order_id == order_id:
				order_to_accept = character.available_orders[i]
				character_id = char_id
				
				# Remove from character's available orders
				character.available_orders.remove_at(i)
				break
		
		if order_to_accept != null:
			break
	
	if order_to_accept == null:
		return false
	
	# Accept the order
	order_to_accept.accept()
	
	# Add to active orders
	active_orders.append(order_to_accept)
	
	# Emit signal
	order_accepted.emit(order_to_accept)
	
	return true

# Start crafting an order
func start_crafting_order(order_id: String) -> bool:
	for order in active_orders:
		if order.order_id == order_id:
			order.start_crafting()
			return true
	
	return false

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
		
		# Update character reputation
		var character_id = order.customer_id
		if character_id in characters:
			characters[character_id].reputation += order.get_reputation_impact()
		
		# Emit signal
		order_completed.emit(order, item_quality)
		
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
	
	# Update character reputation
	var character_id = order.customer_id
	if character_id in characters:
		characters[character_id].reputation += order.get_reputation_impact()
	
	# Emit signal
	order_failed.emit(order)
	
	return true

# Process a day - handle order expirations
func process_day() -> void:
	var orders_to_expire = []
	
	# Check for expired orders
	for i in range(active_orders.size()):
		var order = active_orders[i]
		order.duration_days -= 1
		
		if order.duration_days <= 0:
			orders_to_expire.append(i)
	
	# Expire orders (process in reverse to keep indices valid)
	for i in range(orders_to_expire.size() - 1, -1, -1):
		var order_index = orders_to_expire[i]
		var order = active_orders[order_index]
		
		# Expire the order
		order.expire()
		
		# Move to failed orders
		active_orders.remove_at(order_index)
		failed_orders.append(order)
		
		# Update character reputation
		var character_id = order.customer_id
		if character_id in characters:
			characters[character_id].reputation += order.get_reputation_impact()
		
		# Emit signal
		order_expired.emit(order)

# Get all available orders from all characters
func get_all_available_orders() -> Array[Order]:
	var all_orders: Array[Order] = []
	
	for character_id in characters:
		all_orders.append_array(characters[character_id].available_orders)
	
	return all_orders

# Get available orders for a specific character
func get_character_available_orders(character_id: String) -> Array[Order]:
	if character_id in characters:
		return characters[character_id].available_orders
	return []

# Get an order by ID from any collection
func get_order_by_id(order_id: String) -> Order:
	# Check active orders first
	for order in active_orders:
		if order.order_id == order_id:
			return order
	
	# Check completed orders
	for order in completed_orders:
		if order.order_id == order_id:
			return order
	
	# Check failed orders
	for order in failed_orders:
		if order.order_id == order_id:
			return order
	
	# Check available orders from characters
	for character_id in characters:
		for order in characters[character_id].available_orders:
			if order.order_id == order_id:
				return order
	
	return null

# Can accept more orders check
func can_accept_more_orders() -> bool:
	return active_orders.size() < max_active_orders

# Get character reputation
func get_character_reputation(character_id: String) -> int:
	if character_id in characters:
		return characters[character_id].reputation
	return 0

# Get character faction
func get_character_faction(character_id: String) -> String:
	if character_id in characters:
		return characters[character_id].faction
	return ""

# Get character orders info as text
func get_character_orders_info(character_id: String) -> String:
	if not character_id in characters:
		return "Character not found"
	
	var character = characters[character_id]
	var info = character_id + " (" + character.faction + ")\n"
	info += "Reputation: " + str(character.reputation) + "\n\n"
	
	if character.available_orders.is_empty():
		info += "No available orders."
	else:
		info += "Available Orders:\n"
		for i in range(character.available_orders.size()):
			var order = character.available_orders[i]
			info += str(i+1) + ". " + order.order_name + "\n"
			info += "   Quality: " + str(order.required_quality_min) + "\n"
			info += "   Price: " + str(order.base_price) + "\n"
			info += "   Duration: " + str(order.duration_days) + " days\n\n"
	
	return info

# Get active orders info as text
func get_active_orders_info() -> String:
	if active_orders.is_empty():
		return "No active orders."
	
	var info = "Active Orders (" + str(active_orders.size()) + "/" + str(max_active_orders) + "):\n\n"
	
	for i in range(active_orders.size()):
		var order = active_orders[i]
		info += str(i+1) + ". " + order.order_name + "\n"
		info += "   Status: " + order.get_status_name() + "\n"
		info += "   Customer: " + order.customer_id + "\n"
		info += "   Quality: " + str(order.required_quality_min) + "\n"
		info += "   Price: " + str(order.base_price) + "\n"
		info += "   Days left: " + str(order.duration_days) + "\n\n"
	
	return info
