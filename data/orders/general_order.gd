extends Order
class_name GeneralOrder

# Замовлення для певної категорії виробу
@export var item_category: ItemData.Category
@export var creation_difficulty: ItemData.CreationDifficulty

func _init() -> void:
	order_type = OrderType.GENERAL
	super()

# Перевизначаємо метод validate_item для перевірки відповідності категорії та складності
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Перевірка відповідності категорії
	if item.get_category() != item_category:
		return false
		
	# Перевірка рівня складності
	if item.creation_difficulty < creation_difficulty:
		return false
		
	return true

# Генерація опису замовлення для UI
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	desc += "\nТип: "
	match item_category:
		ItemData.Category.TOOLS:
			desc += "Інструмент"
		ItemData.Category.WEAPONS:
			desc += "Зброя"
		ItemData.Category.ARMOR:
			desc += "Броня"
	
	desc += "\nСкладність: "
	match creation_difficulty:
		ItemData.CreationDifficulty.HOUSEHOLD:
			desc += "Господарський"
		ItemData.CreationDifficulty.BASIC:
			desc += "Базовий"
		ItemData.CreationDifficulty.MILITARY:
			desc += "Військовий"
		ItemData.CreationDifficulty.ELITE:
			desc += "Елітний"
	
	return desc

# Генерація детального опису замовлення
func get_detailed_description() -> String:
	var desc = "Замовлення на виготовлення предмета категорії "
	
	match item_category:
		ItemData.Category.TOOLS:
			desc += "Інструменти"
		ItemData.Category.WEAPONS:
			desc += "Зброя"
		ItemData.Category.ARMOR:
			desc += "Броня"
	
	desc += " зі складністю "
	
	match creation_difficulty:
		ItemData.CreationDifficulty.HOUSEHOLD:
			desc += "Господарський"
		ItemData.CreationDifficulty.BASIC:
			desc += "Базовий"
		ItemData.CreationDifficulty.MILITARY:
			desc += "Військовий"
		ItemData.CreationDifficulty.ELITE:
			desc += "Елітний"
	
	desc += ".\nМінімальна якість: " + str(required_quality_min)
	desc += ".\nНагорода: " + str(base_price) + " монет."
	
	if description:
		desc += "\n\n" + description
	
	return desc

# Оцінка складності замовлення від 1 до 5
func get_difficulty_rating() -> int:
	var base_difficulty = int(creation_difficulty)
	
	# Підвищуємо складність, якщо вимоги до якості високі
	if required_quality_min > 70:
		base_difficulty += 1
	elif required_quality_min > 50:
		base_difficulty += 0.5
		
	return int(min(base_difficulty, 5))
