@tool
extends EditorScript

# Шляхи до директорій для збереження ресурсів
const TOOL_ITEM_BASE_PATH = "res://data/items/products (complex items)/resources/tools/"

# Структура для зберігання виробів інструментів
var tool_items = []

# Функція для запуску скрипту
func _run():
	print("Запускаємо генератор складних виробів інструментів...")
	
	# Переконуємось, що директорії існують
	ensure_directories_exist()
	
	# Ініціалізуємо дані вручну
	init_tool_items()
	
	# Генеруємо вироби інструментів
	generate_tool_items()
	
	print("Генерація складних виробів інструментів завершена!")

# Створює необхідні директорії, якщо вони не існують
func ensure_directories_exist():
	var dir = DirAccess.open("res://")
	if dir:
		# Створюємо базову директорію
		var base_path = TOOL_ITEM_BASE_PATH
		var current_path = ""
		for part in base_path.split("/"):
			if part.is_empty():
				continue
			current_path += "/" + part
			if not dir.dir_exists(current_path):
				dir.make_dir(current_path)
				print("Створено директорію: " + current_path)

# Ініціалізація даних про вироби інструментів зі скріншотів
func init_tool_items():
	print("Ініціалізація складних виробів інструментів з даними зі скріншотів...")
	
	# Категорія: Tools
	var category = "Tools"
	var subcategory = "Tools"
	
	# Додаємо вироби інструментів зі скріншоту
	tool_items.append({
		"category": category,
		"subcategory": subcategory,
		"name": "Axe",
		"difficulty": "1",
		"unique_components": ["1x Axe Head"],
		"common_components": ["1x Tool Handle"],
		"quality_weights": "3 - Tool Head (Слот 1), 1 - Tool Handle (Слот 2)"
	})
	
	tool_items.append({
		"category": category,
		"subcategory": subcategory,
		"name": "Hand Hoe",
		"difficulty": "1",
		"unique_components": ["1x Hand Hoe Head"],
		"common_components": ["1x Tool Handle"],
		"quality_weights": "3 - Tool Head (Слот 1), 1 - Tool Handle (Слот 2)"
	})
	
	tool_items.append({
		"category": category,
		"subcategory": subcategory,
		"name": "Scythe",
		"difficulty": "1",
		"unique_components": ["1x Scythe Head"],
		"common_components": ["1x Tool Handle"],
		"quality_weights": "3 - Tool Head (Слот 1), 1 - Tool Handle (Слот 2)"
	})
	
	tool_items.append({
		"category": category,
		"subcategory": subcategory,
		"name": "Shovel",
		"difficulty": "1",
		"unique_components": ["1x Shovel Head"],
		"common_components": ["1x Tool Handle"],
		"quality_weights": "3 - Tool Head (Слот 1), 1 - Tool Handle (Слот 2)"
	})
	
	tool_items.append({
		"category": category,
		"subcategory": subcategory,
		"name": "Pickaxe",
		"difficulty": "1",
		"unique_components": ["1x Pickaxe Head"],
		"common_components": ["1x Tool Handle"],
		"quality_weights": "3 - Tool Head (Слот 1), 1 - Tool Handle (Слот 2)"
	})
	
	print("Ініціалізовано складних виробів інструментів: " + str(tool_items.size()))

# Функція для генерації складних виробів інструментів
func generate_tool_items():
	print("Генерація складних виробів інструментів...")
	
	# Створюємо вироби
	for item in tool_items:
		create_tool_item(item)

# Функція для створення складного виробу інструменту
func create_tool_item(item_data):
	# Створюємо новий ресурс ToolItem
	var tool_item = ToolItem.new()
	
	# Встановлюємо основні властивості
	tool_item.name = item_data.name
	tool_item.description = generate_description(item_data.name)
	
	# Встановлюємо тип інструменту на основі назви
	match item_data.name:
		"Axe":
			tool_item.tool_type = ToolItem.ToolType.AXE
		"Hand Hoe":
			tool_item.tool_type = ToolItem.ToolType.HAND_HOE
		"Scythe":
			tool_item.tool_type = ToolItem.ToolType.SCYTHE
		"Shovel":
			tool_item.tool_type = ToolItem.ToolType.SHOVEL
		"Pickaxe":
			tool_item.tool_type = ToolItem.ToolType.PICKAXE
		_:
			tool_item.tool_type = ToolItem.ToolType.AXE  # За замовчуванням
	
	# Встановлюємо складність створення
	match item_data.difficulty:
		"1": tool_item.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": tool_item.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": tool_item.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": tool_item.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: tool_item.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Встановлюємо кількість виробів
	tool_item.produced_quantity = 1
	
	# Додаємо слоти для компонентів
	setup_component_slots(tool_item, item_data)
	
	# Зберігаємо ресурс
	var file_name = item_data.name.to_snake_case() + ".tres"
	var save_path = TOOL_ITEM_BASE_PATH + file_name
	var result = ResourceSaver.save(tool_item, save_path)
	
	if result == OK:
		print("Складний виріб інструменту створено: " + save_path)
	else:
		push_error("Помилка при збереженні складного виробу інструменту: " + str(result))

