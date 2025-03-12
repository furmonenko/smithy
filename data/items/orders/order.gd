# order.gd
extends Resource
class_name Order

enum OrderType {
	GENERAL,           # Загальне замовлення (тільки тип виробу)
	SPECIFIC_COMPONENT, # Замовлення з конкретним компонентом
	SPECIFIC_ITEM,     # Замовлення конкретного виробу
}

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
	if not completed:
		return -abs(reputation_impact)  # Негативний вплив, якщо не виконано
	
	# Позитивний вплив, якщо якість вища за мінімальну
	if actual_quality > required_quality_min:
		var quality_bonus = (actual_quality - required_quality_min) / 10
		return reputation_impact + quality_bonus
	
	return reputation_impact

# Локалізований опис замовлення для UI
func get_ui_description() -> String:
	var desc = "Замовлення від %s\n" % (customer.name if customer else "Невідомого замовника")
	desc += "Якість: %d\n" % [required_quality_min]
	desc += "Базова ціна: %d\n" % base_price
	desc += "Термін виконання: %d днів\n" % duration_days
	
	if description:
		desc += "\n%s" % description
	
	return desc
