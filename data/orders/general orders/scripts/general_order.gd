extends Order
class_name CategoryItemOrder

# Категорія предмета
@export var item_category: ItemData.Category
# Тип предмета (відповідає енумам в класах предметів)
@export var item_type: int
# Рівень складності
@export var creation_difficulty: ItemData.CreationDifficulty

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
func get_category_name(category: ItemData.Category) -> String:
	match category:
		ItemData.Category.WEAPONS:
			return "Weapon"
		ItemData.Category.ARMOR:
			return "Armor"
		ItemData.Category.TOOLS:
			return "Tool"
		_:
			return "Unknown"

# Отримання назви типу предмета
func get_type_name(category: ItemData.Category, type_value: int) -> String:
	match category:
		ItemData.Category.WEAPONS:
			return get_weapon_type_name(type_value)
		ItemData.Category.ARMOR:
			if type_value >= 100:  # Шоломи (з зміщенням)
				return get_head_armor_type_name(type_value - 100)
			else:  # Броня тіла
				return get_body_armor_type_name(type_value)
		ItemData.Category.TOOLS:
			return get_tool_type_name(type_value)
		_:
			return "Unknown Item"

# Отримання назви типу зброї
func get_weapon_type_name(weapon_type: int) -> String:
	match weapon_type:
		WeaponItem.WeaponType.ONE_HANDED_SWORD:
			return "One-Handed Sword"
		WeaponItem.WeaponType.DAGGER:
			return "Dagger"
		WeaponItem.WeaponType.SABER:
			return "Saber"
		WeaponItem.WeaponType.LONG_SWORD:
			return "Long Sword"
		WeaponItem.WeaponType.POLE_WEAPON:
			return "Pole Weapon"
		WeaponItem.WeaponType.HEAVY_WEAPON:
			return "Heavy Weapon"
		_:
			return "Unknown Weapon"

# Отримання назви типу броні тіла
func get_body_armor_type_name(armor_type: int) -> String:
	match armor_type:
		BodyArmorItem.BodyArmorType.TORSO_ARMOR:
			return "Torso Armor"
		BodyArmorItem.BodyArmorType.CHAINMAIL:
			return "Chainmail"
		BodyArmorItem.BodyArmorType.ARMS_ARMOR:
			return "Arm Guards"
		BodyArmorItem.BodyArmorType.LEGS_ARMOR:
			return "Leg Guards"
		_:
			return "Unknown Armor"

# Отримання назви типу шолома
func get_head_armor_type_name(armor_type: int) -> String:
	match armor_type:
		HeadArmorItem.HeadArmorType.WITHOUT_VISOR:
			return "Helmet without Visor"
		HeadArmorItem.HeadArmorType.WITH_VISOR:
			return "Helmet with Visor"
		HeadArmorItem.HeadArmorType.COIF:
			return "Coif"
		_:
			return "Unknown Helmet"

# Отримання назви типу інструмента
func get_tool_type_name(tool_type: int) -> String:
	match tool_type:
		ToolItem.ToolType.AXE:
			return "Axe"
		ToolItem.ToolType.HAND_HOE:
			return "Hand Hoe"
		ToolItem.ToolType.SCYTHE:
			return "Scythe"
		ToolItem.ToolType.SHOVEL:
			return "Shovel"
		ToolItem.ToolType.PICKAXE:
			return "Pickaxe"
		_:
			return "Unknown Tool"

# Отримання назви рівня складності
func get_difficulty_name(difficulty: ItemData.CreationDifficulty) -> String:
	match difficulty:
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

# Розрахунок середньої базової ціни на основі всіх підходящих рецептів
func calculate_average_base_price() -> void:
	if suitable_recipes.is_empty():
		base_price = 0
		return
	
	var total_price = 0
	
	for recipe in suitable_recipes:
		# Розрахунок ціни для цього рецепту
		var recipe_price = 0
		
		if recipe is ComplexItem:
			recipe_price = PriceCalculator.calculate_complex_item_material_cost(recipe, required_quality_min)
		
		total_price += recipe_price
	
	# Середня ціна
	base_price = total_price / suitable_recipes.size()
	
	# Встановлюємо ліміт ціни (для торгівлі) з урахуванням базової націнки
	var config = Global.get_config()
	price_limit = int(base_price * config.price_limit_multiplier)
	
	print("[CATEGORY_ORDER] Average base price: ", base_price)

# Перевизначення методу validate_item для перевірки відповідності категорії та типу
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Перевірка категорії
	if item.get_category() != item_category:
		return false
	
	# Перевірка типу предмета
	var item_type_value = -1
	
	match item_category:
		ItemData.Category.WEAPONS:
			if "weapon_type" in item:
				item_type_value = item.weapon_type
		ItemData.Category.ARMOR:
			if "body_armor_type" in item:
				item_type_value = item.body_armor_type
			elif "head_armor_type" in item:
				item_type_value = item.head_armor_type + 100  # Додаємо зміщення
		ItemData.Category.TOOLS:
			if "tool_type" in item:
				item_type_value = item.tool_type
	
	if item_type_value != item_type:
		return false
	
	# Перевірка рівня складності
	if item.creation_difficulty != creation_difficulty:
		return false
	
	return true

# Створення замовлення на категорію предметів
static func create_dagger_order(difficulty: ItemData.CreationDifficulty, customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_weapon_order(WeaponItem.WeaponType.DAGGER, difficulty, customer, min_quality)

# Створення замовлення на зброю певного типу
static func create_weapon_order(weapon_type: WeaponItem.WeaponType, difficulty: ItemData.CreationDifficulty, 
								customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(ItemData.Category.WEAPONS, weapon_type, difficulty, customer, min_quality)

# Створення замовлення на броню тіла певного типу
static func create_body_armor_order(armor_type: BodyArmorItem.BodyArmorType, difficulty: ItemData.CreationDifficulty, 
									customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(ItemData.Category.ARMOR, armor_type, difficulty, customer, min_quality)

# Створення замовлення на шолом певного типу
static func create_head_armor_order(armor_type: HeadArmorItem.HeadArmorType, difficulty: ItemData.CreationDifficulty, 
									customer: String, min_quality: int = -1) -> CategoryItemOrder:
	# Додаємо зміщення для шоломів
	return create_category_order(ItemData.Category.ARMOR, armor_type + 100, difficulty, customer, min_quality)

# Створення замовлення на інструмент певного типу
static func create_tool_order(tool_type: ToolItem.ToolType, difficulty: ItemData.CreationDifficulty, 
							  customer: String, min_quality: int = -1) -> CategoryItemOrder:
	return create_category_order(ItemData.Category.TOOLS, tool_type, difficulty, customer, min_quality)

# Базовий метод для створення замовлення на категорію предметів
static func create_category_order(category: ItemData.Category, type_value: int, difficulty: ItemData.CreationDifficulty, 
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
		ItemData.CreationDifficulty.HOUSEHOLD:
			complexity = 0.8
		ItemData.CreationDifficulty.BASIC:
			complexity = 1.0
		ItemData.CreationDifficulty.MILITARY:
			complexity = 1.2
		ItemData.CreationDifficulty.ELITE:
			complexity = 1.5
	
	order.prestige_gain = int(min_quality / config.prestige_gain_quality_divisor * complexity)
	
	# Set duration based on complexity
	order.duration_days = int(config.duration_days_multiplier * complexity)
	
	# Ініціалізація замовлення
	order.initialize_category_order()
	
	return order
