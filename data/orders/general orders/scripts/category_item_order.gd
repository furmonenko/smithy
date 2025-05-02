extends Order
class_name CategoryItemOrder

# Категорія предмета
@export var item_category: Recipe.Category

@export_group("Item Type")
@export_multiline var types_reference = """ Weapons:
  0 = ONE_HANDED_SWORD
  1 = SABER
  2 = LONG_SWORD
  3 = POLE_WEAPON
  4 = HEAVY_WEAPON
  5 = DAGGER

Body Armor:
  0 = TORSO_ARMOR
  1 = CHAINMAIL
  2 = ARMS_ARMOR
  3 = LEGS_ARMOR

Head Armor:
  0 = WITHOUT_VISOR
  1 = WITH_VISOR
  2 = COIF

Tools:
  0 = AXE
  1 = HAND_HOE
  2 = SCYTHE
  3 = SHOVEL
  4 = PICKAXE """
@export_range(-1, 100, 1, "or_greater") var item_type: int = -1
@export_group("")

# Рівень складності
@export var creation_difficulty: Recipe.CreationDifficulty

# Придатні рецепти, які відповідають вимогам
var suitable_recipes: Array = []

func _init() -> void:
	super()
	# order_type = OrderType.CATEGORY_ITEM

# Ініціалізація замовлення
func initialize_category_order() -> void:
	# Знаходження підходящих рецептів
	find_suitable_recipes()
	
	# Якщо знайдені підходящі рецепти, обчислюємо середню ціну
	if not suitable_recipes.is_empty():
		calculate_average_base_price()
	
	# Встановлюємо опис
	generate_description()

# Пошук придатних рецептів у базі даних
func find_suitable_recipes() -> void:
	suitable_recipes.clear()
	
	# Отримання рецептів за критеріями з RecipesManager
	suitable_recipes = RecipesManager.get_recipes_by_criteria(item_category, item_type, creation_difficulty)
	
	print("[CATEGORY_ORDER] Found ", suitable_recipes.size(), " suitable recipes")

# Генерація опису замовлення
func generate_description() -> void:
	var category_name = get_category_name(item_category)
	var type_name = get_type_name(item_category, item_type)
	var difficulty_name = get_difficulty_name(creation_difficulty)
	
	order_name = "Order for " + type_name
	description = "Create a " + difficulty_name + " " + type_name + " with at least " + str(required_quality_min) + " quality."
	
	if suitable_recipes.is_empty():
		description += "\n\nWARNING: No suitable recipes found for this category."

# Отримання назви категорії
func get_category_name(category: Recipe.Category) -> String:
	match category:
		Recipe.Category.WEAPONS:
			return "Weapon"
		Recipe.Category.BODY_ARMOR:
			return "Body Armor"
		Recipe.Category.HEAD_ARMOR:
			return "Head Armor"
		Recipe.Category.TOOLS:
			return "Tool"
		_:
			return "Unknown"

# Отримання назви типу предмета
func get_type_name(category: Recipe.Category, type_value: int) -> String:
	match category:
		Recipe.Category.WEAPONS:
			return get_weapon_type_name(type_value)
		Recipe.Category.BODY_ARMOR:
			return get_body_armor_type_name(type_value)
		Recipe.Category.HEAD_ARMOR:
			return get_head_armor_type_name(type_value)
		Recipe.Category.TOOLS:
			return get_tool_type_name(type_value)
		_:
			return "Unknown Item"

# Отримання назви типу зброї
func get_weapon_type_name(weapon_type: int) -> String:
	match weapon_type:
		WeaponRecipe.WeaponType.ONE_HANDED_SWORD:
			return "One-Handed Sword"
		WeaponRecipe.WeaponType.DAGGER:
			return "Dagger"
		WeaponRecipe.WeaponType.SABER:
			return "Saber"
		WeaponRecipe.WeaponType.LONG_SWORD:
			return "Long Sword"
		WeaponRecipe.WeaponType.POLE_WEAPON:
			return "Pole Weapon"
		WeaponRecipe.WeaponType.HEAVY_WEAPON:
			return "Heavy Weapon"
		_:
			return "Unknown Weapon"

# Отримання назви типу броні тіла
func get_body_armor_type_name(armor_type: int) -> String:
	match armor_type:
		BodyArmorRecipe.BodyArmorType.TORSO_ARMOR:
			return "Torso Armor"
		BodyArmorRecipe.BodyArmorType.CHAINMAIL:
			return "Chainmail"
		BodyArmorRecipe.BodyArmorType.ARMS_ARMOR:
			return "Arm Guards"
		BodyArmorRecipe.BodyArmorType.LEGS_ARMOR:
			return "Leg Guards"
		_:
			return "Unknown Body Armor"

# Отримання назви типу шолома
func get_head_armor_type_name(armor_type: int) -> String:
	match armor_type:
		HeadArmorRecipe.HeadArmorType.WITHOUT_VISOR:
			return "Helmet without Visor"
		HeadArmorRecipe.HeadArmorType.WITH_VISOR:
			return "Helmet with Visor"
		HeadArmorRecipe.HeadArmorType.COIF:
			return "Coif"
		_:
			return "Unknown Head Armor"

# Отримання назви типу інструмента
func get_tool_type_name(tool_type: int) -> String:
	match tool_type:
		ToolRecipe.ToolType.AXE:
			return "Axe"
		ToolRecipe.ToolType.HAND_HOE:
			return "Hand Hoe"
		ToolRecipe.ToolType.SCYTHE:
			return "Scythe"
		ToolRecipe.ToolType.SHOVEL:
			return "Shovel"
		ToolRecipe.ToolType.PICKAXE:
			return "Pickaxe"
		_:
			return "Unknown Tool"