# Функція для налаштування слотів компонентів
func setup_component_slots(tool_item, item_data):
	# Створюємо слоти для унікальних компонентів
	for component_str in item_data.unique_components:
		var parts = component_str.split("x ")
		if parts.size() >= 2:
			var quantity = int(parts[0])
			var component_name = parts[1].strip_edges()
			
			# Створюємо слот для компонента
			var component_slot = ComponentSlot.new()
			
			# Встановлюємо властивості слота
			component_slot.quantity = quantity
			component_slot.is_required = true
			
			# Встановлюємо вагу відповідно до типу компонента
			if "Head" in component_name:
				component_slot.weight = 3  # Важливіший компонент має більшу вагу
			else:
				component_slot.weight = 1
			
			# Встановлюємо обмеження за типом компонента
			var allowed_component = get_allowed_component_by_name(component_name)
			if allowed_component:
				component_slot.allowed_component = allowed_component
			
			# Додаємо слот до виробу
			tool_item.component_slots.append(component_slot)
	
	# Створюємо слоти для спільних компонентів
	for component_str in item_data.common_components:
		var parts = component_str.split("x ")
		if parts.size() >= 2:
			var quantity = int(parts[0])
			var component_name = parts[1].strip_edges()
			
			# Створюємо слот для компонента
			var component_slot = ComponentSlot.new()
			
			# Встановлюємо властивості слота
			component_slot.quantity = quantity
			component_slot.is_required = true
			
			# Встановлюємо вагу відповідно до типу компонента
			if "Handle" in component_name:
				component_slot.weight = 1  # Менш важливий компонент має меншу вагу
			else:
				component_slot.weight = 3
			
			# Встановлюємо обмеження за типом компонента
			var allowed_component = get_allowed_component_by_name(component_name)
			if allowed_component:
				component_slot.allowed_component = allowed_component
			
			# Додаємо слот до виробу
			tool_item.component_slots.append(component_slot)

# Функція для отримання дозволеного компонента за назвою
func get_allowed_component_by_name(component_name: String) -> SimpleItem:
	# В залежності від назви компонента, завантажуємо відповідний ресурс
	var component_path = ""
	
	match component_name:
		"Axe Head":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/axe_head.tres"
		"Hand Hoe Head":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/hand_hoe_head.tres"
		"Scythe Head":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/scythe_head.tres"
		"Shovel Head":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/shovel_head.tres"
		"Pickaxe Head":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/pickaxe_head.tres"
		"Tool Handle":
			component_path = "res://data/items/components (simple items)/tool components/resources/tools/tool_handle.tres"
	
	if component_path.is_empty():
		push_warning("Не знайдено шлях до компонента: " + component_name)
		return null
	
	# Завантажуємо ресурс компонента
	var component = load(component_path)
	if not component:
		push_warning("Не вдалося завантажити компонент: " + component_path)
		return null
	
	return component

# Функція для генерації опису для складного виробу інструменту
func generate_description(item_name: String) -> String:
	# Словник описів для різних типів інструментів
	var descriptions = {
		"Axe": [
			"The lumberjack's best friend. Trees tremble when you approach.",
			"Chops wood, fells trees, and occasionally terrifies woodland creatures.",
			"Perfect for turning large trees into smaller trees, and then into firewood.",
			"Makes quick work of anything wooden, including your neighbor's fence if you're not careful.",
			"The medieval multi-tool: woodcutter, weapon, and conversation starter all in one."
		],
		"Hand Hoe": [
			"Convinces the ground to accept seeds whether it wants to or not.",
			"Turns hard dirt into less hard dirt. Agricultural innovation at its finest.",
			"Perfect for gardening or impromptu self-defense against particularly slow attackers.",
			"Makes farming slightly less backbreaking, which isn't saying much.",
			"The farmer's loyal companion through many a long day in the fields."
		],
		"Scythe": [
			"Not just for the Grim Reaper anymore. Works great on wheat too!",
			"Harvests crops with a satisfying swish sound that terrifies city folk.",
			"Scares children and cuts grass. Two purposes for the price of one.",
			"The elegant weapon of farmers and personifications of death alike.",
			"Separates wheat from chaff, and occasionally fingers from hands if you're careless."
		],
		"Shovel": [
			"Moves dirt from one place to another, revolutionizing the concept of 'over there'.",
			"Perfect for digging holes, filling holes, and wondering why you dug the hole in the first place.",
			"The gravedigger's best friend, but useful for less morbid excavations too.",
			"Designed by someone who was tired of using their hands to move dirt around.",
			"Makes a satisfying 'thunk' sound when it hits something unexpectedly solid."
		],
		"Pickaxe": [
			"For when rocks need convincing to become smaller rocks.",
			"Turns 'impossible to mine' into 'just really difficult to mine'.",
			"Makes mining slightly less impossible, which still leaves it mostly impossible.",
			"The miner's trusted companion through many a dark tunnel.",
			"Perfect for extracting valuable minerals or creating impromptu cave-ins."
		]
	}
	
	# Вибір випадкового опису для інструменту
	if item_name in descriptions:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var index = rng.randi_range(0, descriptions[item_name].size() - 1)
		return descriptions[item_name][index]
	else:
		return "A finely crafted tool that would make any craftsman proud."
