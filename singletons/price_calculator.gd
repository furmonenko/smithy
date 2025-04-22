# price_calculator.gd
extends Node

# Функція для розрахунку очікуваної ціни матеріалів простого виробу
func calculate_simple_item_material_cost(item: SimpleItem) -> int:
	var total_cost = 0
	
	# Перевірка, чи є точний вказаний виріб
	if item.is_exact_recipe:
		# Викорстовуємо формулу з першої частини скріншоту 2
		for material in item.required_materials:
			total_cost += material.quantity * material.cost_per_quality
	else:
		# Викорстовуємо формулу з другої частини скріншоту 2
		for material in item.subcategory_materials:
			total_cost += material.quantity * material.cost_per_quality
	
	return total_cost

# Функція для розрахунку очікуваної ціни матеріалів складного виробу
func calculate_complex_item_material_cost(item: ComplexItem) -> int:
	var total_cost = 0
	
	# Сума очікуваних цін простих виробів
	for component in item.components:
		total_cost += calculate_simple_item_material_cost(component)
	
	return total_cost

# Розрахунок фактичної ціни замовлення
func calculate_actual_order_price(order: Order, item: ItemData) -> int:
	var negotiated_price = order.negotiated_price
	
	# Якщо ціна вже узгоджена під час торгу
	if negotiated_price > 0:
		return negotiated_price
	
	# Інакше рахуємо за формулою:
	# Фактична ціна = Виторгована ціна * Модифікатор складності * Модифікатор якості
	
	var base_price = order.base_price
	
	# Модифікатор складності фінального виробу
	var complexity_mod = 1.0
	match item.get_complexity_level():
		1: complexity_mod = 1.05 if item is SimpleItem else 1.02
		2: complexity_mod = 1.1 if item is SimpleItem else 1.05 
		3: complexity_mod = 1.2 if item is SimpleItem else 1.075
		4: complexity_mod = 1.0 if item is SimpleItem else 1.1  # Для рівня 4
	
	# Модифікатор якості фінального виробу
	var quality_mod = 1.0
	var quality_requirement = order.required_quality_min
	var actual_quality = item.get_quality()
	
	if actual_quality == quality_requirement:
		quality_mod = 1.05
	elif actual_quality > quality_requirement:
		quality_mod = 1.1
	elif actual_quality < quality_requirement && actual_quality >= quality_requirement - 10:
		quality_mod = 0.8
	else:
		# Замовлення не приймається
		return 0
	
	return int(base_price * complexity_mod * quality_mod)
