extends Node

signal prestige_changed(old_value, new_value)
signal prestige_level_changed(old_level, new_level)
signal prestige_achievement_unlocked(achievement_name, prestige_bonus)

# Базові показники престижу
var prestige_points: int = 0
var prestige_level: int = 0

# Історія змін престижу для аналітики
var prestige_history: Array = []

# Рівні престижу кузні з усіма параметрами з таблиці
var prestige_levels = [
	{
		"min": 0, 
		"max": 50, 
		"name": "Невідома кузня", 
		"description": "Початківець, відомий лише в околицях",
		"level": 0, 
		"multiplier": 0,
		"divisor": 5,
		"price_premium": 0.0,    # +0%
		"supplier_discount": 0.0  # 0%
	},
	{
		"min": 51, 
		"max": 150, 
		"name": "Місцева кузня", 
		"description": "Має постійних клієнтів серед містян",
		"level": 0, 
		"multiplier": 0,
		"divisor": 5,
		"price_premium": 0.015,  # +1-2%
		"supplier_discount": 0.0  # 0%
	},
	{
		"min": 151, 
		"max": 300, 
		"name": "Поважна кузня", 
		"description": "Довіра купців і міської варти",
		"level": 0, 
		"multiplier": 0,
		"divisor": 5,
		"price_premium": 0.03,   # +2-4%
		"supplier_discount": 0.01 # 1%
	},
	{
		"min": 301, 
		"max": 500, 
		"name": "Відома кузня", 
		"description": "Визнана серед лицарства та дрібної шляхти",
		"level": 0.2, 
		"multiplier": 0.2,
		"divisor": 10,
		"price_premium": 0.06,   # +4-8%
		"supplier_discount": 0.03 # 3%
	},
	{
		"min": 501, 
		"max": 700, 
		"name": "Майстерна кузня", 
		"description": "Відома у всьому воєводстві",
		"level": 0.5, 
		"multiplier": 0.5,
		"divisor": 10,
		"price_premium": 0.09,   # +8-10%
		"supplier_discount": 0.05 # 5%
	},
	{
		"min": 701, 
		"max": 900, 
		"name": "Еліта ремісництва", 
		"description": "Слава досягає сусідніх держав",
		"level": 1.0, 
		"multiplier": 1.0,
		"divisor": 20,
		"price_premium": 0.11,   # +10-12%
		"supplier_discount": 0.07 # 7%
	},
	{
		"min": 901, 
		"max": 1000, 
		"name": "Легендарна кузня", 
		"description": "Вироби стають легендами",
		"level": 1.5, 
		"multiplier": 1.5,
		"divisor": 20,
		"price_premium": 0.135,  # +12-15%
		"supplier_discount": 0.1  # 10%
	}
]

# Пороги для досягнень престижу
var prestige_achievements = {
	"first_weapon": {"name": "Перша зброя", "threshold": 50, "bonus": 10, "unlocked": false},
	"noble_order": {"name": "Замовлення від знаті", "threshold": 100, "bonus": 20, "unlocked": false},
	"masterpiece": {"name": "Шедевр", "threshold": 300, "bonus": 50, "unlocked": false},
	"royal_weapon": {"name": "Королівська зброя", "threshold": 500, "bonus": 100, "unlocked": false}
}

# Виключення для штрафів невідповідності
var exception_types = {
	"charity": true,       # Благодійність (безкоштовні вироби для бідних)
	"learning": 0.5,       # Навчальні вироби (штраф 50%)
	"noble_order": false   # Замовлення від знаті (повний штраф)
}

# Зона толерантності
const TOLERANCE_THRESHOLD = 3

# Ініціалізація
func _init() -> void:
	prestige_history.append({"day": 0, "value": prestige_points, "source": "Початок кар'єри"})


# PRIVATE FUNCTIONS
# Оновлення рівня престижу
func update_prestige_level() -> void:
	var old_level = prestige_level
	var current_level_info = get_current_level_info()
	
	prestige_level = current_level_info.level
	
	if old_level != prestige_level:
		emit_signal("prestige_level_changed", old_level, prestige_level)

# Перевірка досягнень
func check_achievements() -> void:
	for achievement_id in prestige_achievements:
		var achievement = prestige_achievements[achievement_id]
		
		if not achievement.unlocked and prestige_points >= achievement.threshold:
			achievement.unlocked = true
			
			# Бонус за досягнення
			var bonus = achievement.bonus
			prestige_points += bonus
			
			emit_signal("prestige_achievement_unlocked", achievement.name, bonus)
			
			# Додаємо запис в історію
			prestige_history.append({
				"day": GameTime.current_day,
				"value": prestige_points,
				"change": bonus,
				"source": "Досягнення: " + achievement.name
			})

