@tool
extends EditorScript

# Шляхи до директорій для збереження ресурсів
const TOOL_COMPONENT_BASE_PATH = "res://data/items/components (simple items)/tool components/resources/"
const MATERIAL_COMPONENT_BASE_PATH = "res://data/items/components (simple items)/tool components/resources/materials/"

# Підпапки для різних типів компонентів
const COMPONENT_FOLDERS = {
	"Tools": "tools",
	"Materials": "materials"
}

# Структура для зберігання компонентів
var components = []

# Мапінг категорій та підкатегорій до відповідних типів і скриптів
var scripts_map = {
	"Tools": {
		"Tool Head": {"script": "ToolComponent", "type": ToolComponent.ToolComponentType.AXE_HEAD},
		"Tool Handle": {"script": "ToolComponent", "type": ToolComponent.ToolComponentType.TOOL_HANDLE}
	},
	"Materials": {
		"Usable": {"script": "UsableMaterialComponent", "type": UsableMaterialComponent.UsableMaterialType.WIRE},
		"Unusable": {"script": "UnusableMaterialComponent", "type": UnusableMaterialComponent.UnusableMaterialType.NAILS}
	}
}

# Функція для запуску скрипту
func _run():
	print("Запускаємо генератор компонентів інструментів та матеріалів...")
	
	# Переконуємось, що директорії існують
	ensure_directories_exist()
	
	# Ініціалізуємо дані вручну
	init_components()
	
	# Генеруємо компоненти
	generate_components()
	
	print("Генерація компонентів інструментів та матеріалів завершена!")

# Створює необхідні директорії, якщо вони не існують
func ensure_directories_exist():
	var dir = DirAccess.open("res://")
	if dir:
		# Створюємо базові директорії
		var tool_path = TOOL_COMPONENT_BASE_PATH
		var material_path = MATERIAL_COMPONENT_BASE_PATH
		
		# Створюємо шлях для tool components
		var current_path = ""
		for part in tool_path.split("/"):
			if part.is_empty():
				continue
			current_path += "/" + part
			if not dir.dir_exists(current_path):
				dir.make_dir(current_path)
				print("Створено директорію: " + current_path)
		
		# Створюємо шлях для material components
		current_path = ""
		for part in material_path.split("/"):
			if part.is_empty():
				continue
			current_path += "/" + part
			if not dir.dir_exists(current_path):
				dir.make_dir(current_path)
				print("Створено директорію: " + current_path)
		
		# Створюємо підпапки для різних типів компонентів
		for folder in COMPONENT_FOLDERS.values():
			var folder_path = tool_path + folder
			if not dir.dir_exists(folder_path):
				dir.make_dir(folder_path)
				print("Створено директорію: " + folder_path)

# Ініціалізація даних про вироби зі скріншотів
func init_components():
	print("Ініціалізація компонентів інструментів та матеріалів з даними зі скріншотів...")
	
	# ======= TOOLS =======
	
	# Tools - Tool Head
	var category = "Tools"
	var subcategory = "Tool Head"
	var subcategory_materials = "2x Metal"
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Axe Head",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": []
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Hand Hoe Head",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": []
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Scythe Head",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Shovel Head",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": []
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Pickaxe Head",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": []
	})
	
	# Tools - Tool Handle
	subcategory = "Tool Handle"
	subcategory_materials = "2x Wood"
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Tool Handle",
		"difficulty": "1",
		"materials": "2x Wood",
		"stations": ["Верстак", "Теслярний верстак"]
	})
	
	# ======= MATERIALS =======
	
	# Materials - Usable
	category = "Materials"
	subcategory = "Usable"
	subcategory_materials = "-"
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Wire",
		"difficulty": "1",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Волочильна дошка"]
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Metal Rings",
		"difficulty": "1",
		"materials": "1x Wire",
		"stations": ["Верстак", "Ковадло"]
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Chainmail Piece",
		"difficulty": "2",
		"materials": "5x Metal Ring",
		"stations": ["Верстак"]
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Metal Plate",
		"difficulty": "2",
		"materials": "2x Metal",
		"stations": ["Верстак", "Горн", "Велике Ковадло"]
	})
	
	# Materials - Unusable
	subcategory = "Unusable"
	subcategory_materials = "-"
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Nails",
		"difficulty": "1",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Ковадло"]
	})
	
	components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Horseshoe",
		"difficulty": "1",
		"materials": "1x Metal",
		"stations": []
	})
	
	print("Ініціалізовано компонентів інструментів та матеріалів: " + str(components.size()))

