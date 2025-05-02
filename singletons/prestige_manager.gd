extends Node

# Сигнали
signal prestige_achievement_unlocked(achievement_name, prestige_bonus)

# Пороги для досягнень престижу
var prestige_achievements = {
	"first_weapon": {"name": "Перша зброя", "threshold": 50, "bonus": 10, "unlocked": false},
	"noble_order": {"name": "Замовлення від знаті", "threshold": 100, "bonus": 20, "unlocked": false},
	"masterpiece": {"name": "Шедевр", "threshold": 300, "bonus": 50, "unlocked": false},
	"royal_weapon": {"name": "Королівська зброя", "threshold": 500, "bonus": 100, "unlocked": false}
}

# Ініціалізація
func _ready() -> void:
	pass

# Перевірка досягнень
func check_achievements() -> void:
	for achievement_id in prestige_achievements:
		var achievement = prestige_achievements[achievement_id]
		
		if not achievement.unlocked and ForgeManager.forge_prestige >= achievement.threshold:
			achievement.unlocked = true
			
			# Бонус за досягнення
			var bonus = achievement.bonus
			ForgeManager.update_prestige(bonus)
			
			emit_signal("prestige_achievement_unlocked", achievement.name, bonus)

# Отримання множника рівня для розрахунків
func get_level_multiplier() -> float:
	var forge_level = get_forge_level()
	var config = Global.get_config()
	
	match forge_level:
		Enums.ForgeLevel.UNKNOWN, Enums.ForgeLevel.LOCAL:
			return config.complexity_mod_level_1
		Enums.ForgeLevel.RESPECTED, Enums.ForgeLevel.KNOWN:
			return config.complexity_mod_level_2
		Enums.ForgeLevel.MASTERFUL:
			return config.complexity_mod_level_3
		Enums.ForgeLevel.ELITE, Enums.ForgeLevel.LEGENDARY:
			return config.complexity_mod_level_4
		_:
			return 1.0

# Отримання дільника рівня для приросту престижу
func get_level_divisor() -> int:
	var config = Global.get_config()
	var forge_level = get_forge_level()
	
	match forge_level:
		Enums.ForgeLevel.UNKNOWN, Enums.ForgeLevel.LOCAL:
			return config.prestige_level_divisor_low
		Enums.ForgeLevel.RESPECTED, Enums.ForgeLevel.KNOWN:
			return config.prestige_level_divisor_medium
		Enums.ForgeLevel.MASTERFUL, Enums.ForgeLevel.ELITE, Enums.ForgeLevel.LEGENDARY:
			return config.prestige_level_divisor_high
		_:
			return config.prestige_level_divisor_medium

# Розрахунок престижу для замовлення
func calculate_order_prestige_gain(min_quality: int, difficulty: Recipe.CreationDifficulty) -> int:
	var config = Global.get_config()
	var complexity = 1.0
	
	match difficulty:
		Recipe.CreationDifficulty.HOUSEHOLD:
			complexity = config.complexity_mod_level_1
		Recipe.CreationDifficulty.BASIC:
			complexity = config.complexity_mod_level_2
		Recipe.CreationDifficulty.MILITARY:
			complexity = config.complexity_mod_level_3
		Recipe.CreationDifficulty.ELITE:
			complexity = config.complexity_mod_level_4
	
	# Базовий престиж
	var base_prestige = min_quality / config.prestige_gain_quality_divisor * complexity
	
	# Модифікатор залежно від поточного престижу кузні
	var prestige_modifier = get_prestige_modifier_for_difficulty(difficulty)
	
	return int(base_prestige * prestige_modifier)

# Отримання модифікатора престижу залежно від складності
func get_prestige_modifier_for_difficulty(difficulty: Recipe.CreationDifficulty) -> float:
	var modifier = 1.0
	var forge_prestige = ForgeManager.forge_prestige
	var config = Global.get_config()
	
	# Зниження множника залежно від загального престижу кузні
	if forge_prestige < config.prestige_level_1:
		modifier = config.prestige_modifier_level_1
	elif forge_prestige < config.prestige_level_3:
		modifier = config.prestige_modifier_level_2 - (forge_prestige - config.prestige_level_1) / config.prestige_modifier_decline_rate_1
	elif forge_prestige < config.prestige_level_5:
		modifier = config.prestige_modifier_level_3 - (forge_prestige - config.prestige_level_3) / config.prestige_modifier_decline_rate_2
	else:
		modifier = config.prestige_modifier_level_4 - (forge_prestige - config.prestige_level_5) / config.prestige_modifier_decline_rate_3
	
	# Бонус для складних предметів
	if forge_prestige > config.prestige_level_4 and difficulty >= Recipe.CreationDifficulty.MILITARY:
		modifier += config.prestige_modifier_bonus_military
	if forge_prestige > config.prestige_level_6 and difficulty == Recipe.CreationDifficulty.ELITE:
		modifier += config.prestige_modifier_bonus_elite
	
	return max(config.prestige_modifier_minimum, modifier)

