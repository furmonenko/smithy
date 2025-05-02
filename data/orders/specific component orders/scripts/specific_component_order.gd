extends Order
class_name SpecificComponentOrder

@export var required_component: ComponentRecipe

# Перевизначаємо метод validate_item для перевірки наявності необхідного компонента
func validate_item(item: Recipe) -> bool:
	if not super.validate_item(item):
		return false
	
	# Перевірка наявності необхідного компонента (для складних виробів)
	if item is ProductRecipe:
		return item.has_component(required_component)
	
	# Для простих компонентів перевіряємо відповідність
	if item is ComponentRecipe:
		return item.name == required_component.name
		
	return false

# Генерація опису замовлення для UI
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	if required_component:
		desc += "\nПотрібний компонент: " + required_component.name
	
	return desc

# Генерація детального опису замовлення
func get_detailed_description() -> String:
	var desc = "Замовлення на виготовлення виробу з компонентом \"" + required_component.name + "\"."
	desc += "\nМінімальна якість: " + str(required_quality_min)
	desc += ".\nНагорода: " + str(base_price) + " монет."
	
	if description:
		desc += "\n\n" + description
	
	return desc

# Оцінка складності замовлення від 1 до 5
func get_difficulty_rating() -> int:
	# Базова складність залежить від типу компонента
	var base_difficulty = 2  # За замовчуванням середня складність
	
	if required_component:
		base_difficulty = int(required_component.creation_difficulty)
	
	# Підвищуємо складність, якщо вимоги до якості високі
	if required_quality_min > 70:
		base_difficulty += 1
	elif required_quality_min > 50:
		base_difficulty += 0.5
		
	return int(min(base_difficulty, 5))