# Функція для генерації компонентів
func generate_components():
	print("Генерація компонентів інструментів та матеріалів...")
	
	# Мапінг специфічних типів компонентів
	var tool_type_mapping = {
		"Axe Head": ToolComponent.ToolComponentType.AXE_HEAD,
		"Hand Hoe Head": ToolComponent.ToolComponentType.HAND_HOE_HEAD,
		"Scythe Head": ToolComponent.ToolComponentType.SCYTHE_HEAD,
		"Shovel Head": ToolComponent.ToolComponentType.SHOVEL_HEAD,
		"Pickaxe Head": ToolComponent.ToolComponentType.PICKAXE_HEAD,
		"Tool Handle": ToolComponent.ToolComponentType.TOOL_HANDLE
	}
	
	var usable_type_mapping = {
		"Wire": UsableMaterialComponent.UsableMaterialType.WIRE,
		"Metal Rings": UsableMaterialComponent.UsableMaterialType.METAL_RING,
		"Chainmail Piece": UsableMaterialComponent.UsableMaterialType.CHAINMAIL_PIECE,
		"Metal Plate": UsableMaterialComponent.UsableMaterialType.METAL_PLATE
	}
	
	var unusable_type_mapping = {
		"Nails": UnusableMaterialComponent.UnusableMaterialType.NAILS,
		"Horseshoe": UnusableMaterialComponent.UnusableMaterialType.HORSESHOE
	}
	
	# Створюємо компоненти
	for item in components:
		# Пропускаємо рядки заголовків
		if item.category == "Категорія" or item.subcategory == "Підкатегорія":
			continue
		
		# Визначення типу компонента та скрипта
		var script_name = ""
		var component_type = null
		
		if item.category == "Tools":
			script_name = "ToolComponent"
			if item.name in tool_type_mapping:
				component_type = tool_type_mapping[item.name]
		elif item.category == "Materials":
			if item.subcategory == "Usable":
				script_name = "UsableMaterialComponent"
				if item.name in usable_type_mapping:
					component_type = usable_type_mapping[item.name]
			elif item.subcategory == "Unusable":
				script_name = "UnusableMaterialComponent"
				if item.name in unusable_type_mapping:
					component_type = unusable_type_mapping[item.name]
		
		if script_name.is_empty() or component_type == null:
			print("Пропуск: Не вдалося визначити тип або скрипт для ", item.name)
			continue
		
		# Створюємо компонент відповідного типу
		create_component(item, script_name, component_type)

# Створення компонента
func create_component(item_data, script_class_name: String, component_type):
	# Завантажуємо скрипт компонента
	var script_path = "res://data/items/components (simple items)/tool components/scripts/" + script_class_name.to_snake_case() + ".gd"
	var script = load(script_path)
	
	if not script:
		push_error("Скрипт не знайдено: " + script_path)
		return
	
	# Створюємо новий компонент
	var component = script.new()
	
	# Встановлюємо базові властивості
	component.name = item_data.name
	
	# Генеруємо цікавий опис англійською
	component.description = generate_description(item_data.name, script_class_name, component_type)
	
	# Встановлюємо тип компонента відповідно до скрипта
	match script_class_name:
		"ToolComponent":
			component.tool_type = component_type
		"UsableMaterialComponent":
			component.usable_material_type = component_type
		"UnusableMaterialComponent":
			component.unusable_material_type = component_type
	
	# Встановлюємо складність створення на основі вхідних даних
	match item_data.difficulty:
		"1": component.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": component.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": component.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": component.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: component.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Встановлюємо кількість виробів
	component.produced_quantity = 1
	
	# Парсимо та додаємо слоти для матеріалів
	setup_material_slots(component, item_data.materials)
	
	# Визначаємо папку для збереження компонента
	var save_path = ""
	
	if script_class_name == "ToolComponent":
		save_path = TOOL_COMPONENT_BASE_PATH + "tools/" + item_data.name.to_snake_case() + ".tres"
	else:  # MaterialComponent (Usable або Unusable)
		save_path = TOOL_COMPONENT_BASE_PATH + "materials/" + item_data.name.to_snake_case() + ".tres"
	
	# Зберігаємо ресурс
	var result = ResourceSaver.save(component, save_path)
	
	if result == OK:
		print("Компонент створено: " + save_path)
	else:
		push_error("Помилка при збереженні компонента: " + str(result))

