extends Resource
class_name ItemData

enum Category {
	TOOLS,          # Інструменти
	ARMOR,          # Обладунки
	WEAPONS         # Зброя
}

enum CreationDifficulty {
	HOUSEHOLD = 1,  # Господарський (0.8)
	BASIC = 2,      # Базовий (0.9)
	MILITARY = 3,   # Військовий (1.0)
	ELITE = 4       # Елітний (1.1)
}

@export var name: String
@export var description: String = ""
@export var creation_difficulty: CreationDifficulty = CreationDifficulty.BASIC
@export var produced_quantity: int = 1
@export var component_slots: Array[Slot] = []

const PRESTIGE_LOW_QUALITY: int = 30
const PRESTIGE_MEDIUM_QUALITY: int = 40
const PRESTIGE_HIGH_QUALITY: int = 60

var quality: float = 0.0  # 0-100
var prestige: float = 0.0
var base_price: int = 0
var required_craftsman_level: Enums.CraftsmanLevel

# Базові методи
func calculate_quality() -> float:
	return 0.0  # Перевизначається в дочірніх класах

func calculate_prestige() -> float:
	return 0.0  # Перевизначається в дочірніх класах

func get_selling_price(forge_premium: float = 0.0) -> int:
	return base_price + int(base_price * forge_premium)

# Отримання категорії предмета
func get_category():
	# Базова реалізація - перевизначається в підкласах
	return Category.TOOLS

# Повертає фактичну якість предмета
func get_quality() -> float:
	if quality <= 0:
		quality = calculate_quality()
	return quality

# Повертає фактичний престиж предмета
func get_prestige() -> float:
	if prestige <= 0:
		prestige = calculate_prestige()
	return prestige

# Отримання рівня складності складання виробу (для розрахунку ціни)
func get_complexity_level():
	return creation_difficulty

# Перевірка чи відповідає предмет вимогам замовлення за типом
func matches_category(required_category) -> bool:
	return get_category() == required_category

# Перевірка чи відповідає предмет вимогам замовлення за складністю
func matches_difficulty(required_difficulty: CreationDifficulty) -> bool:
	return creation_difficulty >= required_difficulty

# Перевірка чи містить предмет конкретний компонент (для складних предметів)
func has_component(component: SimpleItem) -> bool:
	# Простий предмет не має компонентів, перевизначається в ComplexItem
	return false

# Повертає вартість матеріалів
func get_material_cost() -> int:
	var total_cost = 0
	for slot in component_slots:
		if slot is MaterialSlot:
			total_cost += slot.get_material_cost()
	return total_cost

# Повертає назву рівня складності
func get_difficulty_name() -> String:
	match creation_difficulty:
		CreationDifficulty.HOUSEHOLD:
			return "Household"
		CreationDifficulty.BASIC:
			return "Basic"
		CreationDifficulty.MILITARY:
			return "Military"
		CreationDifficulty.ELITE:
			return "Elite"
		_:
			return "Unknown"

# Повертає базовий престиж категорії на основі якості
func get_base_category_prestige() -> int:
	var item_quality = get_quality()
	
	if item_quality < 50:
		return 30  # Базовий престиж для звичайної якості
	elif item_quality < 80:
		return 50  # Базовий престиж для відмінної якості
	else:
		return 70  # Базовий престиж для видатної якості

# Перевірка чи підходить предмет для конкретного замовлення
func matches_order_requirements(order: Order) -> bool:
	# Базова перевірка якості
	return get_quality() >= order.required_quality_min

# Розрахунок ціни виробу для цілей оцінки в системі замовлень
func calculate_estimated_price(desired_quality: int) -> int:
	# Базова реалізація - перевизначається в підкласах
	return base_price

# Повертає рівень майстерності, необхідний для виготовлення
func get_required_craftsman_level() -> Enums.CraftsmanLevel:
	return required_craftsman_level

# Повертає рядок опису для UI з інформацією про виріб
func get_ui_description() -> String:
	var desc = name + "\n"
	desc += "Quality: " + str(int(get_quality())) + "\n"
	desc += "Prestige: " + str(int(get_prestige())) + "\n"
	desc += "Complexity: " + get_difficulty_name() + "\n"
	desc += "Price: " + str(get_selling_price()) + "\n\n"
	desc += description
	return desc

# Отримує коефіцієнт для розрахунку престижу на основі якості
func get_quality_prestige_coefficient() -> float:
	var q = get_quality()
	
	# Залежність від таблиці на скріншоті
	if q < 50:  # 0-49
		return 30.0 / 100.0  # Базовий престиж 30
	elif q < 80:  # 50-79
		return 50.0 / 100.0  # Базовий престиж 50
	else:  # 80-100
		return 70.0 / 100.0  # Базовий престиж 70
