extends Order
class_name SpecificItemOrder

# Item properties
@export var item_resource: ComplexItem  # Direct reference to the required item

func _init() -> void:
	super()
	order_type = OrderType.SPECIFIC_ITEM

# Override validate_item method to check exact match
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Check if the item matches the required item
	
	# If resource is specified, check by resource
	if item_resource != null:
		return item.name == item_resource.name
	
	return false

# Calculate final price
func calculate_final_price(item_quality: int) -> int:
	# If price is already negotiated
	if negotiated_price > 0:
		return negotiated_price
	
	# Base price
	var price = base_price
	
	# Quality modifier
	var quality_modifier = 1.0
	if item_quality > required_quality_min:
		# Bonus for exceeding quality
		quality_modifier = 1.0 + (item_quality - required_quality_min) / 100.0
	elif item_quality < required_quality_min:
		# Penalty for insufficient quality (if acceptable)
		quality_modifier = 0.8
	
	# Final price with a small bonus for specific item orders
	return int(price * quality_modifier * 1.1)

# Extend UI description
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	# Display information about the required item
	if item_resource != null:
		desc += "\nRequired item: " + item_resource.name
		
		# Add category info if available
		var category_name = ""
		match item_resource.get_category():
			ItemData.Category.TOOLS:
				category_name = "Tool"
			ItemData.Category.WEAPONS:
				category_name = "Weapon"
			ItemData.Category.ARMOR:
				category_name = "Armor"
		
		if not category_name.is_empty():
			desc += " (" + category_name + ")"
	
	return desc