# Функція для генерації унікальних описів
func generate_description(item_name: String, script_class_name: String, component_type) -> String:
	# Словники описів для різних типів компонентів
	var tool_head_descriptions = [
		"The business end of your farming ambitions.",
		"Surprisingly sharp for something made by an apprentice.",
		"Could be used as a weapon in a pinch. Not that we're suggesting anything.",
		"Guaranteed to last until the warranty expires.",
		"Will make short work of anything softer than itself.",
		"Has ended more trees than a Roman logging expedition."
	]
	
	var tool_handle_descriptions = [
		"The part you hold that doesn't hurt you. Usually.",
		"Crafted from wood that died of natural causes. Probably.",
		"More splinter-free than you'd expect from medieval craftsmanship.",
		"Ergonomically designed, if your idea of ergonomics is 'stick-shaped'.",
		"Carefully selected from trees that won't complain about their new purpose.",
		"Makes a satisfying 'thunk' when you hit things with it."
	]
	
	var wire_descriptions = [
		"Impossibly thin metal that's surprisingly useful.",
		"Metal that's had a rough day at the stretching rack.",
		"More versatile than you'd think, unless you're thinking 'very versatile'.",
		"Can be twisted into various shapes, much like the truth.",
		"Perfect for tying things that need to stay tied forever."
	]
	
	var metal_ring_descriptions = [
		"Round bits of metal with holes in the middle. Revolutionary!",
		"Not suitable for marriage proposals unless extremely desperate.",
		"Usually comes in groups of five, like fingers on a blacksmith's hand.",
		"The building blocks of chainmail and annoying jangly sounds.",
		"What happens when wire gets tired of being straight."
	]
	
	var chainmail_descriptions = [
		"Thousands of tiny rings linked together by an apprentice who questions life choices.",
		"Surprisingly heavy for something full of holes.",
		"Makes a pleasant jingling sound as you get stabbed slightly less.",
		"Takes forever to make, seconds to pierce if the weapon is pointy enough.",
		"The medieval equivalent of bubble wrap, but for protection instead of fun."
	]
	
	var metal_plate_descriptions = [
		"A flat piece of metal. Revolutionary technology for the 12th century.",
		"Thin enough to be flexible, thick enough to be useful.",
		"The answer to 'how can I make metal even more versatile?'",
		"Used in everything from armor to cookware. Mostly armor.",
		"What happens when you hit metal until it gives up and flattens."
	]
	
	var nail_descriptions = [
		"Pointy on one end, flat on the other. Simple yet effective.",
		"Useful for holding things together or causing tetanus. Your choice.",
		"They always come in packs of slightly fewer than you need.",
		"Medieval construction's best friend.",
		"Small, sharp, and remarkably adept at finding bare feet."
	]
	
	var horseshoe_descriptions = [
		"Like shoes, but for horses. And made of metal.",
		"Brings good luck if you find it. Brings hoof protection if you make it.",
		"Keeps horses from complaining about pebbles.",
		"Surprisingly difficult to attach without the horse filing a complaint.",
		"Makes a satisfying clop sound on cobblestone streets."
	]
	
	# Вибір списку описів на основі типу компонента
	var descriptions = []
	var component_name_lower = item_name.to_lower()
	
	if "head" in component_name_lower and "tool" in script_class_name.to_lower():
		descriptions = tool_head_descriptions
	elif "handle" in component_name_lower:
		descriptions = tool_handle_descriptions
	elif "wire" in component_name_lower:
		descriptions = wire_descriptions
	elif "ring" in component_name_lower:
		descriptions = metal_ring_descriptions
	elif "chainmail" in component_name_lower:
		descriptions = chainmail_descriptions
	elif "plate" in component_name_lower:
		descriptions = metal_plate_descriptions
	elif "nail" in component_name_lower:
		descriptions = nail_descriptions
	elif "horseshoe" in component_name_lower:
		descriptions = horseshoe_descriptions
	else:
		# Якщо не знайдено відповідність, використовуємо загальні описи
		return "A quality crafted component that serves its purpose admirably."
	
	# Додаємо специфічні описи для деяких особливих типів предметів
	if "axe" in component_name_lower:
		return "Makes trees regret their life choices since the Bronze Age."
	
	if "hoe" in component_name_lower:
		return "Turns hard dirt into slightly less hard dirt. Agricultural innovation at its finest."
	
	if "scythe" in component_name_lower:
		return "Like Death's favorite tool, but for wheat instead of souls."
	
	if "shovel" in component_name_lower:
		return "Ergonomically designed for digging holes and hiding evidence."
	
	if "pickaxe" in component_name_lower:
		return "For when rocks need convincing to become smaller rocks."
	
	# Вибір випадкового опису зі списку
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = rng.randi_range(0, descriptions.size() - 1)
	
	return descriptions[index]

