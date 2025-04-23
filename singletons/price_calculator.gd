extends Node

# Функція для розрахунку очікуваної ціни матеріалів простого виробу
static func calculate_simple_item_material_cost(item: SimpleItem) -> int:
	print("[PRICE] Calculating cost for simple item: ", item.name)
	var total_cost = 0
	
	# Переконаємося що subcategory_materials ініціалізовано
	if item.subcategory_materials.is_empty():
		if item.has_method("initialize_subcategory_materials"):
			item.initialize_subcategory_materials()
			print("[PRICE] Initialized subcategory_materials")
	
	print("[PRICE] Subcategory materials: ", item.subcategory_materials)
	
	# Для кожного типу матеріалу у підкатегорії
	for material_type in item.subcategory_materials.keys():
		var quantity = item.subcategory_materials[material_type]
		print("[PRICE] Material type: ", material_type, ", quantity: ", quantity)
		
		# Отримати ціну матеріалу для потрібної якості
		var material_cost = get_material_cost_for_quality(material_type, 50)  # Використовуємо середню якість 50 за замовчуванням
		print("[PRICE] Material cost: ", material_cost, " per unit")
		
		total_cost += material_cost * quantity
		print("[PRICE] Subtotal: ", material_cost * quantity)
	
	print("[PRICE] Total material cost for ", item.name, ": ", total_cost)
	return total_cost

# Функція для розрахунку очікуваної ціни матеріалів складного виробу
static func calculate_complex_item_material_cost(item: ComplexItem) -> int:
	print("[PRICE] Calculating cost for complex item: ", item.name)
	var total_cost = 0
	
	# Перебираємо всі слоти компонентів
	for slot in item.component_slots:
		if slot is ComponentSlot and slot.allowed_component != null:
			var component = slot.allowed_component
			print("[PRICE] Processing slot with component: ", component.name)
			
			# Використовуємо max_stack для кількості компонентів
			var required_amount = slot.max_stack
			if required_amount <= 0:
				required_amount = 1  # Мінімальна кількість 1, якщо max_stack не встановлено
			
			print("[PRICE] Required amount (max_stack): ", required_amount)
			
			# Розраховуємо вартість компонента
			var component_cost = calculate_simple_item_material_cost(component)
			print("[PRICE] Component cost: ", component_cost, " x ", required_amount)
			
			total_cost += component_cost * required_amount
		else:
			print("[PRICE] Slot doesn't have an allowed component")
	
	print("[PRICE] Total material cost for complex item ", item.name, ": ", total_cost)
	return total_cost

# Отримати вартість матеріалу певної якості
static func get_material_cost_for_quality(material_type: int, quality: int) -> int:
	var config = Global.get_config()
	
	# Базова ціна для типу матеріалу
	var base_cost = 10 # Значення за замовчуванням
	
	match material_type:
		Enums.MaterialType.METAL:
			base_cost = config.metal_base_cost
		Enums.MaterialType.LEATHER:
			base_cost = config.leather_base_cost
		Enums.MaterialType.WOOD:
			base_cost = config.wood_base_cost
		Enums.MaterialType.FABRIC:
			base_cost = config.fabric_base_cost
	
	# Множник якості (чим вища якість, тим дорожче)
	var quality_multiplier = 1.0 + (quality * config.quality_cost_multiplier)
	
	return int(base_cost * quality_multiplier)

# Розрахунок фактичної ціни замовлення
static func calculate_actual_order_price(order: Order, item: ItemData, quality_execution: float = 0.8) -> int:
	var config = Global.get_config()
	var negotiated_price = order.negotiated_price
	
	# Якщо ціна вже узгоджена під час торгу
	if negotiated_price > 0:
		return negotiated_price
	
	# Інакше рахуємо за формулою:
	# Фактична ціна = Базова ціна * Модифікатор складності * Модифікатор якості
	
	var base_price = order.base_price
	
	# Модифікатор складності фінального виробу
	var complexity_mod = 1.0
	var complexity_level = item.get_complexity_level() if item.has_method("get_complexity_level") else 1
	
	if item is SimpleItem:
		match complexity_level:
			1: complexity_mod = config.complexity_mod_level_1
			2: complexity_mod = config.complexity_mod_level_2
			3: complexity_mod = config.complexity_mod_level_3
			4: complexity_mod = config.complexity_mod_level_4
	else:  # ComplexItem
		match complexity_level:
			1: complexity_mod = config.complexity_mod_level_1
			2: complexity_mod = config.complexity_mod_level_2
			3: complexity_mod = config.complexity_mod_level_3
			4: complexity_mod = config.complexity_mod_level_4
	
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
	
	# Модифікатор якості виконання (від міні-гри)
	var execution_mod = config.quality_mod_min + (quality_execution * config.quality_mod_range)
	
	# Бонус престижу кузні
	var prestige_bonus = 1.0 + ForgeManager.price_premium
	
	# Фінальна ціна з усіма модифікаторами
	var final_price = int(base_price * complexity_mod * quality_mod * execution_mod * prestige_bonus)
	
	return final_price