# Розрахунок невідповідності престижу
func calculate_discrepancy(item_prestige: int) -> float:
	# Невідповідність = (Престиж_Кузні / 100) - Престиж_Виробу
	var normalized_forge_prestige = prestige_points / 100.0
	var discrepancy = normalized_forge_prestige - item_prestige
	
	return discrepancy

# Розрахунок штрафу престижу за невідповідність
func calculate_prestige_penalty(item_prestige: int, item_type: String = "") -> int:
	var discrepancy = calculate_discrepancy(item_prestige)
	
	# Якщо невідповідність менша за поріг толерантності, немає штрафу
	if abs(discrepancy) <= TOLERANCE_THRESHOLD:
		return 0
	
	# Обробка виключень
	if item_type in exception_types:
		var modifier = exception_types[item_type]
		if modifier is bool:
			if modifier == true:  # Повне виключення
				return 0
		elif modifier is float:
			discrepancy *= modifier  # Часткове зменшення штрафу
	
	# Позитивна невідповідність (кузня має занадто високий престиж)
	if discrepancy > TOLERANCE_THRESHOLD:
		var penalty = int((discrepancy - TOLERANCE_THRESHOLD) * get_level_multiplier())
		return penalty
	
	return 0

# Розрахунок бонусу престижу за невідповідність
func calculate_prestige_bonus(item_prestige: int) -> int:
	var discrepancy = calculate_discrepancy(item_prestige)
	
	# Негативна невідповідність (виріб має вищий престиж, ніж очікується від кузні)
	if discrepancy < -TOLERANCE_THRESHOLD:
		var bonus = int(abs(discrepancy + TOLERANCE_THRESHOLD) * 0.5)
		return bonus
	
	return 0

# Отримання інформації про наступний рівень
func get_next_level_info() -> Dictionary:
	var current_level = get_current_level_info()
	var current_index = prestige_levels.find(current_level)
	
	if current_index < prestige_levels.size() - 1:
		return prestige_levels[current_index + 1]
	
	# Якщо це останній рівень
	return {}


# PUBLIC FUNCTIONS
# Додавання престижу
func add_prestige(amount: int, source: String = "") -> void:
	if amount == 0:
		return
		
	var old_value = prestige_points
	prestige_points = clamp(prestige_points + amount, 0, 1000)
	
	# Додаємо запис в історію
	prestige_history.append({
		"day": GameTime.current_day,
		"value": prestige_points,
		"change": amount,
		"source": source
	})
	
	emit_signal("prestige_changed", old_value, prestige_points)
	
	# Перевірка на досягнення
	check_achievements()
	
	# Перевірка на зміну рівня
	update_prestige_level()

# Втрата престижу
func lose_prestige(amount: int, source: String = "") -> void:
	add_prestige(-amount, source)

# Отримання інформації про поточний рівень
func get_current_level_info() -> Dictionary:
	for level in prestige_levels:
		if prestige_points >= level.min and prestige_points <= level.max:
			return level
	
	# За замовчуванням повертаємо перший рівень
	return prestige_levels[0]

# Отримання назви поточного рівня
func get_current_level_name() -> String:
	return get_current_level_info().name

# Отримання опису поточного рівня
func get_current_level_description() -> String:
	return get_current_level_info().description

# Отримання множника рівня для штрафів
func get_level_multiplier() -> float:
	return get_current_level_info().multiplier

# Отримання дільника рівня для приросту престижу
func get_level_divisor() -> int:
	return get_current_level_info().divisor

# Отримання цінової премії (підвищення ціни)
func get_price_premium() -> float:
	return get_current_level_info().price_premium

# Отримання знижки від постачальників
func get_supplier_discount() -> float:
	return get_current_level_info().supplier_discount

# Розрахунок фактичного впливу на престиж для виробу
func calculate_actual_prestige_impact(item_prestige: int, item_type: String = "") -> Dictionary:
	var discrepancy = calculate_discrepancy(item_prestige)
	var penalty = 0
	var bonus = 0
	var actual_impact = 0
	
	# Позитивна невідповідність (штраф)
	if discrepancy > TOLERANCE_THRESHOLD:
		penalty = calculate_prestige_penalty(item_prestige, item_type)
		actual_impact = item_prestige - penalty
	
	# Негативна невідповідність (бонус)
	elif discrepancy < -TOLERANCE_THRESHOLD:
		bonus = calculate_prestige_bonus(item_prestige)
		actual_impact = item_prestige + bonus
	
	# В межах толерантності
	else:
		actual_impact = item_prestige
	
	return {
		"discrepancy": discrepancy,
		"penalty": penalty,
		"bonus": bonus,
		"impact": actual_impact
	}

