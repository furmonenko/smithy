extends ItemData
class_name SimpleItem

var subcategory_materials: Dictionary

# В базовому класі SimpleItem
func initialize_subcategory_materials() -> void:
	# Буде перевизначено в нащадках
	subcategory_materials = {}

# Нова функція для визначення ціни на основі якості
func calculate_price_for_quality(desired_quality: int) -> int:
	var total_price = 0
	
	for material_type in subcategory_materials.keys():
		var quantity = subcategory_materials[material_type]
		var material = CraftMaterialsManager.get_cheapest_material_by_type_and_quality(material_type, desired_quality)
		
		if material:
			total_price += material.cost * quantity
	
	return total_price

# Отримати коефіцієнт складності на основі типу виробу
func get_complexity_coefficient() -> float:
	match creation_difficulty:
		CreationDifficulty.HOUSEHOLD:
			return 0.9
		CreationDifficulty.BASIC:
			return 1.0
		CreationDifficulty.MILITARY:
			return 1.1
		CreationDifficulty.ELITE:
			return 1.2
		_:
			return 1.0

func calculate_quality() -> float:
	# 1. Розрахунок зваженої середньої якості матеріалів
	var weighted_quality_sum = 0.0
	var total_weight = 0
	
	for slot in component_slots:
		if slot.is_filled():
			weighted_quality_sum += slot.assigned_material.quality * slot.weight * slot.quantity
			total_weight += slot.weight * slot.quantity
	
	if total_weight == 0:
		return 0.0
	
	var weighted_avg_quality = weighted_quality_sum / total_weight
	
	# 2. Розрахунок ефективності виконання
	var mini_game_result = get_mini_game_result()  # Середній результат міні-ігор (0-100)
	var station_efficiency = get_station_efficiency()  # Середня ефективність станків (0-1 або трохи більше)
	var player_skill = get_player_skill()  # Навичка гравця (0-1 або трохи більше)
	
	var execution_efficiency = (mini_game_result * station_efficiency * player_skill) / 100.0
	
	# 3. Розрахунок фактичної якості
	var final_quality = weighted_avg_quality * execution_efficiency * get_complexity_coefficient()
	
	return final_quality

# Для класу SimpleItem (простий виріб/компонент)
func calculate_prestige() -> float:
	var quality = calculate_quality()
	var base_prestige = get_base_prestige_by_quality(quality)
	
	# Престиж Елемента = (Фактична Якість / 100) × Базовий Престиж Категорії
	return (quality / 100.0) * base_prestige

# Визначення базового престижу на основі якості
func get_base_prestige_by_quality(quality: float) -> int:
	if quality >= 0 and quality < 50:
		return PRESTIGE_LOW_QUALITY  # Звичайний
	elif quality >= 50 and quality < 80:
		return PRESTIGE_MEDIUM_QUALITY  # Відмінний
	elif quality >= 80 and quality <= 100:
		return PRESTIGE_HIGH_QUALITY  # Видатний
	return 20  # За замовчуванням

# Отримати результат міні-ігор (може бути реалізовано в GameManager)
func get_mini_game_result() -> float:
	# Тут має бути логіка отримання результату міні-ігор
	# Поки що повертаємо значення за замовчуванням
	return 80.0  # Від 0 до 100

# Отримати ефективність станків
func get_station_efficiency() -> float:
	# Тут має бути логіка отримання ефективності станків
	# Поки що повертаємо значення за замовчуванням
	return 0.9  # від 0 до 1 (або трохи більше)

# Отримати навичку гравця
func get_player_skill() -> float:
	# Тут має бути логіка отримання навички гравця
	# Поки що повертаємо значення за замовчуванням
	return 0.75  # від 0 до 1 (або трохи більше)
