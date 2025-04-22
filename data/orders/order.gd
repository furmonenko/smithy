extends Resource
class_name Order

enum OrderType {
	GENERAL,           # Загальне замовлення (тільки тип виробу)
	SPECIFIC_COMPONENT, # Замовлення з конкретним компонентом
	SPECIFIC_ITEM,     # Замовлення конкретного виробу
}

# Сигнали
signal order_accepted
signal order_completed(success)
signal order_failed
signal order_updated

# Загальні властивості для всіх замовлень
@export var required_quality_min: int = 0
@export var base_price: int = 0
@export var price_limit: int = 0  # Максимальна ціна, яку готовий заплатити замовник
@export var duration_days: int = 1  # Тривалість виконання у днях
@export var reputation_impact: int = 0  # Вплив на репутацію коваля (+/-)
@export var description: String = ""
@export var completed: bool = false
@export var faction_type: String = ""  # Тип фракції, що дала замовлення

# Додаткові поля для розширеної функціональності
@export var prestige_gain: int = 0      # Базовий приріст престижу
@export var difficulty_level: int = 1    # Рівень складності (1-3)

var order_id: String
var customer: Resource  # Посилання на ресурс замовника
var order_type: OrderType

# Тимчасові змінні, що використовуються в процесі виконання
var negotiated_price: int = 0  # Ціна після торгів
var crafting_started: bool = false
var crafting_started_date: int = 0  # День, коли почалось виконання
var deadline_date: int = 0  # Кінцевий термін
var actual_quality: int = 0  # Фактична якість виробу
var is_expired: bool = false

# Ініціалізація
func _init() -> void:
	# Генеруємо унікальний ID для замовлення, якщо його ще немає
	if order_id.is_empty():
		order_id = _generate_order_id()
	
	# Встановлюємо limit_price, якщо він не встановлений
	if price_limit <= 0:
		price_limit = int(base_price * 1.2)  # За замовчуванням +20% до базової ціни

# Генерація унікального ID для замовлення
func _generate_order_id() -> String:
	var time = Time.get_unix_time_from_system()
	var random = RandomNumberGenerator.new()
	random.randomize()
	var rand_num = random.randi_range(1000, 9999)
	return "ORD-%d-%d" % [time, rand_num]

# Початок виконання замовлення
func start_crafting() -> void:
	crafting_started = true
	crafting_started_date = GameTime.current_day
	deadline_date = crafting_started_date + duration_days
	emit_signal("order_updated")

# Перевірка чи замовлення прострочене
func check_if_expired() -> bool:
	if crafting_started and GameTime.current_day > deadline_date:
		is_expired = true
		emit_signal("order_updated")
		return true
	return false

# Отримання грошової винагороди
func get_money_reward() -> int:
	if not completed:
		return 0
	
	if negotiated_price > 0:
		return negotiated_price
	
	return base_price

# Отримання впливу на репутацію
func get_reputation_impact() -> int:
	# Враховуємо фракцію та успішність виконання
	if not completed:
		return -abs(reputation_impact)
	
	# Бонус за якість
	if actual_quality > required_quality_min:
		var quality_bonus = (actual_quality - required_quality_min) / 10
		return reputation_impact + quality_bonus
	
	return reputation_impact

# Отримання впливу на престиж
func get_prestige_gain() -> int:
	# Згідно з формулами зі скріншотів
	if not completed:
		return 0
		
	# Базовий приріст престижу
	var base_gain = prestige_gain
	
	# Модифікатор залежно від якості
	var quality_ratio = actual_quality / 100.0
	
	# Приріст = (Престиж Виробу / Дільник Рівня)
	return int(base_gain * quality_ratio)

# Перевірка чи предмет відповідає вимогам замовлення
func validate_item(item: ItemData) -> bool:
	# Базова перевірка якості
	if item.get_quality() < required_quality_min:
		return false
	
	# Додаткові перевірки в підкласах
	return true

# Локалізований опис замовлення для UI
func get_ui_description() -> String:
	var desc = "Замовлення від %s\n" % (customer.name if customer else "Невідомого замовника")
	desc += "Якість: %d\n" % [required_quality_min]
	desc += "Базова ціна: %d\n" % base_price
	desc += "Термін виконання: %d днів\n" % duration_days
	
	if description:
		desc += "\n%s" % description
	
	return desc

# Розрахунок фінальної ціни
func calculate_final_price(item: ItemData) -> int:
	# Якщо ціна вже узгоджена
	if negotiated_price > 0:
		return negotiated_price
		
	# Базова формула з урахуванням модифікаторів складності та якості
	var base = base_price
	var quality_mod = float(actual_quality) / float(required_quality_min)
	var difficulty_mod = 1.0
	
	# Залежність від складності фінального виробу
	match difficulty_level:
		1: difficulty_mod = 1.05
		2: difficulty_mod = 1.1 
		3: difficulty_mod = 1.2
		4: difficulty_mod = 1.3
		
	return int(base * quality_mod * difficulty_mod)

# Торг з замовником
func negotiate_price(offered_price: int) -> bool:
	# Якщо торг виходить за межі ліміту ціни
	if offered_price > price_limit:
		return false
		
	# Мінімальна ціна - 80% від базової
	if offered_price < (base_price * 0.8):
		return false
		
	# Успішний торг
	negotiated_price = offered_price
	return true

# Перевірка чи торг можливий
func can_negotiate() -> bool:
	# Не можна торгуватися, якщо замовлення вже виконується або завершене
	if crafting_started or completed:
		return false
	
	return true

# Повертає модифікатор складності для обчислення ціни
func get_complexity_price_modifier() -> float:
	# Залежність від складності фінального виробу
	match difficulty_level:
		1: return 1.05  # Простий
		2: return 1.1   # Середній
		3: return 1.2   # Складний
		4: return 1.3   # Дуже складний
	return 1.0

# Повертає модифікатор якості для обчислення ціни
func get_quality_price_modifier(item_quality: float) -> float:
	# Коли якість дорівнює вимогам
	if item_quality == required_quality_min:
		return 1.05
	# Коли якість перевищує вимоги
	elif item_quality > required_quality_min:
		return 1.1 + ((item_quality - required_quality_min) / 100.0)
	# Коли якість нижча, але в допустимих межах
	elif item_quality >= required_quality_min - 10:
		return 0.8
	# В інших випадках замовлення не може бути прийняте
	return 0.0

# Перевірка чи замовлення може вважатися виконаним якщо якість нижча ніж вимагається
func accepts_lower_quality() -> bool:
	# За замовчуванням, приймаємо виріб з якістю не нижче ніж на 10 пунктів
	return true

# Отримання залишку днів до дедлайну
func get_days_remaining() -> int:
	if not crafting_started:
		return duration_days
		
	var days_left = deadline_date - GameTime.current_day
	return max(0, days_left)

# Отримання прогресу виконання у відсотках
func get_progress_percentage() -> float:
	if not crafting_started:
		return 0.0
		
	var total_days = float(duration_days)
	var days_passed = float(GameTime.current_day - crafting_started_date)
	
	if days_passed >= total_days:
		return 100.0
		
	return (days_passed / total_days) * 100.0

# Метод для оцінки вартості замовлення з урахуванням всіх модифікаторів
func estimate_total_value() -> int:
	var estimated_value = base_price
	
	# Додаємо цінність від репутації
	estimated_value += abs(reputation_impact) * 10
	
	# Додаємо цінність від престижу
	estimated_value += prestige_gain * 5
	
	# Вплив складності
	estimated_value = int(estimated_value * get_complexity_price_modifier())
	
	return estimated_value
