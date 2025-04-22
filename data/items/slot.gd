extends Resource
class_name Slot

signal slot_filled(slot: Slot)  # Сигнал, що слот повністю заповнений
signal content_added(item)  # Сигнал про додавання вмісту
signal content_removed(item)  # Сигнал про видалення вмісту
signal quality_changed(new_quality: float)  # Сигнал про зміну якості

@export var weight: int = 1  # Вага для розрахунку (1-3)
@export var is_required: bool = true  # Чи є обов'язковим
@export var max_stack: int = 10  # Максимальна кількість вмісту у слоті

var quantity: int = 0  # Необхідна кількість вмісту
var quality: float = 0.0  # Середня якість вмісту слота

# Чи повністю заповнений слот (кількість >= необхідної)
func is_filled() -> bool:
	return get_current_quantity() >= quantity

# Отримати поточну кількість вмісту (перевизначається в нащадках)
func get_current_quantity() -> int:
	return 0

# Очистити слот (перевизначається в нащадках)
func clear() -> void:
	quality = 0.0
	emit_signal("quality_changed", quality)

# Оновити значення якості
func update_quality() -> void:
	var old_quality = quality
	quality = calculate_average_quality()
	
	# Якщо якість змінилася, відправити сигнал
	if old_quality != quality:
		emit_signal("quality_changed", quality)

# Розрахувати середню якість вмісту (перевизначається в нащадках)
func calculate_average_quality() -> float:
	return 0.0

# Перевірити чи можна додати ще вміст
func can_add_more() -> bool:
	return get_current_quantity() < max_stack

# Перевірка чи слот містить конкретний елемент
func contains(item) -> bool:
	return false  # Базова реалізація

# Отримати вартість матеріалів у слоті
func get_material_cost() -> int:
	return 0  # Базова реалізація

# Перевірка, чи слот повністю порожній 
func is_empty() -> bool:
	return get_current_quantity() == 0

# Получение качества материалов в процентах
func get_quality_percentage() -> float:
	return quality

# Отримання коефіцієнта ваги для розрахунку загальної якості
func get_weight_coefficient() -> float:
	# Переводимо вагу в коефіцієнт
	match weight:
		1: return 1.0
		2: return 1.5
		3: return 2.0
		_: return 1.0

# Отримання всіх елементів в слоті
func get_all_items() -> Array:
	return []  # Базова реалізація, перевизначається в нащадках
