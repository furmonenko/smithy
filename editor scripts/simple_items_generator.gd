@tool
extends EditorScript

# Шляхи до директорій для збереження ресурсів
const WEAPON_COMPONENT_BASE_PATH = "res://data/items/components (simple items)/weapon components/resources/"

# Підпапки для різних типів компонентів
const WEAPON_COMPONENT_FOLDERS = {
	"One-Handed Cut Weapon": "one_handed_cut_weapon",
	"Long Cut Weapon": "long_cut_weapon",
	"Pole Weapon": "pole_weapon",
	"Heavy Weapon": "heavy_weapon",
	"Dagger": "dagger"
}

# Структура для зберігання компонентів зброї
var weapon_components = []

# Мапінг категорій та підкатегорій до відповідних типів і скриптів
var scripts_map = {
	"One-Handed Cut Weapon": {
		"One-Handed Sword Blade": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_SWORD_BLADE},
		"Saber Blade": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.SABER_BLADE},
		"One-Handed Guard": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_GUARD},
		"One-Handed Pommel": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_POMMEL},
		"One-Handed Handle": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_HANDLE}
	},
	"Long Cut Weapon": {
		"Long Sword Blade": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_BLADE},
		"Lond Sword Guard": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_GUARD},
		"Long Sword Pommel": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_POMMEL},
		"Long Sword Handle": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_HANDLE}
	},
	"Pole Weapon": {
		"Pole Head": {"script": "PoleWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SPEAR_HEAD, "type": PoleWeaponComponent.PoleWeaponType.POLE_HEAD},
		"Pole Handle": {"script": "PoleWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": PoleWeaponComponent.PoleWeaponType.POLE_HANDLE}
	},
	"Heavy Weapon": {
		"Heavy Weapon Head": {"script": "HeavyWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.MACE_HEAD, "type": HeavyWeaponComponent.HeavyWeaponType.HEAVY_WEAPON_HEAD},
		"Heavy Weapon Handle": {"script": "HeavyWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": HeavyWeaponComponent.HeavyWeaponType.HEAVY_WEAPON_HANDLE}
	},
	"Dagger": {
		"Dagger Blade": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_BLADE},
		"Dagger Handle": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": DaggerComponent.DaggerType.DAGGER_HANDLE},
		"Dagger Pommel": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_POMMEL},
		"Dagger Guard": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_GUARD}
	}
}

# Функція для запуску скрипту
func _run():
	print("Запускаємо генератор простих виробів зброї...")
	
	# Переконуємось, що директорії існують
	ensure_directories_exist()
	
	# Ініціалізуємо дані вручну
	init_weapon_components()
	
	# Генеруємо компоненти зброї
	generate_weapon_components()
	
	print("Генерація простих виробів зброї завершена!")

# Створює необхідні директорії, якщо вони не існують
func ensure_directories_exist():
	var dir = DirAccess.open("res://")
	if dir:
		# Створюємо базову директорію
		var base_path = WEAPON_COMPONENT_BASE_PATH
		var current_path = ""
		for part in base_path.split("/"):
			if part.is_empty():
				continue
			current_path += "/" + part
			if not dir.dir_exists(current_path):
				dir.make_dir(current_path)
				print("Створено директорію: " + current_path)
		
		# Створюємо підпапки для різних типів компонентів
		for folder in WEAPON_COMPONENT_FOLDERS.values():
			var folder_path = base_path + folder
			if not dir.dir_exists(folder_path):
				dir.make_dir(folder_path)
				print("Створено директорію: " + folder_path)

