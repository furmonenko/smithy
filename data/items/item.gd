extends Resource
class_name Item

# Reference to the recipe that created this item
var recipe: Recipe

# Basic properties
var name: String
var description: String
var category: Recipe.Category
var creation_difficulty: Recipe.CreationDifficulty

# Crafting results
var quality: float = 0.0
var prestige: float = 0.0
var base_price: int = 0

# For complex items
var components: Array[Item] = []

# Creation timestamp
var creation_time: int = 0

# Initialize a new item
func _init() -> void:
	creation_time = Time.get_unix_time_from_system()

# Get the quality of the item
func get_quality() -> float:
	return quality

# Calculate prestige based on quality
func calculate_prestige() -> float:
	var config = Global.get_config()
	var base_prestige = get_base_category_prestige()
	
	# Престиж Предмета = (Фактична Якість / 100) × Базовий Престиж Категорії
	return (quality / 100.0) * base_prestige

# Get prestige
func get_prestige() -> float:
	return prestige

# Get selling price with forge premium
func get_selling_price(forge_premium: float = 0.0) -> int:
	return base_price + int(base_price * forge_premium)

# Get base prestige by quality level
func get_base_category_prestige() -> int:
	var config = Global.get_config()
	
	if quality < 50:
		return config.prestige_low_quality  # Звичайний
	elif quality < 80:
		return config.prestige_medium_quality  # Відмінний
	else:
		return config.prestige_high_quality  # Видатний

# Get UI description
func get_ui_description() -> String:
	var desc = name + "\n"
	desc += "Quality: " + str(int(quality)) + "\n"
	desc += "Prestige: " + str(int(prestige)) + "\n"
	desc += "Complexity: " + recipe.get_difficulty_name() + "\n"
	desc += "Price: " + str(get_selling_price()) + "\n\n"
	desc += description
	return desc

# Check if item matches order requirements
func matches_order_requirements(order: Order) -> bool:
	# Basic quality check
	if quality < order.required_quality_min:
		return false
		
	# Specific order type checks
	if order is CategoryItemOrder:
		if category != order.item_category:
			return false
		if creation_difficulty < order.creation_difficulty:
			return false
	elif order is SpecificItemOrder:
		if name != order.required_item.name:
			return false
	
	return true
