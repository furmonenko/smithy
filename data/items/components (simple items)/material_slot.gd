extends Slot
class_name MaterialSlot

signal material_added(material: CraftMaterial)  # Специфічний сигнал для матеріалів
signal material_removed(material: CraftMaterial)  # Специфічний сигнал для матеріалів

@export var material_type: Enums.MaterialType  # Тип матеріалу для цього слота

var assigned_materials: Array[CraftMaterial] = []  # Масив призначених матеріалів

# Отримати поточну кількість матеріалів
func get_current_quantity() -> int:
	return assigned_materials.size()

# Очистити слот
func clear() -> void:
	assigned_materials.clear()
	super.clear()

# Додати матеріал у слот
func assign_material(material: CraftMaterial) -> bool:
	# Перевірка типу матеріалу
	if material.material_type == material_type:
		# Перевірка чи слот не переповнений
		if can_add_more():
			assigned_materials.append(material)
			
			# Перерахувати якість
			update_quality()
			
			# Відправити загальний сигнал про додавання вмісту
			emit_signal("content_added", material)
			
			# Відправити специфічний сигнал для матеріалів
			emit_signal("material_added", material)
			
			# Перевірити чи слот заповнений і відправити сигнал якщо так
			if is_filled() and get_current_quantity() == quantity:  # Щойно досягли рівно потрібної кількості
				emit_signal("slot_filled")
				
			return true
	return false

# Видалити матеріал зі слота
func remove_material(index: int) -> CraftMaterial:
	if index >= 0 and index < assigned_materials.size():
		var material = assigned_materials[index]
		assigned_materials.remove_at(index)
		
		# Перерахувати якість
		update_quality()
		
		# Відправити загальний сигнал про видалення вмісту
		emit_signal("content_removed", material)
		
		# Відправити специфічний сигнал для матеріалів
		emit_signal("material_removed", material)
		
		return material
	return null

# Розрахувати середню якість матеріалів у слоті
func calculate_average_quality() -> float:
	if assigned_materials.is_empty():
		return 0.0
	
	var total_quality = 0.0
	for material in assigned_materials:
		total_quality += material.quality
	
	return total_quality / assigned_materials.size()

# Отримати базовий престиж на основі якості слота
func get_base_prestige_by_quality(quality_value: int) -> int:
	# Логіка з таблиці категорій якості
	if quality_value >= 0 and quality_value <= 49:
		return 30
	elif quality_value >= 50 and quality_value <= 79:
		return 50
	elif quality_value >= 80 and quality_value <= 100:
		return 70
	return 0

# Отримати базовий престиж для всього слота
func get_base_prestige() -> int:
	var avg_quality = int(calculate_average_quality())
	return get_base_prestige_by_quality(avg_quality)

# Отримати всі матеріали
func get_all_materials() -> Array[CraftMaterial]:
	return assigned_materials

# Перевірити чи матеріал підходить для цього слота
func is_material_valid(material: CraftMaterial) -> bool:
	return material.material_type == material_type

# Знайти матеріал найвищої якості у слоті
func get_highest_quality_material() -> CraftMaterial:
	if assigned_materials.is_empty():
		return null
		
	var highest_quality = -1
	var best_material = null
	
	for material in assigned_materials:
		if material.quality > highest_quality:
			highest_quality = material.quality
			best_material = material
			
	return best_material

# Знайти матеріал найнижчої якості у слоті
func get_lowest_quality_material() -> CraftMaterial:
	if assigned_materials.is_empty():
		return null
		
	var lowest_quality = 101  # Більше максимальної якості
	var worst_material = null
	
	for material in assigned_materials:
		if material.quality < lowest_quality:
			lowest_quality = material.quality
			worst_material = material
			
	return worst_material

# Отримати загальну вартість всіх матеріалів у слоті
func get_total_value() -> int:
	var total = 0
	for material in assigned_materials:
		total += material.cost
	return total
