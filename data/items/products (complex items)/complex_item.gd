extends ItemData
class_name ComplexItem 

signal component_added(component: SimpleItem, slot_index: int)
signal component_removed(component: SimpleItem, slot_index: int)
signal assembly_quality_changed(new_quality: float)

var assembly_quality: float = 0.0  # Результат міні-гри складання (0-1)

# Отримати коефіцієнт складності на основі рівня
func get_complexity_coefficient() -> float:
	match creation_difficulty:
		1:  # Побутовий виріб
			return 0.9
		2:  # Військовий виріб
			return 1.1
		3:  # Елітний виріб
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