# Ініціалізація даних про вироби зі скріншотів
func init_weapon_components():
	print("Ініціалізація компонентів зброї з даними зі скріншотів...")
	
	# ======= ONE-HANDED CUT WEAPON =======
	
	# One-Handed Cut Weapon - One-Handed Sword Blade
	var category = "One-Handed Cut Weapon"
	var subcategory = "One-Handed Sword Blade"
	var subcategory_materials = "4x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Short Sword Blade",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Arming Sword Blade",
		"difficulty": "3",
		"materials": "4x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Falchion Blade",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Estoc Blade",
		"difficulty": "3",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Noble Short Sword Bide",  # Саме так написано на скріні
		"difficulty": "4",
		"materials": "4x Metal 2x Decoration",
		"stations": ["Верстак", "Горн", "Велике Ковадло", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	# One-Handed Cut Weapon - Saber Blade
	subcategory = "Saber Blade"
	subcategory_materials = "4x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Saber Blade",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Polish Saber Blade",
		"difficulty": "3",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Tatar Saber Blade",
		"difficulty": "3",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Magyar Saber Blade",
		"difficulty": "4",
		"materials": "4x Metal",
		"stations": ["Верстак", "Горн", "Велике Ковадло", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Noble Saber Blade",
		"difficulty": "4",
		"materials": "4x Metal 2x Decoration",
		"stations": []
	})
	
	# One-Handed Cut Weapon - One-Handed Guard
	subcategory = "One-Handed Guard"
	subcategory_materials = "1x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Straight Guard",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Curved Guard",
		"difficulty": "3",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Guard",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Closed Guard",
		"difficulty": "3",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Коваль майстер", "Відро", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Guard",
		"difficulty": "4",
		"materials": "1x Metal 1x Decoration",
		"stations": []
	})
	
	# One-Handed Cut Weapon - One-Handed Pommel
	subcategory = "One-Handed Pommel"
	subcategory_materials = "1x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Round Pommel",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Pentagon Pommel",
		"difficulty": "3",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Long Pommel",
		"difficulty": "3",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Pommel",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Pommel",
		"difficulty": "4",
		"materials": "1x Metal 1x Decoration",
		"stations": []
	})
	
	# One-Handed Cut Weapon - One-Handed Handle
	subcategory = "One-Handed Handle"
	subcategory_materials = "1x Wood 1x Leather"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Handle",
		"difficulty": "2",
		"materials": "1x Wood",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Two-Part Handle",
		"difficulty": "3",
		"materials": "2x Wood",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Grip Handle",
		"difficulty": "3",
		"materials": "1x Wood 1x Leather",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Handle",
		"difficulty": "4",
		"materials": "1x Wood 1x Leather 1x Decoration",
		"stations": []
	})
	
	# ======= LONG CUT WEAPON =======
	
	# Long Cut Weapon - Long Sword Blade
	category = "Long Cut Weapon"
	subcategory = "Long Sword Blade"
	subcategory_materials = "7x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Bastard Sword Blade",
		"difficulty": "2",
		"materials": "6x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Noble Bastard Blade",
		"difficulty": "4",
		"materials": "6x Metal 3x Decoration",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Zweihänder Blade",
		"difficulty": "3",
		"materials": "8x Metal",
		"stations": ["Верстак", "Горн", "Велике Ковадло", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Claymore Blade",
		"difficulty": "4",
		"materials": "7x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Noble Zweihänder Blade",
		"difficulty": "4",
		"materials": "8x Metal 4x Decoration",
		"stations": []
	})
	
	# Long Cut Weapon - Lond Sword Guard
	subcategory = "Lond Sword Guard"
	subcategory_materials = "2x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Guard",
		"difficulty": "2",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Straight Guard",
		"difficulty": "3",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Curved Guard",
		"difficulty": "3",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Guard",
		"difficulty": "4",
		"materials": "2x Metal 1x Decoration",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	# Long Cut Weapon - Long Sword Pommel
	subcategory = "Long Sword Pommel"
	subcategory_materials = "2x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Pommel",
		"difficulty": "2",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Heavy Pommel",
		"difficulty": "3",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Pommel",
		"difficulty": "4",
		"materials": "2x Metal 1x Decoration",
		"stations": []
	})
	
	# Long Cut Weapon - Long Sword Handle
	subcategory = "Long Sword Handle"
	subcategory_materials = "2x Wood 1x Leather"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Handle",
		"difficulty": "2",
		"materials": "2x Wood",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Grip Handle",
		"difficulty": "3",
		"materials": "3x Wood 1x Leather",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Handle",
		"difficulty": "4",
		"materials": "3x Wood 2x Leather 1x Decoration",
		"stations": []
	})
	
	# ======= POLE WEAPON =======
	
	# Pole Weapon - Pole Head
	category = "Pole Weapon"
	subcategory = "Pole Head"
	subcategory_materials = "3x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Spear Head",
		"difficulty": "2",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Bardiche Head",
		"difficulty": "3",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Halberd Head",
		"difficulty": "3",
		"materials": "4x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Pike Head",
		"difficulty": "3",
		"materials": "2x Metal",
		"stations": []
	})
	
	# Pole Weapon - Pole Handle
	subcategory = "Pole Handle"
	subcategory_materials = "3x Wood 1x Leather"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Handle",
		"difficulty": "2",
		"materials": "3x Wood",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Grip Handle",
		"difficulty": "3",
		"materials": "3x Wood 2x Leather",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Ornamented Hande",
		"difficulty": "4",
		"materials": "4x Wood 3x Cloth 2x Decoration",
		"stations": []
	})
	
	# ======= HEAVY WEAPON =======
	
	# Heavy Weapon - Heavy Weapon Head
	category = "Heavy Weapon"
	subcategory = "Heavy Weapon Head"
	subcategory_materials = "3x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "War Hammer Head",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Mace Head",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Morning Start Head",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Battle Axe Head",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Noble Pernach Head",
		"difficulty": "4",
		"materials": "3x Metal 2x Decoration",
		"stations": []
	})
	
	# Heavy Weapon - Heavy Weapon Handle
	subcategory = "Heavy Weapon Handle"
	subcategory_materials = "1x Wood 1x Leather 1x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Wooden Handle",
		"difficulty": "2",
		"materials": "2x Wood",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Grip Handle",
		"difficulty": "2",
		"materials": "2x Wood 1x Leather",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Metal Handle",
		"difficulty": "3",
		"materials": "2x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Metal Handle",
		"difficulty": "4",
		"materials": "2x Metal 2x Decoration",
		"stations": []
	})
	
	# ======= DAGGER =======
	
	# Dagger - Dagger Blade
	category = "Dagger"
	subcategory = "Dagger Blade"
	subcategory_materials = "3x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Knife Blade",
		"difficulty": "1",
		"materials": "2x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Thieves Dagger Blade",
		"difficulty": "1",
		"materials": "3x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Точильний камінь", "Шліфувальний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Knights Dagger Blade",
		"difficulty": "2",
		"materials": "3x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Rich Dagger Blade",
		"difficulty": "3",
		"materials": "3x Metal 1x Decoration",
		"stations": []
	})
	
	# Dagger - Dagger Handle
	subcategory = "Dagger Handle"
	subcategory_materials = "1x Wood 1x Leather"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Dagger Handle",
		"difficulty": "1",
		"materials": "1x Wood",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Grip Dagger Handle",
		"difficulty": "2",
		"materials": "1x Wood 1x Leather",
		"stations": ["Верстак", "Тесларний верстак"]
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Decorated Dagger Handle",
		"difficulty": "3",
		"materials": "1x Wood 1x Leather 1x Decoration",
		"stations": []
	})
	
	# Dagger - Dagger Pommel
	subcategory = "Dagger Pommel"
	subcategory_materials = "1x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Dagger Pommel",
		"difficulty": "1",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Large Dagger Pommel",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": ["Верстак", "Горн", "Ковадло", "Відро", "Шліфувальний верстак"]
	})
	
	# Dagger - Dagger Guard
	subcategory = "Dagger Guard"
	subcategory_materials = "1x Metal"
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Simple Dagger Guard",
		"difficulty": "1",
		"materials": "1x Metal",
		"stations": []
	})
	
	weapon_components.append({
		"category": category,
		"subcategory": subcategory,
		"subcategory_materials": subcategory_materials,
		"name": "Extended Dagger Guard",
		"difficulty": "2",
		"materials": "1x Metal",
		"stations": []
	})
	
	print("Ініціалізовано компонентів зброї: " + str(weapon_components.size()))

