extends Node

# Функція для розрахунку очікуваної ціни матеріалів простого виробу
static func calculate_simple_item_material_cost(item: ComponentRecipe, desired_quality: int = 50) -> int:
	print("[PRICE] Calculating cost for simple item: ", item.name, " with quality: ", desired_quality)
	var total_cost = 0
	
	# Переконаємося що subcategory_materials ініціалізовано
	if item.subcategory_materials.is_empty():
		if item.has_method("initialize_subcategory_materials"):
			item.initialize_subcategory_materials()
			print("[PRICE] Initialized subcategory_materials")
		else:
			print("[PRICE] WARNING: Empty subcategory_materials and no initialization method")
	
	print("[PRICE] Subcategory materials: ", item.subcategory_materials)
	
	# Для кожного типу матеріалу у підкатегорії
	for material_type in item.subcategory_materials.keys():
		var quantity = item.subcategory_materials[material_type]
		print("[PRICE] Material type: ", get_material_type_name(material_type), " (", material_type, "), quantity: ", quantity)
		
		# Отримати найдешевший матеріал відповідної якості через CraftMaterialsManager
		var material = CraftMaterialsManager.get_cheapest_material_by_type_and_quality(material_type, desired_quality)
		
		if material:
			print("[PRICE] Selected material: ", material.name, ", quality: ", material.quality, ", cost: ", material.cost)
			total_cost += material.cost * quantity
			print("[PRICE] Subtotal: ", material.cost * quantity)
		else:
			print("[PRICE] No material found, returning 0.")
			return 0
	
	print("[PRICE] Total material cost for ", item.name, ": ", total_cost)
	return total_cost

# Функція для розрахунку очікуваної ціни матеріалів складного виробу
static func calculate_complex_item_material_cost(item: ProductRecipe, desired_quality: int = 50) -> int:
	print("[PRICE] Calculating cost for complex item: ", item.name, " with desired quality: ", desired_quality)
	var total_cost = 0
	
	# Для ProductRecipe (рецепт) завжди використовуємо component_slots
	print("[PRICE] Using component slots for calculation")
	
	# Перебираємо всі слоти компонентів
	for slot in item.component_slots:
		if slot is ComponentSlot and slot.allowed_component != null:
			var component = slot.allowed_component
			print("[PRICE] Processing slot with component: ", component.name)
			
			# Використовуємо required_amount для кількості компонентів
			var required_amount = slot.required_amount
			if required_amount <= 0:
				required_amount = 1  # Мінімальна кількість 1, якщо required_amount не встановлено
			
			print("[PRICE] Required amount (required_amount): ", required_amount)
			
			# Розраховуємо вартість компонента з тією ж якістю
			var component_cost = calculate_simple_item_material_cost(component, desired_quality)
			print("[PRICE] Component cost: ", component_cost, " x ", required_amount)
			
			total_cost += component_cost * required_amount
		else:
			print("[PRICE] Slot doesn't have an allowed component")
	
	print("[PRICE] Total material cost for complex item ", item.name, ": ", total_cost)
	return total_cost

# Розрахунок фактичної ціни замовлення
static func calculate_actual_order_price(order: Order, item: Recipe, quality_execution: float = 0.8) -> int:
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
	
	if item is ComponentRecipe:
		match complexity_level:
			1: complexity_mod = config.complexity_mod_level_1
			2: complexity_mod = config.complexity_mod_level_2
			3: complexity_mod = config.complexity_mod_level_3
			4: complexity_mod = config.complexity_mod_level_4
	else:  # ProductRecipe
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

# Отримати текстову назву типу матеріалу за числовим ідентифікатором
static func get_material_type_name(material_type: int) -> String:
	match material_type:
		Enums.MaterialType.METAL:
			return "METAL"
		Enums.MaterialType.LEATHER:
			return "LEATHER"
		Enums.MaterialType.WOOD:
			return "WOOD"
		Enums.MaterialType.FABRIC:
			return "FABRIC"
		Enums.MaterialType.DECORATION:
			return "DECORATION"
		Enums.MaterialType.CREATED:
			return "CREATED"
		_:
			return "UNKNOWN"
