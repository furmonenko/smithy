extends Node

# Шляхи до теки з ресурсами
const COMPLEX_ITEMS_PATH = "res://data/recipes/products (complex items)/resources/"
const SIMPLE_ITEMS_PATH = "res://data/recipes/components (simple items)/resources/"

# Категорії складних речей
const BODY_ARMOR_PATH = COMPLEX_ITEMS_PATH + "body_armor/"
const HEAD_ARMOR_PATH = COMPLEX_ITEMS_PATH + "head_armor/"
const WEAPONS_PATH = COMPLEX_ITEMS_PATH + "weapons/"
const TOOLS_PATH = COMPLEX_ITEMS_PATH + "tools/"

# Категорії простих речей (компонентів)
const ARMOR_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "armor components/"
const TOOL_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "tool components/"
const WEAPON_COMPONENTS_PATH = SIMPLE_ITEMS_PATH + "weapon components/"

# Словники для зберігання завантажених ресурсів
var complex_items = {
	"body_armor": {},  # name -> ProductRecipe
	"head_armor": {},  # name -> ProductRecipe
	"weapons": {},     # name -> ProductRecipe
	"tools": {}        # name -> ProductRecipe
}

var simple_items = {
	"armor_components": {},  # name -> ComponentRecipe
	"tool_components": {},   # name -> ComponentRecipe
	"weapon_components": {}  # name -> ComponentRecipe
}

# Для пошуку за категоріями
var items_by_category = {
	Recipe.Category.BODY_ARMOR: [],
	Recipe.Category.HEAD_ARMOR: [],
	Recipe.Category.WEAPONS: [],
	Recipe.Category.TOOLS: []
}