# Функція для розбиття рядка CSV на колонки з урахуванням лапок
func parse_csv_line(line: String) -> Array:
	var result = []
	var in_quotes = false
	var current_value = ""
	
	for i in range(line.length()):
		var char = line[i]
		
		if char == '"':
			in_quotes = not in_quotes
		elif char == ',' and not in_quotes:
			result.append(current_value.strip_edges())
			current_value = ""
		else:
			current_value += char
	
	# Додаємо останнє значення
	result.append(current_value.strip_edges())
	
	return result

func generate_weapon_components():
	print("Генерація компонентів зброї...")
	
	# Використовуємо значення з WeaponComponent.WeaponComponentType для вказання типу зброї
	# та відповідних підтипів з OneHandedCutWeaponComponent, LongCutWeaponComponent і т.д.
	
	# Мапінг категорій та підкатегорій до відповідних типів і скриптів
	var scripts_map = {
		"One-Handed Cut Weapon": {
			"One-Handed Sword Blade": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_SWORD_BLADE},
			"Saber Blade": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.SABER_BLADE},
			"One-Handed Guard": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_GUARD},
			"One-Handed Pommel": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SHORT_BLADE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_POMMEL},
			"One-Handed Handle": {"script": "OneHandedCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": OneHandedCutWeaponComponent.OneHandedCutWeaponType.ONE_HANDED_HANDLE}
		},
		"Long Cut Weapon": {
			"Long Sword Blade": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_BLADE},
			"Lond Sword Guard": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_GUARD},
			"Long Sword Pommel": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.LONG_BLADE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_POMMEL},
			"Long Sword Handle": {"script": "LongCutWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": LongCutWeaponComponent.LongCutWeaponType.LONG_SWORD_HANDLE}
		},
		"Pole Weapon": {
			"Pole Head": {"script": "PoleWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.SPEAR_HEAD, "type": PoleWeaponComponent.PoleWeaponType.POLE_HEAD},
			"Pole Handle": {"script": "PoleWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": PoleWeaponComponent.PoleWeaponType.POLE_HANDLE}
		},
		"Heavy Weapon": {
			"Heavy Weapon Head": {"script": "HeavyWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.MACE_HEAD, "type": HeavyWeaponComponent.HeavyWeaponType.HEAVY_WEAPON_HEAD},
			"Heavy Weapon Handle": {"script": "HeavyWeaponComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": HeavyWeaponComponent.HeavyWeaponType.HEAVY_WEAPON_HANDLE}
		},
		"Dagger": {
			"Dagger Blade": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_BLADE},
			"Dagger Handle": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.WEAPON_HANDLE, "type": DaggerComponent.DaggerType.DAGGER_HANDLE},
			"Dagger Pommel": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_POMMEL},
			"Dagger Guard": {"script": "DaggerComponent", "weapon_type": WeaponComponent.WeaponComponentType.DAGGER_BLADE, "type": DaggerComponent.DaggerType.DAGGER_GUARD}
		}
	}
	
	# Створюємо компоненти
	for item in weapon_components:
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
		create_weapon_component(item, script_name, component_type)

