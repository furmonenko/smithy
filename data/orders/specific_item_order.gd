extends Order
class_name SpecificItemOrder

@export var required_item: ComplexItem

func _init() -> void:
	order_type = OrderType.SPECIFIC_ITEM
	super()

# Перевизначаємо метод validate_item для перевірки точної відповідності
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Перевірка точної відповідності
	return item.name == required_item.name

# Генерація опису замовлення для UI
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	if required_item:
		desc += "\nПотрібний виріб: " + required_item.name
		desc += "\nТип: " + get_item_category_name(required_item.get_category())
	
	return desc

# Отримання назви категорії
func get_item_category_name(category: ItemData.Category) -> String:
	match category:
		ItemData.Category.TOOLS:
			return "Інструмент"
		ItemData.Category.WEAPONS:
			return "Зброя"
		ItemData.Category.ARMOR:
			return "Броня"
		_:
			return "Невідомо"

# Генерація детального опису замовлення
func get_detailed_description() -> String:
	var desc = "Замовлення на виготовлення конкретного виробу \"" + required_item.name + "\"."
	desc += "\nМінімальна якість: " + str(required_quality_min)
	desc += ".\nНагорода: " + str(base_price) + " монет."
	
	if description:
		desc += "\n\n" + description
	
	return desc

# Оцінка складності замовлення від 1 до 5
func get_difficulty_rating() -> int:
	# Базова складність залежить від складності предмета
	var base_difficulty = 3  # За замовчуванням підвищена складність
	
	if required_item:
		base_difficulty = int(required_item.creation_difficulty)
	
	# Підвищуємо складність, якщо вимоги до якості високі
	if required_quality_min > 70:
		base_difficulty += 1
	elif required_quality_min > 50:
		base_difficulty += 0.5
		
	return int(min(base_difficulty, 5))
