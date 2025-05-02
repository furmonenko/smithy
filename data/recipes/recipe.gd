extends Resource
class_name Recipe

enum Category {
	TOOLS,          # Інструменти
	BODY_ARMOR,     # Обладунки для тіла
	HEAD_ARMOR,     # Обладунки для голови
	WEAPONS         # Зброя
}

enum CreationDifficulty {
	HOUSEHOLD = 1,  # Господарський (0.8)
	BASIC = 2,      # Базовий (0.9)
	MILITARY = 3,   # Військовий (1.0)
	ELITE = 4       # Елітний (1.1)
}

@export var name: String
@export var description: String = ""
@export var creation_difficulty: CreationDifficulty = CreationDifficulty.BASIC
@export var produced_quantity: int = 1
@export var component_slots: Array[Slot] = []
@export var required_craftsman_level: Enums.CraftsmanLevel

# Method to instantiate an actual Item from this recipe
func create_item() -> Item:
	var item = Item.new()
	item.recipe = self
	item.name = name
	item.description = description
	item.category = get_category()
	item.creation_difficulty = creation_difficulty
	
	# Set base values
	item.base_price = calculate_base_price()
	
	return item

# Calculate the base price of the recipe based on materials
func calculate_base_price() -> int:
	var total_cost = 0
	for slot in component_slots:
		if slot is MaterialSlot:
			total_cost += slot.get_material_cost()
	return total_cost

# Get the category of the recipe
func get_category():
	# Base implementation - overridden in subclasses
	return Category.TOOLS

# Get the difficulty name as a string
func get_difficulty_name() -> String:
	match creation_difficulty:
		CreationDifficulty.HOUSEHOLD:
			return "Household"
		CreationDifficulty.BASIC:
			return "Basic"
		CreationDifficulty.MILITARY:
			return "Military"
		CreationDifficulty.ELITE:
			return "Elite"
		_:
			return "Unknown"

# Get the complexity coefficient based on difficulty
func get_complexity_coefficient() -> float:
	var config = Global.get_config()
	
	match creation_difficulty:
		CreationDifficulty.HOUSEHOLD:
			return config.complexity_mod_level_1
		CreationDifficulty.BASIC:
			return config.complexity_mod_level_2
		CreationDifficulty.MILITARY:
			return config.complexity_mod_level_3
		CreationDifficulty.ELITE:
			return config.complexity_mod_level_4
		_:
			return 1.0

# Matches recipe to category and difficulty requirements
func matches_category(required_category: Category) -> bool:
	return get_category() == required_category

func matches_difficulty(required_difficulty: CreationDifficulty) -> bool:
	return creation_difficulty >= required_difficulty

# Estimate material cost for a desired quality
func calculate_material_cost_estimate(desired_quality: int) -> int:
	# To be implemented in subclasses
	return 0