# Створення компонента зброї
func create_weapon_component(item_data, script_class_name: String, component_type):
	# Завантажуємо скрипт компонента
	var script_path = "res://data/items/components (simple items)/weapon components/scripts/" + script_class_name.to_snake_case() + ".gd"
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
			"OneHandedCutWeaponComponent":
				component.one_handed_cut_weapon_type = script_info.type
			"LongCutWeaponComponent":
				component.long_cut_weapon_type = script_info.type
			"PoleWeaponComponent":
				component.pole_weapon_type = script_info.type
			"HeavyWeaponComponent":
				component.heavy_weapon_type = script_info.type
			"DaggerComponent":
				component.dagger_type = script_info.type
		
		# Встановлюємо загальний тип зброї
		component.weapon_type = script_info.weapon_type
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
	var folder = WEAPON_COMPONENT_FOLDERS.get(item_data.category, "")
	if folder.is_empty():
		push_warning("Не знайдено папку для категорії: " + item_data.category)
		return
	
	# Створюємо ім'я файлу (замінюємо пробіли на підкреслення)
	var file_name = item_data.name.to_snake_case() + ".tres"
	
	# Зберігаємо ресурс
	var save_path = WEAPON_COMPONENT_BASE_PATH + folder + "/" + file_name
	var result = ResourceSaver.save(component, save_path)
	
	if result == OK:
		print("Компонент створено: " + save_path)
	else:
		push_error("Помилка при збереженні компонента: " + str(result))

