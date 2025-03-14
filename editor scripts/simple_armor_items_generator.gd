@tool
extends EditorScript

# Шляхи до директорій для збереження ресурсів
const ARMOR_COMPONENT_BASE_PATH = "res://data/items/components (simple items)/armor components/resources/"

# Підпапки для різних типів компонентів
const ARMOR_COMPONENT_FOLDERS = {
	"Head Armor": "head_armor",
	"Body Armor": "body_armor"
}

# Структура для зберігання компонентів броні
var armor_components = []

# Мапінг категорій та підкатегорій до відповідних типів і скриптів
var scripts_map = {
	"Head Armor": {
		"Dome": {"script": "HeadArmorComponent", "type": HeadArmorComponent.HeadArmorType.DOME},
		"Visor": {"script": "HeadArmorComponent", "type": HeadArmorComponent.HeadArmorType.VISOR},
		"Head Liner": {"script": "HeadArmorComponent", "type": HeadArmorComponent.HeadArmorType.HEAD_LINER}
	},
	"Body Armor": {
		"Torso Armor": {"script": "BodyArmorComponent", "type": BodyArmorComponent.BodyArmorType.TORSO_ARMOR},
		"Arms Armor": {"script": "BodyArmorComponent", "type": BodyArmorComponent.BodyArmorType.ARMS_ARMOR},
		"Legs Armor": {"script": "BodyArmorComponent", "type": BodyArmorComponent.BodyArmorType.LEGS_ARMOR},
		"Body Liner": {"script": "BodyArmorComponent", "type": BodyArmorComponent.BodyArmorType.BODY_LINER},
		"Limb Liner": {"script": "BodyArmorComponent", "type": BodyArmorComponent.BodyArmorType.LIMB_LINER}
	}
}

# Функція для запуску скрипту
func _run():
	print("Запускаємо генератор простих виробів броні...")
	
	# Переконуємось, що директорії існують
	ensure_directories_exist()
	
	# Ініціалізуємо дані вручну
	init_armor_components()
	
	# Генеруємо компоненти броні
	generate_armor_components()
	
	print("Генерація простих виробів броні завершена!")

# Створює необхідні директорії, якщо вони не існують
func ensure_directories_exist():
	var dir = DirAccess.open("res://")
	if dir:
		# Створюємо базову директорію
		var base_path = ARMOR_COMPONENT_BASE_PATH
		var current_path = ""
		for part in base_path.split("/"):
			if part.is_empty():
				continue
			current_path += "/" + part
			if not dir.dir_exists(current_path):
				dir.make_dir(current_path)
				print("Створено директорію: " + current_path)
		
		# Створюємо підпапки для різних типів компонентів
		for folder in ARMOR_COMPONENT_FOLDERS.values():
			var folder_path = base_path + folder
			if not dir.dir_exists(folder_path):
				dir.make_dir(folder_path)
				print("Створено директорію: " + folder_path)

# Ініціалізація даних про вироби зі скріншотів
func init_armor_components():
	print("Ініціалізація компонентів броні з даними зі скріншотів...")
	
	# ======= HEAD ARMOR =======
	
	# Head Armor - Dome
	var category = "Head Armor"
	var subcategory = "Dome"
	var subcategory_materials = "3x Metal Plate"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Kettle-Hat Dome",
		"difficulty": "2",
		"materials": "3x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Bascinet Dome",
		"difficulty": "3",
		"materials": "3x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Armet Dome",
		"difficulty": "4",
		"materials": "4x Metal Plate",
		"stations": ["Верстак", "Горн", "Бронярське Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Szyszak Dome",
		"difficulty": "3",
		"materials": "2x Metal Plate 2x Chainmail Piece",
		"stations": []
	})
	
	# Head Armor - Visor
	subcategory = "Visor"
	subcategory_materials = "2x Metal Plate"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Static Visor",
		"difficulty": "2",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Folding Visor",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Nose Protection",
		"difficulty": "2",
		"materials": "1x Metal Plate",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	# Head Armor - Head Liner
	subcategory = "Head Liner"
	subcategory_materials = "1x Leather 1x Fabric"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Leather Liner",
		"difficulty": "2",
		"materials": "3x Leather",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Fabric Liner",
		"difficulty": "2",
		"materials": "3x Fabric",
		"stations": ["Верстак"]
	})
	
	# ======= BODY ARMOR =======
	
	# Body Armor - Torso Armor
	category = "Body Armor"
	subcategory = "Torso Armor"
	subcategory_materials = "4x Metal Plate"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Front Cuirass",
		"difficulty": "3",
		"materials": "5x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Back Cuirass",
		"difficulty": "3",
		"materials": "4x Metal Plate",
		"stations": ["Верстак", "Горн", "Бронярське Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Plates on rope",
		"difficulty": "2",
		"materials": "3x Metal Plate 1x Fabric",
		"stations": []
	})
	
	# Body Armor - Body Liner
	subcategory = "Body Liner"
	subcategory_materials = "2x Leather 2x Fabric"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Leather Liner",
		"difficulty": "2",
		"materials": "4x Leather",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Fabric Liner",
		"difficulty": "2",
		"materials": "4x Fabric",
		"stations": ["Верстак"]
	})
	
	# Body Armor - Limb Liner
	subcategory = "Limb Liner"
	subcategory_materials = "1x Leather 1x Fabric"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Leather Liner",
		"difficulty": "2",
		"materials": "2x Leather",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Fabric Liner",
		"difficulty": "2",
		"materials": "2x Fabric",
		"stations": []
	})
	
	# Body Armor - Arms Armor
	subcategory = "Arms Armor"
	subcategory_materials = "2x Metal Plate"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Pauldrons Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Rerebracers Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Vambraces Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Gauntlets Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": ["Верстак", "Горн", "Бронярське Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	# Body Armor - Legs Armor
	subcategory = "Legs Armor"
	subcategory_materials = "2x Metal Plate"
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Cuisses Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Greaves Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	armor_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Sabatons Plate",
		"difficulty": "3",
		"materials": "2x Metal Plate",
		"stations": []
	})
	
	print("Ініціалізовано компонентів броні: " + str(armor_components.size()))

