# GeneralOrder.gd - General order for a specific category of items
extends Order
class_name GeneralOrder

# Properties for the order - we use enums from the ItemData class
@export var item_category: ItemData.Category  # TOOLS=0, WEAPONS=1, ARMOR=2
@export var creation_difficulty: ItemData.CreationDifficulty  # HOUSEHOLD=1, BASIC=2, MILITARY=3, ELITE=4
@export var is_complex_item: bool = true  # Whether a complex item is required

# Override validate_item method to check category and difficulty match
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Check category
	if item.get_category() != item_category:
		return false
	
	# Check difficulty
	if item.creation_difficulty < creation_difficulty:
		return false
	
	# Check if the item is of the right type (simple/complex)
	if is_complex_item and not (item is ComplexItem):
		return false
	elif not is_complex_item and not (item is SimpleItem):
		return false
	
	return true

# Get category name
func get_category_name() -> String:
	match item_category:
		ItemData.Category.TOOLS:
			return "Tool"
		ItemData.Category.WEAPONS:
			return "Weapon"
		ItemData.Category.ARMOR:
			return "Armor"
		_:
			return "Unknown"

# Get complexity name
func get_complexity_name() -> String:
	match creation_difficulty:
		ItemData.CreationDifficulty.HOUSEHOLD:
			return "Household"
		ItemData.CreationDifficulty.BASIC:
			return "Basic"
		ItemData.CreationDifficulty.MILITARY:
			return "Military"
		ItemData.CreationDifficulty.ELITE:
			return "Elite"
		_:
			return "Unknown"

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
	
	# Difficulty modifier
	var difficulty_modifier = 1.0
	match creation_difficulty:
		ItemData.CreationDifficulty.HOUSEHOLD:
			difficulty_modifier = 1.0
		ItemData.CreationDifficulty.BASIC:
			difficulty_modifier = 1.1
		ItemData.CreationDifficulty.MILITARY:
			difficulty_modifier = 1.3
		ItemData.CreationDifficulty.ELITE:
			difficulty_modifier = 1.5
	
	# Final price
	return int(price * quality_modifier * difficulty_modifier)

# Extend UI description
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	desc += "\nCategory: " + get_category_name()
	desc += "\nComplexity: " + get_complexity_name()
	desc += "\nType: " + ("Complex" if is_complex_item else "Simple") + " item"
	return desc