# Отримати зону толерантності для поточного рівня престижу
func get_tolerance_range() -> Dictionary:
	var normalized_prestige = prestige_points / 100.0
	
	# Визначаємо діапазон прийнятного престижу виробів
	var min_acceptable = max(0, normalized_prestige - TOLERANCE_THRESHOLD)
	var max_acceptable = normalized_prestige + TOLERANCE_THRESHOLD
	
	# Додатково масштабуємо для кузень високого рівня
	if prestige_points >= 500:
		min_acceptable = 2
		max_acceptable = 8
	
	if prestige_points >= 900:
		min_acceptable = 6
		max_acceptable = 12
	
	return {
		"min": min_acceptable,
		"max": max_acceptable
	}

# Обробка завершення виготовлення предмета
func process_item_completion(item: ItemData, order: Order = null) -> Dictionary:
	var item_prestige = item.get_prestige()
	var item_type = "normal"
	
	# Визначення типу виробу на основі замовлення
	if order:
		if order.faction_type == "nobles" or order.faction_type == "church":
			item_type = "noble_order"
		elif order.base_price <= 0:  # Безкоштовне замовлення
			item_type = "charity"
	
	# Розрахунок впливу на престиж
	var impact_data = calculate_actual_prestige_impact(item_prestige, item_type)
	
	# Застосовуємо фактичний вплив
	add_prestige(impact_data.impact, "Виготовлення: " + item.name)
	
	return impact_data

# Перевірка чи виріб відповідає рівню кузні
func is_item_appropriate_for_forge(item_prestige: int) -> bool:
	var tolerance_range = get_tolerance_range()
	return item_prestige >= tolerance_range.min and item_prestige <= tolerance_range.max

# Розрахунок приросту престижу від продажу виробу
func calculate_prestige_gain_from_item(item: ItemData) -> int:
	var item_prestige = item.get_prestige()
	var level_divisor = get_level_divisor()
	
	# Приріст престижу = Престиж виробу / Дільник рівня
	var prestige_gain = int(item_prestige / level_divisor)
	
	return max(1, prestige_gain)  # Мінімальний приріст - 1 пункт

# Оновлена функція отримання множника ціни
func get_price_multiplier() -> float:
	# Отримуємо цінову премію з таблиці
	var premium = get_price_premium()
	
	# Додаємо випадковий фактор в межах діапазону премії
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Залежно від рівня, визначаємо діапазон
	var range_addon = 0.0
	if premium >= 0.01:
		range_addon = rng.randf_range(0.0, 0.02)  # Додатковий розкид 0-2%
	
	return 1.0 + premium + range_addon

# Розрахунок знижки для закупівлі матеріалів
func calculate_material_discount(base_price: int) -> int:
	var discount = get_supplier_discount()
	var discounted_price = int(base_price * (1.0 - discount))
	
	return base_price - discounted_price

# Отримання даних для UI
func get_ui_data() -> Dictionary:
	var current_level = get_current_level_info()
	var tolerance_range = get_tolerance_range()
	
	return {
		"prestige": prestige_points,
		"level_name": current_level.name,
		"level_description": current_level.description,
		"level_progress": float(prestige_points - current_level.min) / (current_level.max - current_level.min),
		"min_appropriate_prestige": tolerance_range.min,
		"max_appropriate_prestige": tolerance_range.max,
		"next_level": get_next_level_info(),
		"price_premium": get_price_premium() * 100,  # У відсотках
		"supplier_discount": get_supplier_discount() * 100  # У відсотках
	}

# Отримання історії престижу за певний період
func get_prestige_history(days: int = 30) -> Array:
	var cutoff_day = max(0, GameTime.current_day - days)
	var filtered_history = []
	
	for entry in prestige_history:
		if entry.day >= cutoff_day:
			filtered_history.append(entry)
	
	return filtered_history

# Прогнозування впливу на престиж для майбутнього виробу
func forecast_prestige_impact(estimated_item_prestige: int, item_type: String = "") -> Dictionary:
	return calculate_actual_prestige_impact(estimated_item_prestige, item_type)

# Перевірка доступності підвищень престижу
func check_prestige_unlocks() -> Dictionary:
	var unlocks = {
		"unique_orders": prestige_points >= 300,
		"noble_students": prestige_points >= 400,
		"rare_materials": prestige_points >= 500,
		"noble_events": prestige_points >= 600,
		"social_status": prestige_points >= 700,
		"royal_title": prestige_points >= 800
	}
	
	return unlocks

# Отримання поточної ціни матеріалу з урахуванням знижки від постачальників
func get_discounted_material_price(base_price: int) -> int:
	var discount = get_supplier_discount()
	return int(base_price * (1.0 - discount))

# Розрахунок реальної ціни виробу з урахуванням цінової премії
func calculate_item_selling_price(base_price: int) -> int:
	var price_modifier = get_price_multiplier()
	return int(base_price * price_modifier)