# Функція для генерації компонентів броні
func generate_armor_components():
	print("Генерація компонентів броні...")
	
	# Створюємо компоненти
	for item in armor_components:
		# Пропускаємо рядки заголовків
		if item.category == "Категорія" or item.subcategory == "Підкатегорія":
			continue
		
		# Перевіряємо наявність відповідного скрипта
		if not scripts_map.has(item.category) or not scripts_map[item.category].has(item.subcategory):
			print("Пропуск: Не знайдено відповідного скрипта для ", item.category, " > ", item.subcategory)
			continue
		
		# Отримуємо інформацію про скрипт
		var script_info = scripts_map[item.category][item.subcategory]
		var script_name = script_info.script
		var component_type = script_info.type
		
		# Створюємо компонент відповідного типу
		create_armor_component(item, script_name, component_type)

# Створення компонента броні
func create_armor_component(item_data, script_class_name: String, component_type):
	# Завантажуємо скрипт компонента
	var script_path = "res://data/items/components (simple items)/armor components/" + script_class_name.to_snake_case() + ".gd"
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
	
	# Отримуємо інформацію про тип компонента з scripts_map
	var script_info = null
	for category in scripts_map:
		if category == item_data.category:
			for subcategory in scripts_map[category]:
				if subcategory == item_data.subcategory:
					script_info = scripts_map[category][subcategory]
					break
			break
	
	if script_info:
		# Встановлюємо тип компонента
		match script_class_name:
			"HeadArmorComponent":
				component.head_armor_type = script_info.type
			"BodyArmorComponent":
				component.body_armor_type = script_info.type
	else:
		push_warning("Не знайдено інформацію про тип компонента для " + item_data.name)
	
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
	var folder = ARMOR_COMPONENT_FOLDERS.get(item_data.category, "")
	if folder.is_empty():
		push_warning("Не знайдено папку для категорії: " + item_data.category)
		return
	
	# Створюємо ім'я файлу (замінюємо пробіли на підкреслення)
	var file_name = item_data.name.to_snake_case() + ".tres"
	
	# Зберігаємо ресурс
	var save_path = ARMOR_COMPONENT_BASE_PATH + folder + "/" + file_name
	var result = ResourceSaver.save(component, save_path)
	
	if result == OK:
		print("Компонент створено: " + save_path)
	else:
		push_error("Помилка при збереженні компонента: " + str(result))