# Отримання назви рівня складності
func get_difficulty_name(difficulty: Recipe.CreationDifficulty) -> String:
	match difficulty:
		Recipe.CreationDifficulty.HOUSEHOLD:
			return "Household"
		Recipe.CreationDifficulty.BASIC:
			return "Basic"
		Recipe.CreationDifficulty.MILITARY:
			return "Military"
		Recipe.CreationDifficulty.ELITE:
			return "Elite"
		_:
			return "Unknown"

# Розрахунок середньої базової ціни на основі всіх підходящих рецептів
func calculate_average_base_price() -> void:
	if suitable_recipes.is_empty():
		base_price = 0
		return
	
	var total_price = 0
	
	for recipe in suitable_recipes:
		# Розрахунок ціни для цього рецепту
		var recipe_price = 0
		
		if recipe is ProductRecipe:
			recipe_price = PriceCalculator.calculate_complex_item_material_cost(recipe, required_quality_min)
		
		total_price += recipe_price
	
	# Середня ціна
	base_price = total_price / suitable_recipes.size()
	
	# Встановлюємо ліміт ціни (для торгівлі) з урахуванням базової націнки
	var config = Global.get_config()
	price_limit = int(base_price * config.price_limit_multiplier)
	
	print("[CATEGORY_ORDER] Average base price: ", base_price)

# Перевизначення методу validate_item для перевірки відповідності категорії та типу
func validate_item(item: Recipe) -> bool:
	if not super.validate_item(item):
		return false
	
	# Перевірка категорії
	if item.get_category() != item_category:
		return false
	
	# Перевірка типу предмета
	var item_type_value = -1
	
	match item_category:
		Recipe.Category.WEAPONS:
			if "weapon_type" in item:
				item_type_value = item.weapon_type
		Recipe.Category.BODY_ARMOR:
			if "body_armor_type" in item:
				item_type_value = item.body_armor_type
		Recipe.Category.HEAD_ARMOR:
			if "head_armor_type" in item:
				item_type_value = item.head_armor_type
		Recipe.Category.TOOLS:
			if "tool_type" in item:
				item_type_value = item.tool_type
	
	if item_type_value != item_type:
		return false
	
	# Перевірка рівня складності
	if item.creation_difficulty != creation_difficulty:
		return false
	
	return true

# Створення замовлення на категорію предметів
static func create_dagger_order(difficulty: Recipe.CreationDifficulty, customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_weapon_order(WeaponRecipe.WeaponType.DAGGER, difficulty, customer, min_quality)

# Створення замовлення на зброю певного типу
static func create_weapon_order(weapon_type: WeaponRecipe.WeaponType, difficulty: Recipe.CreationDifficulty, 
								customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(Recipe.Category.WEAPONS, weapon_type, difficulty, customer, min_quality)

# Створення замовлення на броню тіла певного типу
static func create_body_armor_order(armor_type: BodyArmorRecipe.BodyArmorType, difficulty: Recipe.CreationDifficulty, 
									customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(Recipe.Category.BODY_ARMOR, armor_type, difficulty, customer, min_quality)

# Створення замовлення на шолом певного типу
static func create_head_armor_order(armor_type: HeadArmorRecipe.HeadArmorType, difficulty: Recipe.CreationDifficulty, 
									customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(Recipe.Category.HEAD_ARMOR, armor_type, difficulty, customer, min_quality)

# Створення замовлення на інструмент певного типу
static func create_tool_order(tool_type: ToolRecipe.ToolType, difficulty: Recipe.CreationDifficulty, 
							  customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(Recipe.Category.TOOLS, tool_type, difficulty, customer, min_quality)

# Базовий метод для створення замовлення на категорію предметів
static func create_category_order(category: Recipe.Category, type_value: int, difficulty: Recipe.CreationDifficulty, 
								 customer: String, min_quality: int = -1) -> CategoryItemOrder:
	var order = CategoryItemOrder.new()
	
	# Налаштування категорії
	order.item_category = category
	order.item_type = type_value
	order.creation_difficulty = difficulty
	
	# Налаштування загальних параметрів
	var config = Global.get_config()
	
	# If min_quality not specified, use default from config
	if min_quality < 0:
		min_quality = config.default_min_quality
	
	order.required_quality_min = min_quality
	order.customer_id = customer
	
	# Calculate reputation impact and prestige gain
	order.reputation_impact = config.base_reputation_impact
	
	# Prestige gain based on complexity and quality
	var complexity = 1.0

	match difficulty:
		Recipe.CreationDifficulty.HOUSEHOLD:
			complexity = config.complexity_mod_level_1
		Recipe.CreationDifficulty.BASIC:
			complexity = config.complexity_mod_level_2
		Recipe.CreationDifficulty.MILITARY:
			complexity = config.complexity_mod_level_3
		Recipe.CreationDifficulty.ELITE:
			complexity = config.complexity_mod_level_4
	
	order.prestige_gain = int(min_quality / config.prestige_gain_quality_divisor * complexity)
	
	# Set duration based on complexity
	order.duration_days = int(config.duration_days_multiplier * complexity)
	
	# Ініціалізація замовлення
	order.initialize_category_order()
	
	return order