# Функція для генерації унікальних описів
func generate_description(item_name: String, script_class_name: String, component_type) -> String:
	# Словники описів для різних типів компонентів
	var blade_descriptions = [
		"Slices through armor and ego with equal ease.",
		"Not quite Excalibur, but it'll do the job.",
		"Guaranteed to cut at least 50% of what you swing at!",
		"Keeps its edge longer than most marriages.",
		"The preferred choice of heroes with more courage than sense.",
		"So sharp it can cut through awkward conversations.",
		"Comes with a free tetanus booster.",
		"May occasionally whisper dark thoughts in the moonlight.",
		"Elegant, deadly, and guaranteed not to turn into a snake... probably.",
		"The pointy end goes toward the enemy. We can't stress this enough."
	]
	
	var guard_descriptions = [
		"Keeps your hand attached to your arm. Usually.",
		"Deflects blows and criticism with similar efficiency.",
		"Fancier than necessary, but who's counting?",
		"Protected the hands of nobles and peasants alike. No discrimination here!",
		"Not just decorative, but mostly decorative.",
		"Functional protection with a touch of medieval swagger.",
		"Prevents unplanned finger removal during combat.",
		"More practical than fashionable, like most armor."
	]
	
	var pommel_descriptions = [
		"Perfect for ending opponents rightly.",
		"Can double as an emergency hammer in household disputes.",
		"Adds balance, weight, and a certain je ne sais quoi.",
		"Useful for cracking nuts and skulls alike.",
		"The unsung hero of sword components.",
		"A satisfying knob to finish off your weapon.",
		"Heavy enough to use as a doorstop when not slaying dragons."
	]
	
	var handle_descriptions = [
		"Ergonomically designed for maximum stabbing comfort.",
		"Provides grip even when covered in blood, sweat, or tears.",
		"Hand-tested by actual humans with hands.",
		"Feels better in your palm than that time you held hands with the village blacksmith's daughter.",
		"Won't give you splinters... we think.",
		"Wrapped with only the finest leather from cows who died of natural causes.",
		"The part you hold, in case that wasn't obvious."
	]
	
	var pole_descriptions = [
		"Reach out and touch someone... with extreme prejudice.",
		"Keep your enemies at bay and your allies confused.",
		"Long enough to compensate for any battlefield insecurities.",
		"Perfect for poking things you'd rather not get close to.",
		"Makes a decent fishing pole in peacetime.",
		"Doubles as an excellent way to retrieve items from high shelves."
	]
	
	var heavy_descriptions = [
		"When subtlety isn't in your vocabulary.",
		"Makes diplomacy obsolete and skulls concave.",
		"Recommended by 9 out of 10 berserkers.",
		"Because sometimes you just need to smash something.",
		"Warning: May cause unintended structural renovations.",
		"Solves arguments with satisfying finality."
	]
	
	var dagger_descriptions = [
		"For when your sword is just too obvious.",
		"Small but ambitious.",
		"The thinking assassin's weapon of choice.",
		"Perfect for butter, bread, and backstabbing.",
		"Concealable, practical, and morally ambiguous.",
		"For the stabby moments that arise in everyday medieval life."
	]
	
	# Вибір списку описів на основі типу компонента
	var descriptions = []
	var component_name_lower = item_name.to_lower()
	
	if "blade" in component_name_lower:
		descriptions = blade_descriptions
	elif "guard" in component_name_lower:
		descriptions = guard_descriptions
	elif "pommel" in component_name_lower:
		descriptions = pommel_descriptions
	elif "handle" in component_name_lower:
		descriptions = handle_descriptions
	elif "pole" in component_name_lower or "spear" in component_name_lower:
		descriptions = pole_descriptions
	elif "mace" in component_name_lower or "hammer" in component_name_lower or "axe" in component_name_lower:
		descriptions = heavy_descriptions
	elif "dagger" in component_name_lower or "knife" in component_name_lower:
		descriptions = dagger_descriptions
	else:
		# Якщо не знайдено відповідність, використовуємо загальні описи
		return "A finely crafted component that would make any blacksmith proud."
	
	# Додаємо специфічні описи для деяких особливих типів предметів
	if "decorated" in component_name_lower or "noble" in component_name_lower:
		return "Unnecessarily ornate. Nobles pay extra for the privilege of dying prettily."
	
	if "simple" in component_name_lower:
		return "No frills, no nonsense, just honest craftsmanship. Boring but reliable."
	
	if "estoc" in component_name_lower:
		return "Pointy enough to find the gaps in armor and in arguments."
	
	if "falchion" in component_name_lower:
		return "Curved, single-edged, and doesn't care about your feelings."
	
	if "zweihänder" in component_name_lower:
		return "Two hands, one sword, infinite regrets for your enemies."
	
	if "claymore" in component_name_lower:
		return "Scottish ingenuity: a sword large enough to compensate for any shortcomings."
	
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
	
	for i in range(0, parts.size(), 2):
		if i + 1 < parts.size():
			var quantity_str = parts[i]
			var material_type = parts[i + 1]
			
			# Перевіряємо, чи є це форматом "3x"
			if quantity_str.ends_with("x"):
				quantity_str = quantity_str.left(quantity_str.length() - 1)
				material_requirements.append({
					"quantity": int(quantity_str),
					"type": material_type
				})
	
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
			"Metal":
				material_slot.weight = 3
			"Wood":
				material_slot.weight = 2
			"Leather", "Fabric":
				material_slot.weight = 1
			"Decoration":
				material_slot.weight = 2
		
		# Встановлюємо обов'язковість
		material_slot.is_required = true
		
		# Виправлена версія - встановлюємо max_stack рівним точній кількості
		material_slot.max_stack = quantity
		
		# Додаємо слот до компонента
		component.component_slots.append(material_slot)