# Отримання поточного рівня кузні залежно від престижу
func get_forge_level() -> Enums.ForgeLevel:
	var forge_prestige = ForgeManager.forge_prestige
	var config = Global.get_config()
	
	if forge_prestige < config.prestige_level_1:
		return Enums.ForgeLevel.UNKNOWN
	elif forge_prestige < config.prestige_level_2:
		return Enums.ForgeLevel.LOCAL
	elif forge_prestige < config.prestige_level_3:
		return Enums.ForgeLevel.RESPECTED
	elif forge_prestige < config.prestige_level_4:
		return Enums.ForgeLevel.KNOWN
	elif forge_prestige < config.prestige_level_5:
		return Enums.ForgeLevel.MASTERFUL
	elif forge_prestige < config.prestige_level_6:
		return Enums.ForgeLevel.ELITE
	else:
		return Enums.ForgeLevel.LEGENDARY

# Обробка завершення виготовлення предмета
func process_item_completion(item: Recipe) -> int:
	var item_prestige = item.get_prestige()
	
	# Застосовуємо модифікатор престижу залежно від рівня кузні
	var config = Global.get_config()
	var forge_prestige = ForgeManager.forge_prestige
	var prestige_modifier = 1.0
	
	# Зниження множника залежно від загального престижу кузні
	if forge_prestige < config.prestige_level_1:
		prestige_modifier = config.prestige_modifier_level_1
	elif forge_prestige < config.prestige_level_3:
		prestige_modifier = config.prestige_modifier_level_2 - (forge_prestige - config.prestige_level_1) / config.prestige_modifier_decline_rate_1
	elif forge_prestige < config.prestige_level_5:
		prestige_modifier = config.prestige_modifier_level_3 - (forge_prestige - config.prestige_level_3) / config.prestige_modifier_decline_rate_2
	else:
		prestige_modifier = config.prestige_modifier_level_4 - (forge_prestige - config.prestige_level_5) / config.prestige_modifier_decline_rate_3
		
	# Застосовуємо фактичний вплив
	var actual_impact = int(item_prestige * prestige_modifier)
	ForgeManager.update_prestige(actual_impact)
	
	# Перевірка досягнень
	check_achievements()
	
	return actual_impact

# Розрахунок приросту престижу від продажу виробу
func calculate_prestige_gain_from_item(item: Recipe) -> int:
	var item_prestige = item.get_prestige()
	var level_divisor = get_level_divisor()
	
	# Приріст престижу = Престиж виробу / Дільник рівня
	var prestige_gain = int(item_prestige / level_divisor)
	
	return max(1, prestige_gain)  # Мінімальний приріст - 1 пункт

# Отримання назви поточного рівня
func get_current_level_name() -> String:
	var forge_level = get_forge_level()
	
	match forge_level:
		Enums.ForgeLevel.UNKNOWN:
			return "Невідома кузня"
		Enums.ForgeLevel.LOCAL:
			return "Місцева кузня"
		Enums.ForgeLevel.RESPECTED:
			return "Поважна кузня"
		Enums.ForgeLevel.KNOWN:
			return "Відома кузня"
		Enums.ForgeLevel.MASTERFUL:
			return "Майстерна кузня"
		Enums.ForgeLevel.ELITE:
			return "Еліта ремісництва"
		Enums.ForgeLevel.LEGENDARY:
			return "Легендарна кузня"
		_:
			return "Невідома кузня"

# Отримання опису поточного рівня
func get_current_level_description() -> String:
	var forge_level = get_forge_level()
	
	match forge_level:
		Enums.ForgeLevel.UNKNOWN:
			return "Початківець, відомий лише в околицях"
		Enums.ForgeLevel.LOCAL:
			return "Має постійних клієнтів серед містян"
		Enums.ForgeLevel.RESPECTED:
			return "Довіра купців і міської варти"
		Enums.ForgeLevel.KNOWN:
			return "Визнана серед лицарства та дрібної шляхти"
		Enums.ForgeLevel.MASTERFUL:
			return "Відома у всьому воєводстві"
		Enums.ForgeLevel.ELITE:
			return "Слава досягає сусідніх держав"
		Enums.ForgeLevel.LEGENDARY:
			return "Вироби стають легендами"
		_:
			return "Початківець, відомий лише в околицях"

# Отримання цінової премії (підвищення ціни)
func get_price_premium() -> float:
	return ForgeManager.price_premium

# Отримання знижки від постачальників
func get_supplier_discount() -> float:
	return ForgeManager.supplier_discount