# Налаштування слотів для матеріалів
func setup_material_slots(component, materials_str: String):
	if materials_str.is_empty():
		return
	
	# Розбиваємо рядок матеріалів на окремі вимоги
	var material_requirements = []
	
	# Обробляємо рядок у форматі "3x Metal 2x Wood 1x Leather"
	var parts = materials_str.split(" ")
	
	for i in range(0, parts.size()):
		if i + 1 < parts.size():
			var quantity_str = parts[i]
			var material_type = parts[i + 1]
			
			# Перевіряємо, чи є це форматом "3x"
			if quantity_str.ends_with("x"):
				quantity_str = quantity_str.left(quantity_str.length() - 1)
				
				# Вирішення для випадків з повним типом матеріалу, як "Metal Ring"
				if i + 2 < parts.size() and not parts[i + 2].contains("x"):
					material_type += " " + parts[i + 2]
					i += 1  # пропускаємо наступне слово, оскільки воно частина типу матеріалу
				
				material_requirements.append({
					"quantity": int(quantity_str),
					"type": material_type
				})
		
		i += 1  # Додаткове збільшення для правильного кроку
	
	# Створюємо слоти для кожного типу матеріалу
	for req in material_requirements:
		var quantity = req.quantity
		var material_type = req.type
		
		# Створюємо слот для матеріалу
		var material_slot = MaterialSlot.new()
		
		# Встановлюємо тип матеріалу
		match material_type:
			"Metal":
				material_slot.material_type = Enums.MaterialType.METAL
			"Wood":
				material_slot.material_type = Enums.MaterialType.WOOD
			"Wire":
				material_slot.material_type = Enums.MaterialType.CREATED
			"Metal Ring":
				material_slot.material_type = Enums.MaterialType.CREATED
			_:
				print("Невідомий тип матеріалу: " + material_type)
				continue
		
		# Встановлюємо кількість для слота
		material_slot.quantity = quantity
		
		# Встановлюємо вагу відповідно до типу матеріалу
		match material_type:
			"Metal":
				material_slot.weight = 3
			"Wood":
				material_slot.weight = 2
			"Wire", "Metal Ring":
				material_slot.weight = 3  # Для створених матеріалів використовуємо вагу як у металу
		
		# Встановлюємо обов'язковість
		material_slot.is_required = true
		
		# Встановлюємо максимальний стек - виправлена версія
		material_slot.max_stack = quantity
		
		# Додаємо слот до компонента
		component.component_slots.append(material_slot)
