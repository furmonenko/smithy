extends Order
class_name SpecificItemOrder

# Item properties
@export var required_item: ComplexItem  # Direct reference to the required item

func _init() -> void:
	order_type = OrderType.SPECIFIC_ITEM

func initialize_item():
	# Automatically calculate base price if required_item is set
	if required_item != null:
		calculate_base_price()
		
	super()

# Override validate_item method to check exact match
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Check if item matches the required item
	if required_item != null and item is ComplexItem:
		return item.name == required_item.name
	
	return false

# Calculate the base price based on component materials
func calculate_base_price() -> int:
	print("[ORDER] Calculating base price for order: ", order_name)
	
	if required_item == null:
		print("[ORDER] No required_item set, returning current base_price: ", base_price)
		return base_price
	
	print("[ORDER] Required item: ", required_item.name)
	print("[ORDER] Required quality: ", required_quality_min)
	
	var material_cost = 0
	
	# Calculate material costs for all components
	print("[ORDER] Calculating costs for ", required_item.component_slots.size(), " component slots")
	
	for slot_index in range(required_item.component_slots.size()):
		var slot = required_item.component_slots[slot_index]
		
		print("[ORDER] Checking slot ", slot_index)
		
		if slot is ComponentSlot and slot.allowed_component != null:
			var component = slot.allowed_component
			
			# Use max_stack as the quantity for calculation
			var slot_quantity = slot.max_stack
			
			print("[ORDER] Slot has component: ", component.name, ", max_stack: ", slot_quantity)
			
			# Get estimated material cost for component
			if component.has_method("calculate_price_for_quality"):
				var component_cost = component.calculate_price_for_quality(required_quality_min)
				var total_component_cost = component_cost * slot_quantity
				
				print("[ORDER] Component cost: ", component_cost, " x ", slot_quantity, " = ", total_component_cost)
				
				material_cost += total_component_cost
			else:
				print("[ORDER] Component doesn't have calculate_price_for_quality method!")
		else:
			print("[ORDER] Slot is not a ComponentSlot or has no allowed_component")
	
	print("[ORDER] Total material cost: ", material_cost)
	
	# Add crafting premium based on complexity
	var complexity_premium = 1.0
	if required_item.has_method("get_complexity_coefficient"):
		complexity_premium = required_item.get_complexity_coefficient()
		print("[ORDER] Complexity premium: ", complexity_premium)
	else:
		print("[ORDER] Item doesn't have get_complexity_coefficient method, using default: 1.0")
	
	# Final base price with 20% markup
	var final_price = int(material_cost * complexity_premium * 1.2)
	print("[ORDER] Final price calculation: ", material_cost, " x ", complexity_premium, " x 1.2 = ", final_price)
	
	# Update the base price
	print("[ORDER] Updating base_price from ", base_price, " to ", final_price)
	base_price = final_price
	
	# Update price limit
	price_limit = int(base_price * 1.5)  # 50% markup for price limit
	print("[ORDER] Setting price_limit to ", price_limit, " (1.5x base price)")
	
	return base_price

# Calculate final price with quality consideration
func calculate_final_price(item_quality: int) -> int:
	# If price is already negotiated
	if negotiated_price > 0:
		return negotiated_price
	
	# Base price (if not calculated yet)
	if base_price <= 0:
		calculate_base_price()
	
	# Quality modifier
	var quality_modifier = 1.0
	if item_quality > required_quality_min:
		# Bonus for exceeding quality
		quality_modifier = 1.0 + (item_quality - required_quality_min) / 100.0
	elif item_quality < required_quality_min:
		# Penalty for insufficient quality (if acceptable)
		quality_modifier = 0.8
	
	# Final price with item-specific bonus
	return int(base_price * quality_modifier * 1.1)

# Extend UI description
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	# Display information about the required item
	if required_item != null:
		desc += "\nRequired item: " + required_item.name
		
		# Add category info if available
		var category_name = ""
		match required_item.get_category():
			ItemData.Category.TOOLS:
				category_name = "Tool"
			ItemData.Category.WEAPONS:
				category_name = "Weapon"
			ItemData.Category.ARMOR:
				category_name = "Armor"
		
		if not category_name.is_empty():
			desc += " (" + category_name + ")"
		
		# Add required quality
		desc += "\nRequired quality: " + str(required_quality_min)
		
		# Add price information
		desc += "\nBase price: " + str(base_price) + " coins"
		desc += "\nPrice limit: " + str(price_limit) + " coins"
		
		if negotiated_price > 0:
			desc += "\nNegotiated price: " + str(negotiated_price) + " coins"
	
	return desc

# Create a specific item order from a complex item template
static func create_from_item(item: ComplexItem, customer: String, min_quality: int = 50) -> SpecificItemOrder:
	var order = SpecificItemOrder.new()
	
	order.order_name = "Order for " + item.name
	order.description = "Create a " + item.name + " with at least " + str(min_quality) + " quality."
	order.required_item = item
	order.required_quality_min = min_quality
	order.customer_id = customer
	
	# Calculate reputation impact and prestige gain
	order.reputation_impact = 5
	
	# Prestige gain based on item complexity
	var complexity = 1.0
	if item.has_method("get_complexity_coefficient"):
		complexity = item.get_complexity_coefficient()
	
	order.prestige_gain = int(min_quality / 10.0 * complexity)
	
	# Set duration based on complexity
	order.duration_days = int(3 * complexity)
	
	# Base price is automatically calculated in _init when required_item is set
	
	return order