# Додаткові індекси для швидкого пошуку
# Структура: [категорія][підтип] -> Array[ProductRecipe]
var complex_items_by_type = {
	Recipe.Category.BODY_ARMOR: {},
	Recipe.Category.HEAD_ARMOR: {},
	Recipe.Category.WEAPONS: {},
	Recipe.Category.TOOLS: {}
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
					item = load(item_path) as ComponentRecipe
					if item:
						target_dict[item.name] = item
						print("[RECIPES] Loaded simple item: ", item.name)
					else:
						push_warning("[RECIPES] Failed to load simple item: " + item_path)
				else:
					item = load(item_path) as ProductRecipe
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
	items_by_category[Recipe.Category.BODY_ARMOR].clear()
	items_by_category[Recipe.Category.HEAD_ARMOR].clear()
	items_by_category[Recipe.Category.WEAPONS].clear()
	items_by_category[Recipe.Category.TOOLS].clear()
	
	complex_items_by_type[Recipe.Category.BODY_ARMOR].clear()
	complex_items_by_type[Recipe.Category.HEAD_ARMOR].clear()
	complex_items_by_type[Recipe.Category.WEAPONS].clear()
	complex_items_by_type[Recipe.Category.TOOLS].clear()
	complex_items_by_difficulty.clear()
	
	# Додавання предметів в індекси за категоріями
	
	# 1. Body Armor
	for item in complex_items.body_armor.values():
		items_by_category[Recipe.Category.BODY_ARMOR].append(item)
		
		# Додавання в індекс за типом
		var armor_type = item.body_armor_type if "body_armor_type" in item else -1
		if armor_type != -1:
			if not complex_items_by_type[Recipe.Category.BODY_ARMOR].has(armor_type):
				complex_items_by_type[Recipe.Category.BODY_ARMOR][armor_type] = []
				
			complex_items_by_type[Recipe.Category.BODY_ARMOR][armor_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 2. Head Armor
	for item in complex_items.head_armor.values():
		items_by_category[Recipe.Category.HEAD_ARMOR].append(item)
		
		# Додавання в індекс за типом
		var armor_type = item.head_armor_type if "head_armor_type" in item else -1
		if armor_type != -1:
			if not complex_items_by_type[Recipe.Category.HEAD_ARMOR].has(armor_type):
				complex_items_by_type[Recipe.Category.HEAD_ARMOR][armor_type] = []
				
			complex_items_by_type[Recipe.Category.HEAD_ARMOR][armor_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 3. Weapons
	for item in complex_items.weapons.values():
		items_by_category[Recipe.Category.WEAPONS].append(item)
		
		# Додавання в індекс за типом
		var weapon_type = item.weapon_type if "weapon_type" in item else -1
		if weapon_type != -1:
			if not complex_items_by_type[Recipe.Category.WEAPONS].has(weapon_type):
				complex_items_by_type[Recipe.Category.WEAPONS][weapon_type] = []
				
			complex_items_by_type[Recipe.Category.WEAPONS][weapon_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	# 4. Tools
	for item in complex_items.tools.values():
		items_by_category[Recipe.Category.TOOLS].append(item)
		
		# Додавання в індекс за типом
		var tool_type = item.tool_type if "tool_type" in item else -1
		if tool_type != -1:
			if not complex_items_by_type[Recipe.Category.TOOLS].has(tool_type):
				complex_items_by_type[Recipe.Category.TOOLS][tool_type] = []
				
			complex_items_by_type[Recipe.Category.TOOLS][tool_type].append(item)
		
		# Додавання в індекс за складністю
		var difficulty = item.creation_difficulty
		if not complex_items_by_difficulty.has(difficulty):
			complex_items_by_difficulty[difficulty] = []
			
		complex_items_by_difficulty[difficulty].append(item)
	
	print("[RECIPES] Built category indices:")
	print("[RECIPES] - Body Armor: ", items_by_category[Recipe.Category.BODY_ARMOR].size())
	print("[RECIPES] - Head Armor: ", items_by_category[Recipe.Category.HEAD_ARMOR].size())
	print("[RECIPES] - Weapons: ", items_by_category[Recipe.Category.WEAPONS].size())
	print("[RECIPES] - Tools: ", items_by_category[Recipe.Category.TOOLS].size())

# Отримати предмет за ім'ям
func get_item(name: String) -> Recipe:
	if all_items.has(name):
		return all_items[name]
	return null

# Отримати простий предмет (компонент) за ім'ям
func get_simple_item(name: String) -> ComponentRecipe:
	var item = get_item(name)
	if item is ComponentRecipe:
		return item
	return null

# Отримати складний предмет за ім'ям
func get_complex_item(name: String) -> ProductRecipe:
	var item = get_item(name)
	if item is ProductRecipe:
		return item
	return null

# Отримати всі рецепти певної категорії
func get_recipes_by_category(category: Recipe.Category) -> Array:
	if items_by_category.has(category):
		return items_by_category[category]
	return []

# Додамо допоміжну функцію для сумісності зі старим кодом, 
# яка повертає всі обладунки (тіла + голови)
func get_all_armor_recipes() -> Array:
	var body_armor = get_recipes_by_category(Recipe.Category.BODY_ARMOR)
	var head_armor = get_recipes_by_category(Recipe.Category.HEAD_ARMOR)
	return body_armor + head_armor

# Отримати рецепти за категорією та типом
func get_recipes_by_type(category: Recipe.Category, item_type: int) -> Array:
	if complex_items_by_type.has(category) and complex_items_by_type[category].has(item_type):
		return complex_items_by_type[category][item_type]
	return []

# Отримати рецепти за типом зброї
func get_recipes_by_weapon_type(weapon_type: WeaponRecipe.WeaponType) -> Array:
	return get_recipes_by_type(Recipe.Category.WEAPONS, weapon_type)

# Отримати рецепти за типом броні тіла
func get_recipes_by_body_armor_type(armor_type: BodyArmorRecipe.BodyArmorType) -> Array:
	return get_recipes_by_type(Recipe.Category.BODY_ARMOR, armor_type)

# Отримати рецепти за типом шолома
func get_recipes_by_head_armor_type(armor_type: HeadArmorRecipe.HeadArmorType) -> Array:
	return get_recipes_by_type(Recipe.Category.HEAD_ARMOR, armor_type)

# Отримати рецепти за типом інструмента
func get_recipes_by_tool_type(tool_type: ToolRecipe.ToolType) -> Array:
	return get_recipes_by_type(Recipe.Category.TOOLS, tool_type)

# Отримати рецепти за складністю
func get_recipes_by_difficulty(difficulty: Recipe.CreationDifficulty) -> Array:
	if complex_items_by_difficulty.has(difficulty):
		return complex_items_by_difficulty[difficulty]
	return []

# Отримати рецепти за категорією, типом та складністю
func get_recipes_by_criteria(category: Recipe.Category, item_type: int, difficulty: Recipe.CreationDifficulty) -> Array:
	var result = []
	
	# Спочатку отримуємо всі рецепти відповідного типу
	var type_recipes = get_recipes_by_type(category, item_type)
	
	# Фільтруємо за складністю
	for recipe in type_recipes:
		if recipe.creation_difficulty == difficulty:
			result.append(recipe)
	
	return result

# Отримати випадковий рецепт за критеріями
func get_random_recipe(category: Recipe.Category, item_type: int = -1, difficulty: Recipe.CreationDifficulty = -1) -> ProductRecipe:
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

# Функції для сумісності зі старим кодом, які обробляють запити з використанням ARMOR
# Маршрутизуємо їх на відповідні нові функції

# Функція, яка обробляє старі запити з Recipe.Category.ARMOR
func _handle_armor_category_request(request_type: String, params = null) -> Array:
	var body_results = []
	var head_results = []
	
	# Розділяємо операцію на дві частини - для body_armor і head_armor
	match request_type:
		"get_recipes_by_category":
			body_results = get_recipes_by_category(Recipe.Category.BODY_ARMOR)
			head_results = get_recipes_by_category(Recipe.Category.HEAD_ARMOR)
		"get_recipes_by_criteria":
			if params:
				# Для обробки запитів за типом потрібна додаткова логіка
				var item_type = params["item_type"]
				var difficulty = params["difficulty"]
				
				# Визначаємо, до якої категорії належить тип
				if item_type < 100:  # Броня тіла
					body_results = get_recipes_by_criteria(Recipe.Category.BODY_ARMOR, item_type, difficulty)
				else:  # Шоломи (з урахуванням зміщення)
					head_results = get_recipes_by_criteria(Recipe.Category.HEAD_ARMOR, item_type - 100, difficulty)
		"get_random_recipe":
			if params:
				var item_type = params.get("item_type", -1)
				var difficulty = params.get("difficulty", -1)
				
				# Визначаємо, до якої категорії належить тип
				if item_type < 0:  # Якщо тип не вказано, вибираємо випадково між body і head
					var use_body = randf() > 0.5
					if use_body:
						return [get_random_recipe(Recipe.Category.BODY_ARMOR, -1, difficulty)]
					else:
						return [get_random_recipe(Recipe.Category.HEAD_ARMOR, -1, difficulty)]
				elif item_type < 100:  # Броня тіла
					return [get_random_recipe(Recipe.Category.BODY_ARMOR, item_type, difficulty)]
				else:  # Шоломи (з урахуванням зміщення)
					return [get_random_recipe(Recipe.Category.HEAD_ARMOR, item_type - 100, difficulty)]
	
	# Об'єднуємо результати
	return body_results + head_results

# Функція для обробки запитів Recipe.Category.ARMOR, яка збереже сумісність зі старим кодом
func handle_legacy_armor_request(function_name: String, params = null) -> Variant:
	if function_name == "get_random_recipe":
		return _handle_armor_category_request(function_name, params)[0]
	else:
		return _handle_armor_category_request(function_name, params)
