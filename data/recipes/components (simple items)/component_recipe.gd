extends Recipe
class_name ComponentRecipe

var subcategory_materials: Dictionary

# Ініціалізує матеріали для підкатегорії
func initialize_subcategory_materials() -> void:
	# Буде перевизначено в нащадках
	subcategory_materials = {}

# Розраховує ціну на основі бажаної якості
func calculate_price_for_quality(desired_quality: int) -> int:
	var total_price = 0
	
# Inside calculate_price_for_quality
	for material_type in subcategory_materials.keys():
		var quantity = subcategory_materials[material_type]
		print("Looking for material of type: ", material_type, " with quality: ", desired_quality)
		var material = CraftMaterialsManager.get_cheapest_material_by_type_and_quality(material_type, desired_quality)
	
		if material:
			print("Found material: ", material.name, " with cost: ", material.cost)
			total_price += material.cost * quantity
		else:
			print("No material found for type: ", material_type, " with quality: ", desired_quality)
	
	return total_price

# Отримує коефіцієнт складності на основі типу виробу
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

# Розраховує якість простого виробу
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

# Розраховує престиж простого виробу
func calculate_prestige() -> float:
	var quality = calculate_quality()
	var base_prestige = get_base_prestige_by_quality(quality)
	
	# Престиж Елемента = (Фактична Якість / 100) × Базовий Престиж Категорії
	return (quality / 100.0) * base_prestige

func get_base_prestige_by_quality(quality: float) -> int:
	var config = Global.get_config()
	
	if quality >= 0 and quality < 50:
		return config.prestige_low_quality  # Звичайний
	elif quality >= 50 and quality < 80:
		return config.prestige_medium_quality  # Відмінний
	elif quality >= 80 and quality <= 100:
		return config.prestige_high_quality  # Видатний
	return config.prestige_low_quality / 2  # За замовчуванням

# Отримує результат міні-ігор
func get_mini_game_result() -> float:
	# Тут має бути логіка отримання результату міні-ігор
	# Поки що повертаємо значення за замовчуванням
	return 80.0  # Від 0 до 100

# Отримує ефективність станків
func get_station_efficiency() -> float:
	# Тут має бути логіка отримання ефективності станків
	# Поки що повертаємо значення за замовчуванням
	return 0.9  # від 0 до 1 (або трохи більше)

# Отримує навичку гравця
func get_player_skill() -> float:
	# Тут має бути логіка отримання навички гравця
	# Поки що повертаємо значення за замовчуванням
	return 0.75  # від 0 до 1 (або трохи більше)

# Додаткові методи для системи замовлень

# Перевіряє чи відповідає компонент необхідним матеріалам
func matches_material_requirements(required_material_type) -> bool:
	# Перевіряємо чи всі необхідні матеріали присутні
	if required_material_type == null:
		return true  # Якщо немає особливих вимог
		
	# Перевіряємо чи в слотах є матеріали відповідного типу
	for slot in component_slots:
		if slot is MaterialSlot and slot.is_filled():
			if slot.assigned_material.material_type == required_material_type:
				return true
	
	return false

# Перевіряє чи відповідає компонент бажаній якості
func meets_quality_requirement(required_quality: int) -> bool:
	return get_quality() >= required_quality

# Переоцінка вартості виробу на основі якості
func recalculate_price() -> void:
	base_price = calculate_price_for_quality(int(get_quality()))

# Отримує тип компонента (для ComponentRecipe це більш специфічний тип)
func get_component_type():
	# Цей метод має бути перевизначений у підкласах
	return null

# Перевіряє чи компонент є точним (specific) типом для замовлення
func is_specific_type(required_type) -> bool:
	var my_type = get_component_type()
	return my_type != null and my_type == required_type

# Метод для перевірки відповідності компонента замовленню
func matches_specific_order_requirements(order) -> bool:
	# Перевіряємо якість
	if not meets_quality_requirement(order.required_quality_min):
		return false
		
	# Специфічні перевірки для різних типів замовлень можуть бути додані тут
	# Наприклад, перевірка типу компонента, матеріалу тощо
	
	return true

# Метод для оцінки вартості матеріалів
func calculate_material_cost_estimate(desired_quality: int) -> int:
	# Використовуємо інформацію про матеріали підкатегорії
	return calculate_price_for_quality(desired_quality)

# Отримує категорію предмета (перевизначення методу Recipe)
func get_category() -> Recipe.Category:
	# Метод має бути перевизначений у підкласах
	return Recipe.Category.TOOLS
