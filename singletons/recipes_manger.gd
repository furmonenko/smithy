extends Node

# Шляхи до теки з ресурсами
const COMPLEX_ITEMS_PATH = "res://data/items/products (complex items)/resources/"
const SIMPLE_ITEMS_PATH = "res://data/items/components (simple items)/resources/"

# Категорії складних речей
const ARMOR_PATH = COMPLEX_ITEMS_PATH + "armor/"
const BODY_ARMOR_PATH = ARMOR_PATH + "body_armor/"
const HEAD_ARMOR_PATH = ARMOR_PATH + "head_armor/"
const WEAPONS_PATH = COMPLEX_ITEMS_PATH + "weapons/"
const TOOLS_PATH = COMPLEX_ITEMS_PATH + "tools/"

# Категорії простих речей (компонентів)
const ARMOR_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "armor components/"
const TOOL_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "tool components/"
const WEAPON_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "weapon components/"

# Словники для зберігання завантажених ресурсів
var complex_items = {
	"body_armor": {},  # name -> ComplexItem
	"head_armor": {},  # name -> ComplexItem
	"weapons": {},     # name -> ComplexItem
	"tools": {}        # name -> ComplexItem
}

var simple_items = {
	"armor_components": {},  # name -> SimpleItem
	"tool_components": {},   # name -> SimpleItem
	"weapon_components": {}  # name -> SimpleItem
}

# Для пошуку за категоріями
var items_by_category = {
	ItemData.Category.ARMOR: [],
	ItemData.Category.WEAPONS: [],
	ItemData.Category.TOOLS: []
}

# Додаткові індекси для швидкого пошуку
# Структура: [категорія][підтип] -> Array[ComplexItem]
var complex_items_by_type = {
	ItemData.Category.ARMOR: {},
	ItemData.Category.WEAPONS: {},
	ItemData.Category.TOOLS: {}
}

# Словник для складності
var complex_items_by_difficulty = {}

# Словник всіх предметів для швидкого пошуку за ім'ям
var all_items = {}

# Флаг для перевірки чи дані вже завантажені
var _loaded = false

func _ready() -> void:
	# Завантаження при старті
	load_all_recipes()

# Завантаження всіх рецептів
func load_all_recipes() -> void:
	if _loaded:
		return
	
	print("[RECIPES] Starting recipes loading...")
	
	# Завантаження простих компонентів
	load_simple_items_from_directory(ARMOR_COMPONENTS_PATH, simple_items.armor_components)
	load_simple_items_from_directory(TOOL_COMPONENTS_PATH, simple_items.tool_components)
	load_simple_items_from_directory(WEAPON_COMPONENTS_PATH, simple_items.weapon_components)
	
	# Завантаження складних предметів
	load_complex_items_from_directory(BODY_ARMOR_PATH, complex_items.body_armor)
	load_complex_items_from_directory(HEAD_ARMOR_PATH, complex_items.head_armor)
	load_complex_items_from_directory(WEAPONS_PATH, complex_items.weapons)
	load_complex_items_from_directory(TOOLS_PATH, complex_items.tools)
	
	# Об'єднання в один словник для швидкого пошуку за ім'ям
	all_items.merge(simple_items.armor_components)
	all_items.merge(simple_items.tool_components)
	all_items.merge(simple_items.weapon_components)
	all_items.merge(complex_items.body_armor)
	all_items.merge(complex_items.head_armor)
	all_items.merge(complex_items.weapons)
	all_items.merge(complex_items.tools)
	
	# Створення індексів для пошуку
	build_category_indices()
	
	print("[RECIPES] Loaded ", all_items.size(), " total items")
	_loaded = true

# Завантаження простих предметів з теки (рекурсивно)
func load_simple_items_from_directory(directory_path: String, target_dict: Dictionary) -> void:
	_load_items_recursive(directory_path, target_dict, true)

# Завантаження складних предметів з теки (рекурсивно)
func load_complex_items_from_directory(directory_path: String, target_dict: Dictionary) -> void:
	_load_items_recursive(directory_path, target_dict, false)

