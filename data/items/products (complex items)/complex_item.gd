extends ItemData
class_name ComplexItem 

signal component_added(component: SimpleItem, slot_index: int)
signal component_removed(component: SimpleItem, slot_index: int)
signal assembly_quality_changed(new_quality: float)

var assembly_quality: float = 0.0  # Результат міні-гри складання (0-1)

# Отримує коефіцієнт складності на основі рівня
func get_complexity_coefficient() -> float:
	match creation_difficulty:
		CreationDifficulty.HOUSEHOLD:  # 1
			return 0.9
		CreationDifficulty.BASIC:      # 2
			return 1.0
		CreationDifficulty.MILITARY:   # 3
			return 1.1
		CreationDifficulty.ELITE:      # 4
			return 1.2
		_:
			return 1.0

# Загальний метод розрахунку якості для всіх складних виробів
func calculate_quality() -> float:
	if not are_all_required_components_assigned():
		return 0.0
		
	var avg_quality = calculate_average_weighted_quality()
	
	return avg_quality * assembly_quality * get_complexity_coefficient()

# Метод для розрахунку середньозваженої якості компонентів
func calculate_average_weighted_quality() -> float:
	var total_quality_weight = 0.0
	var total_weight = 0.0
	
	for i in range(component_slots.size()):
		var slot = component_slots[i]
		
		if slot.is_filled():
			var slot_quality = slot.quality
			var weight = slot.weight
			var quantity = slot.quantity
			
			total_quality_weight += slot_quality * weight * quantity
			total_weight += weight * quantity
	
	if total_weight == 0:
		return 0.0
	
	return total_quality_weight / total_weight

# Метод для перевірки чи всі необхідні компоненти призначені
func are_all_required_components_assigned() -> bool:
	for slot in component_slots:
		if slot.is_required and not slot.is_filled():
			return false
	return true

# Метод для розрахунку престижу виробу
func calculate_prestige() -> float:
	# Перевіряємо чи всі необхідні компоненти присутні
	if not are_all_required_components_assigned():
		return 0.0
	
	# Розрахунок середньозваженого престижу компонентів
	var weighted_prestige_sum = 0.0
	var total_weight = 0.0
	
	for i in range(component_slots.size()):
		var slot = component_slots[i]
		
		if slot.is_filled():
			var prestige_sum = 0.0
			
			for component in slot.assigned_components:
				prestige_sum += component.calculate_prestige()
			
			var avg_prestige = prestige_sum / slot.assigned_components.size()
			weighted_prestige_sum += avg_prestige * slot.weight * slot.quantity
			total_weight += slot.weight * slot.quantity
	
	if total_weight == 0:
		return 0.0
	
	var weighted_avg_prestige = weighted_prestige_sum / total_weight
	
	# Отримуємо коефіцієнт складності збірки
	var complexity_coefficient = get_complexity_coefficient()
	
	# Престиж Виробу = Середньозважений Престиж Компонентів × Коефіцієнт Складності Збірки × (1 + Якість Збірки)
	return weighted_avg_prestige * complexity_coefficient * (1.0 + assembly_quality)

# Метод для встановлення якості збірки
func set_assembly_quality(quality: float) -> void:
	assembly_quality = clamp(quality, 0.0, 1.0)
	emit_signal("assembly_quality_changed", assembly_quality)

# Метод для запуску процесу збірки (різний для різних типів)
func start_assembly_minigame() -> void:
	# Перевизначається в нащадках для запуску специфічних міні-ігор
	pass

# Додати компонент у слот
func assign_component_to_slot(slot_index: int, component: SimpleItem) -> bool:
	if slot_index < 0 or slot_index >= component_slots.size():
		return false
	
	var slot = component_slots[slot_index]
	
	if slot.assign_component(component):
		emit_signal("component_added", component, slot_index)
		return true
	
	return false

# Видалити компонент зі слоту
func remove_component_from_slot(slot_index: int, component_index: int) -> SimpleItem:
	if slot_index < 0 or slot_index >= component_slots.size():
		return null
	
	var slot = component_slots[slot_index]
	var component = slot.remove_component(component_index)
	
	if component != null:
		emit_signal("component_removed", component, slot_index)
	
	return component

# Очистити всі слоти
func clear_all_slots() -> void:
	for slot in component_slots:
		slot.clear()

# Додаткові методи для системи замовлень

# Перевизначення методу has_component для перевірки наявності компонента
func has_component(component: SimpleItem) -> bool:
	for slot in component_slots:
		if slot.contains_component(component):
			return true
	return false

# Перевірка чи містить предмет компонент певного типу
func has_component_type(component_type) -> bool:
	for slot in component_slots:
		if slot.contains_component_type(component_type):
			return true
	return false

# Отримати список всіх компонентів
func get_all_components() -> Array:
	var components = []
	for slot in component_slots:
		components.append_array(slot.get_all_components())
	return components

# Розрахунок вартості матеріалів для складного виробу
func calculate_material_cost() -> int:
	var total_cost = 0
	
	# Додаємо вартість всіх компонентів
	for slot in component_slots:
		if slot.is_filled():
			for component in slot.get_all_components():
				total_cost += component.get_material_cost()
	
	return total_cost

# Метод для оцінки вартості на основі бажаної якості
func calculate_estimated_price(desired_quality: int) -> int:
	# За замовчуванням просто множимо базову ціну на коефіцієнт якості
	return base_price * (desired_quality / 50.0)

# Отримує тип складного виробу
func get_complex_item_type():
	# Метод має бути перевизначений у підкласах
	return null

# Перевіряє чи виріб відповідає конкретному типу
func is_specific_complex_type(required_type) -> bool:
	var my_type = get_complex_item_type()
	return my_type != null and my_type == required_type

# Перевірка відповідності вимогам замовлення для складного виробу
func matches_order_requirements(order: Order) -> bool:
	# Базова перевірка якості
	if get_quality() < order.required_quality_min:
		return false
		
	# Перевірка для різних типів замовлень
	if order is GeneralOrder:
		# Перевірка категорії та складності
		if not matches_category(order.item_category):
			return false
		if not matches_difficulty(order.creation_difficulty):
			return false
	elif order is SpecificItemOrder:
		# Перевірка конкретного виробу
		if name != order.required_item.name:
			return false
	elif order is SpecificComponentOrder:
		# Перевірка наявності конкретного компонента
		if not has_component(order.required_component):
			return false
	
	return true

# Отримує рівень складності складання
func get_complexity_level() -> int:
	# Для складних виробів рівень складності визначається за типом
	match get_complex_item_type():
		"Побутовий виріб":
			return 1
		"Військовий виріб": 
			return 2
		"Елітний виріб":
			return 3
		_:
			return int(creation_difficulty)

# Оновлення базової ціни на основі якості та коефіцієнтів
func update_base_price() -> void:
	var material_cost = calculate_material_cost()
	var complexity_mod = get_complexity_coefficient()
	var quality_mod = get_quality() / 50.0  # Якість впливає на ціну
	
	base_price = int(material_cost * complexity_mod * quality_mod)

# Отримання категорії предмета (перевизначення методу ItemData)
func get_category() -> ItemData.Category:
	# Метод має бути перевизначений у підкласах
	return ItemData.Category.WEAPONS  # За замовчуванням зброя