# Функція для генерації унікальних описів
func generate_description(item_name: String, script_class_name: String, component_type) -> String:
	# Словники описів для різних типів компонентів броні
	var dome_descriptions = [
		"Keeps your head intact during unexpected sword encounters.",
		"Like an umbrella for your brain, but made of metal.",
		"Surprisingly comfortable, especially compared to having your skull split open.",
		"Successfully tested against blunt objects by apprentices who don't know any better.",
		"Stylish, protective, and only slightly claustrophobic.",
		"Makes a satisfying 'dong' sound when struck, which is preferable to the sound an unprotected head makes."
	]
	
	var visor_descriptions = [
		"Provides all the visibility of looking through a mail slot.",
		"Protection for your face, at the cost of peripheral vision.",
		"Surprisingly effective at hiding your fear from your opponents.",
		"May fog up during intense breathing. Try not to breathe.",
		"Gives you that mysterious knight look that drives the ladies wild."
	]
	
	var liner_descriptions = [
		"Transforms uncomfortable metal into slightly less uncomfortable metal.",
		"Absorbs sweat so your armor doesn't have to.",
		"The unsung hero of armor components.",
		"Prevents your skin from becoming one with your armor.",
		"Adds a touch of comfort to an otherwise miserable experience.",
		"Turns armor from 'torture device' to 'merely uncomfortable'."
	]
	
	var plate_descriptions = [
		"Adds another layer between you and sharp pointy things.",
		"When being stabbed is simply not an option.",
		"Tested against arrows, swords, and maces. Results vary.",
		"Remember: the shiny side faces outward.",
		"Makes a wonderful 'clang' when struck by weapons.",
		"Guaranteed to reduce the effectiveness of edged weapons by at least 30%."
	]
	
	var gauntlet_descriptions = [
		"Keeps your fingers attached during battle, mostly.",
		"Perfect for dramatic fist clenching.",
		"For when you want to punch someone wearing armor.",
		"Makes picking your nose significantly more challenging.",
		"May occasionally pinch. Consider it battle practice."
	]
	
	var leg_armor_descriptions = [
		"Because legs are worth protecting too.",
		"Helps prevent that awkward 'arrow to the knee' situation.",
		"Makes running away slightly more difficult, but surviving much more likely.",
		"Not great for dancing, excellent for surviving.",
		"Adds a satisfying 'clank' to your heroic stride."
	]
	
	# Вибір списку описів на основі типу компонента
	var descriptions = []
	var component_name_lower = item_name.to_lower()
	
	if "dome" in component_name_lower:
		descriptions = dome_descriptions
	elif "visor" in component_name_lower or "protection" in component_name_lower:
		descriptions = visor_descriptions
	elif "liner" in component_name_lower:
		descriptions = liner_descriptions
	elif "plate" in component_name_lower:
		descriptions = plate_descriptions
	elif "gauntlet" in component_name_lower:
		descriptions = gauntlet_descriptions
	elif "cuisse" in component_name_lower or "greave" in component_name_lower or "sabaton" in component_name_lower:
		descriptions = leg_armor_descriptions
	else:
		# Якщо не знайдено відповідність, використовуємо загальні описи
		return "A finely crafted piece of armor that might just save your life one day."
	
	# Додаємо специфічні описи для деяких особливих типів предметів
	if "armet" in component_name_lower:
		return "The height of head protection technology. Makes your silhouette 20% more intimidating."
	
	if "kettle" in component_name_lower:
		return "Simple, practical, and bears an uncanny resemblance to actual kitchen equipment."
	
	if "bascinet" in component_name_lower:
		return "Elegant protection for the discriminating knight. Visor sold separately."
	
	if "chainmail" in component_name_lower:
		return "Thousands of tiny rings, each representing hours of apprentice labor and suffering."
	
	if "cuirass" in component_name_lower:
		return "The fancy word for 'chest plate' that makes it sound worth the money."
	
	if "pauldron" in component_name_lower:
		return "Shoulder protection that doubles as a fashion statement. Makes doorways your sworn enemy."
	
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
	
	# Обробляємо рядок у форматі "3x Metal Plate 2x Wood 1x Leather"
	var parts = materials_str.split(" ")
	
	for i in range(0, parts.size()):
		if i + 1 < parts.size():
			var quantity_str = parts[i]
			var material_type = parts[i + 1]
			
			# Перевіряємо, чи є це форматом "3x"
			if quantity_str.ends_with("x"):
				quantity_str = quantity_str.left(quantity_str.length() - 1)
				
				# Вирішення для випадків з повним типом матеріалу, як "Metal Plate"
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
			"Metal Plate":
				material_slot.material_type = Enums.MaterialType.METAL
			"Chainmail Piece":
				material_slot.material_type = Enums.MaterialType.CREATED  # Спеціальний тип для створених компонентів
			"Wood":
				material_slot.material_type = Enums.MaterialType.WOOD
			"Leather":
				material_slot.material_type = Enums.MaterialType.LEATHER
			"Fabric":
				material_slot.material_type = Enums.MaterialType.FABRIC
			"Decoration":
				material_slot.material_type = Enums.MaterialType.DECORATION
			_:
				print("Невідомий тип матеріалу: " + material_type)
				continue
		
		# Встановлюємо кількість для слота
		material_slot.quantity = quantity
		
		# Встановлюємо вагу відповідно до типу матеріалу
		match material_type:
			"Metal Plate":
				material_slot.weight = 3
			"Chainmail Piece":
				material_slot.weight = 2
			"Wood":
				material_slot.weight = 2
			"Leather", "Fabric":
				material_slot.weight = 1
			"Decoration":
				material_slot.weight = 2
		
		# Встановлюємо обов'язковість
		material_slot.is_required = true
		
		# Встановлюємо максимальний стек - виправлена версія
		material_slot.max_stack = quantity
		
		# Додаємо слот до компонента
		component.component_slots.append(material_slot)