# Рекурсивне завантаження предметів (проста чи складна)
func _load_items_recursive(directory_path: String, target_dict: Dictionary, is_simple: bool) -> void:
	var dir = DirAccess.open(directory_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				# Рекурсивно обробляємо підпапку
				var subdirectory = directory_path + file_name + "/"
				_load_items_recursive(subdirectory, target_dict, is_simple)
			elif file_name.ends_with(".tres"):
				var item_path = directory_path + file_name
				var item = null
				
				# Завантажуємо як простий або складний предмет залежно від параметра
				if is_simple:
					item = load(item_path) as SimpleItem
					if item:
						target_dict[item.name] = item
						print("[RECIPES] Loaded simple item: ", item.name)
					else:
						push_warning("[RECIPES] Failed to load simple item: " + item_path)
				else:
					item = load(item_path) as ComplexItem
					if item:
						target_dict[item.name] = item
						print("[RECIPES] Loaded complex item: ", item.name)
					else:
						push_warning("[RECIPES] Failed to load complex item: " + item_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("[RECIPES] An error occurred when trying to access the path: " + directory_path)

# Побудова індексів для пошуку за категоріями
func build_category_indices() -> void:
	# Очищення попередніх індексів
	items_by_category[ItemData.Category.ARMOR].clear()
	items_by_category[ItemData.Category.WEAPONS].clear()
	items_by_category[ItemData.Category.TOOLS].clear()
	
	complex_items_by_type[ItemData.Category.ARMOR].clear()
	complex_items_by_type[ItemData.Category.WEAPONS].clear()
	complex_items_by_type[ItemData.Category.TOOLS].clear()
	complex_items_by_difficulty.clear()
	
	# Додавання предметів в індекси за категоріями
	
	# 1. Body Armor
	for item in complex_items.body_armor.values():
		items_by_category[ItemData.Category.ARMOR].append(item)
		
		# Додавання в індекс за типом
		var armor_type = item.body_armor_type if "body_armor_type" in item else -1
		if armor_type != -1:
			if not complex_items_by_type[ItemData.Category.ARMOR].has(armor_type):
				complex_items_by_type[ItemData.Category.ARMOR][armor_type] = []
				
			complex_items_by_type[ItemData.Category.ARMOR][armor_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 2. Head Armor
	for item in complex_items.head_armor.values():
		items_by_category[ItemData.Category.ARMOR].append(item)
		
		# Додавання в індекс за типом
		var armor_type = item.head_armor_type if "head_armor_type" in item else -1
		if armor_type != -1:
			# Додаємо зміщення до типу шолома, щоб не конфліктувало з типом броні тіла
			var offset_type = armor_type + 100  # Умовне зміщення
			
			if not complex_items_by_type[ItemData.Category.ARMOR].has(offset_type):
				complex_items_by_type[ItemData.Category.ARMOR][offset_type] = []
				
			complex_items_by_type[ItemData.Category.ARMOR][offset_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 3. Weapons
	for item in complex_items.weapons.values():
		items_by_category[ItemData.Category.WEAPONS].append(item)
		
		# Додавання в індекс за типом
		var weapon_type = item.weapon_type if "weapon_type" in item else -1
		if weapon_type != -1:
			if not complex_items_by_type[ItemData.Category.WEAPONS].has(weapon_type):
				complex_items_by_type[ItemData.Category.WEAPONS][weapon_type] = []
				
			complex_items_by_type[ItemData.Category.WEAPONS][weapon_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 4. Tools
	for item in complex_items.tools.values():
		items_by_category[ItemData.Category.TOOLS].append(item)
		
		# Додавання в індекс за типом
		var tool_type = item.tool_type if "tool_type" in item else -1
		if tool_type != -1:
			if not complex_items_by_type[ItemData.Category.TOOLS].has(tool_type):
				complex_items_by_type[ItemData.Category.TOOLS][tool_type] = []
				
			complex_items_by_type[ItemData.Category.TOOLS][tool_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	print("[RECIPES] Built category indices:")
	print("[RECIPES] - Armor: ", items_by_category[ItemData.Category.ARMOR].size())
	print("[RECIPES] - Weapons: ", items_by_category[ItemData.Category.WEAPONS].size())
	print("[RECIPES] - Tools: ", items_by_category[ItemData.Category.TOOLS].size())

# Отримати предмет за ім'ям
func get_item(name: String) -> ItemData:
	if all_items.has(name):
		return all_items[name]
	return null

# Отримати простий предмет (компонент) за ім'ям
func get_simple_item(name: String) -> SimpleItem:
	var item = get_item(name)
	if item is SimpleItem:
		return item
	return null

# Отримати складний предмет за ім'ям
func get_complex_item(name: String) -> ComplexItem:
	var item = get_item(name)
	if item is ComplexItem:
		return item
	return null

# Отримати всі рецепти певної категорії
func get_recipes_by_category(category: ItemData.Category) -> Array:
	if items_by_category.has(category):
		return items_by_category[category]
	return []

# Отримати рецепти за категорією та типом
func get_recipes_by_type(category: ItemData.Category, item_type: int) -> Array:
	if complex_items_by_type.has(category) and complex_items_by_type[category].has(item_type):
		return complex_items_by_type[category][item_type]
	return []

# Отримати рецепти за типом зброї
func get_recipes_by_weapon_type(weapon_type: WeaponItem.WeaponType) -> Array:
	return get_recipes_by_type(ItemData.Category.WEAPONS, weapon_type)

# Отримати рецепти за типом броні тіла
func get_recipes_by_body_armor_type(armor_type: BodyArmorItem.BodyArmorType) -> Array:
	return get_recipes_by_type(ItemData.Category.ARMOR, armor_type)

# Отримати рецепти за типом шолома
func get_recipes_by_head_armor_type(armor_type: HeadArmorItem.HeadArmorType) -> Array:
	# Використовуємо зміщення для розрізнення типів шоломів
	return get_recipes_by_type(ItemData.Category.ARMOR, armor_type + 100)

# Отримати рецепти за типом інструмента
func get_recipes_by_tool_type(tool_type: ToolItem.ToolType) -> Array:
	return get_recipes_by_type(ItemData.Category.TOOLS, tool_type)

# Отримати рецепти за складністю
func get_recipes_by_difficulty(difficulty: ItemData.CreationDifficulty) -> Array:
	if complex_items_by_difficulty.has(difficulty):
		return complex_items_by_difficulty[difficulty]
	return []

# Отримати рецепти за категорією, типом та складністю
func get_recipes_by_criteria(category: ItemData.Category, item_type: int, difficulty: ItemData.CreationDifficulty) -> Array:
	var result = []
	
	# Спочатку отримуємо всі рецепти відповідного типу
	var type_recipes = get_recipes_by_type(category, item_type)
	
	# Фільтруємо за складністю
	for recipe in type_recipes:
		if recipe.creation_difficulty == difficulty:
			result.append(recipe)
	
	return result

# Отримати випадковий рецепт за критеріями
func get_random_recipe(category: ItemData.Category, item_type: int = -1, difficulty: ItemData.CreationDifficulty = -1) -> ComplexItem:
	var available_recipes = []
	
	if item_type >= 0 and difficulty >= 0:
		# Пошук за всіма критеріями
		available_recipes = get_recipes_by_criteria(category, item_type, difficulty)
	elif item_type >= 0:
		# Пошук тільки за категорією та типом
		available_recipes = get_recipes_by_type(category, item_type)
	elif difficulty >= 0:
		# Спочатку отримуємо всі рецепти категорії
		var category_recipes = get_recipes_by_category(category)
		
		# Фільтруємо за складністю
		for recipe in category_recipes:
			if recipe.creation_difficulty == difficulty:
				available_recipes.append(recipe)
	else:
		# Якщо не вказано ні типу, ні складності, беремо всі рецепти категорії
		available_recipes = get_recipes_by_category(category)
	
	# Якщо немає доступних рецептів, повертаємо null
	if available_recipes.is_empty():
		return null
	
	# Повертаємо випадковий рецепт
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = rng.randi() % available_recipes.size()
	
	return available_recipes[index]
