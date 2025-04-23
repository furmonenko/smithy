extends Node

# Шляхи до основних ресурсів
const CONFIG_PATH = "uid://c7hh0204v56is"
const MATERIALS_DATABASE_PATH = ""
const RECIPES_DATABASE_PATH = ""

# Кешовані ресурси
var _config: GameConfig = null
var _materials_database = null
var _recipes_database = null

# Сигнали
signal config_loaded
signal materials_database_loaded
signal recipes_database_loaded

# Флаг першої ініціалізації
var _initialized: bool = false

# Ініціалізація при старті
func _ready() -> void:
	# Якщо ще не ініціалізовано
	if not _initialized:
		# Завантаження необхідних ресурсів
		load_config()
		# load_materials_database()
		# load_recipes_database()
		
		_initialized = true

# Отримати конфігурацію гри
func get_config() -> GameConfig:
	if _config == null:
		load_config()
	return _config

# Завантажити конфігурацію
func load_config() -> void:
	var config_resource = load(CONFIG_PATH)
	if config_resource:
		_config = config_resource
		print("[GLOBAL] Config loaded successfully")
	else:
		push_error("[GLOBAL] Failed to load configuration, using default")
		_config = GameConfig.new()
	
	config_loaded.emit()

## Отримати базу даних матеріалів
#func get_materials_database():
	#if _materials_database == null:
		#load_materials_database()
	#return _materials_database

## Завантажити базу даних матеріалів
#func load_materials_database() -> void:
	#var database = load(MATERIALS_DATABASE_PATH)
	#if database:
		#_materials_database = database
		#print("[GLOBAL] Materials database loaded successfully")
	#else:
		#push_warning("[GLOBAL] Materials database not found")
		#_materials_database = null
	#
	#materials_database_loaded.emit()
#
## Отримати базу даних рецептів
#func get_recipes_database():
	#if _recipes_database == null:
		#load_recipes_database()
	#return _recipes_database
#
## Завантажити базу даних рецептів
#func load_recipes_database() -> void:
	#var database = load(RECIPES_DATABASE_PATH)
	#if database:
		#_recipes_database = database
		#print("[GLOBAL] Recipes database loaded successfully")
	#else:
		#push_warning("[GLOBAL] Recipes database not found")
		#_recipes_database = null
	#
	#recipes_database_loaded.emit()
#
## Отримати матеріал за ідентифікатором
#func get_material_by_id(material_id: String):
	#var database = get_materials_database()
	#if database and database.has_method("get_material"):
		#return database.get_material(material_id)
	#return null
#
## Отримати рецепт за ідентифікатором
#func get_recipe_by_id(recipe_id: String):
	#var database = get_recipes_database()
	#if database and database.has_method("get_recipe"):
		#return database.get_recipe(recipe_id)
	#return null

# Функція для форматування ціни (додає роздільники тисяч)
static func format_price(price: int) -> String:
	var price_str = str(price)
	var result = ""
	var count = 0
	
	for i in range(price_str.length() - 1, -1, -1):
		result = price_str[i] + result
		count += 1
		
		if count % 3 == 0 and i > 0:
			result = " " + result
	
	return result

# Функція для форматування часу
static func format_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return "%dг %dхв" % [hours, minutes]
	elif minutes > 0:
		return "%dхв %dс" % [minutes, secs]
	else:
		return "%dс" % secs

# Функція для отримання рандомного значення в межах
static func random_range(min_val: float, max_val: float) -> float:
	return min_val + (max_val - min_val) * randf()

# Функція для рандомного вибору елемента з масиву
static func random_choice(array: Array):
	if array.size() == 0:
		return null
	
	var index = randi() % array.size()
	return array[index]

# Функція для перевірки шансу (із заданим відсотком)
static func chance(percent: float) -> bool:
	return randf() <= percent / 100.0

# Отримати ідентифікатор сесії (для унікальних ідентифікаторів)
static func get_session_id() -> String:
	return str(int(Time.get_unix_time_from_system()))

# Генерувати унікальний ідентифікатор з префіксом
static func generate_id(prefix: String = "") -> String:
	var time_part = str(int(Time.get_unix_time_from_system() * 1000))
	var random_part = str(randi() % 10000).pad_zeros(4)
	return prefix + time_part + random_part
