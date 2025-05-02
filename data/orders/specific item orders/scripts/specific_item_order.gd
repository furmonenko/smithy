extends Order
class_name SpecificItemOrder

@export var required_item: Recipe

func _init() -> void:
	super()
	order_type = OrderType.SPECIFIC_ITEM

func initialize_item():
	if required_item != null:
		calculate_base_price()
		negotiated_price = calculate_final_price()
		
	super()

# Override validate_item method to check exact match
func validate_item(item: Recipe) -> bool:
	if not super.validate_item(item):
		return false
	
	# Check if item matches the required item
	if required_item != null and item is ProductRecipe:
		return item.name == required_item.name
	
	return false

# Розрахунок базової ціни (лише собівартість матеріалів)
func calculate_base_price() -> int:
	print("[ORDER] Calculating base price (material cost) for order: ", order_name)
	
	if required_item == null:
		print("[ORDER] No required_item set, returning current base_price: ", base_price)
		return base_price
	
	# Розрахунок вартості матеріалів з урахуванням потрібної якості
	var material_cost = 0
	
	if required_item is ProductRecipe:
		print("[ORDER] Calculating material cost for ProductRecipe")
		material_cost = PriceCalculator.calculate_complex_item_material_cost(required_item, required_quality_min)
	elif required_item is ComponentRecipe:
		print("[ORDER] Calculating material cost for ComponentRecipe")
		material_cost = PriceCalculator.calculate_simple_item_material_cost(required_item, required_quality_min)
	
	print("[ORDER] Total material cost: ", material_cost)
	
	# Оновлюємо базову ціну (лише собівартість)
	base_price = material_cost
	
	# Встановлюємо ліміт ціни (для торгівлі) з урахуванням базової націнки
	var config = Global.get_config()
	price_limit = int(base_price * config.price_limit_multiplier)
	
	return base_price

# Розрахунок фінальної ціни замовлення з урахуванням усіх факторів
func calculate_final_price(quality_execution: float = 0.8, negotiation_result: float = 0.0):
	# Якщо ціна вже узгоджена під час торгу
	if negotiated_price > 0:
		return negotiated_price
	
	# Отримання конфігурації
	var config = Global.get_config()
	
	# Базова ціна (собівартість)
	var final_price = base_price
	
	# 1. Модифікатор складності виробу
	var complexity_mod = 1.0
	var complexity_level = 1
	
	if required_item.has_method("get_complexity_level"):
		complexity_level = required_item.get_complexity_level()
	
	match complexity_level:
		1: complexity_mod = config.complexity_mod_level_1
		2: complexity_mod = config.complexity_mod_level_2
		3: complexity_mod = config.complexity_mod_level_3
		4: complexity_mod = config.complexity_mod_level_4
	
	final_price = int(final_price * complexity_mod)
	print("[ORDER] After complexity: ", final_price, " (mod: ", complexity_mod, ")")
	
	# 2. Базова націнка для покриття витрат кузні
	var base_markup = config.base_markup
	final_price = int(final_price * base_markup)
	print("[ORDER] After base markup: ", final_price, " (mod: ", base_markup, ")")
	
	# 3. Модифікатор якості виконання (0-1 від міні-гри)
	var quality_mod = config.quality_mod_min + (quality_execution * config.quality_mod_range)
	final_price = int(final_price * quality_mod)
	print("[ORDER] After quality execution: ", final_price, " (mod: ", quality_mod, ")")
	
	# 4. Бонус престижу кузні
	var prestige_bonus = 1.0 + ForgeManager.price_premium
	final_price = int(final_price * prestige_bonus)
	print("[ORDER] After prestige bonus: ", final_price, " (mod: ", prestige_bonus, ")")
	
	# 5. Результат торгів (-10%, 0%, +10%, +20%)
	var negotiation_multiplier = 1.0
	
	match negotiation_result:
		-0.1: negotiation_multiplier = config.negotiation_result_bad
		0.0: negotiation_multiplier = config.negotiation_result_normal
		0.1: negotiation_multiplier = config.negotiation_result_good
		0.2: negotiation_multiplier = config.negotiation_result_excellent
	
	final_price = int(final_price * negotiation_multiplier)
	print("[ORDER] After negotiation: ", final_price, " (mod: ", negotiation_multiplier, ")")
	
	return final_price

# Create a specific item order from a complex item template
static func create_from_item(item: ProductRecipe, customer: String, min_quality: int = -1) -> SpecificItemOrder:
	var order = SpecificItemOrder.new()
	
	# Отримання конфігурації через Global
	var config = Global.get_config()
	
	# If min_quality not specified, use default from config
	if min_quality < 0:
		min_quality = config.default_min_quality
	
	order.order_name = "Order for " + item.name
	order.description = "Create a " + item.name + " with at least " + str(min_quality) + " quality."
	order.required_item = item
	order.required_quality_min = min_quality
	order.customer_id = customer
	
	# Calculate reputation impact and prestige gain
	order.reputation_impact = config.base_reputation_impact
	
	# Prestige gain based on item complexity
	var complexity = 1.0
	if item.has_method("get_complexity_coefficient"):
		complexity = item.get_complexity_coefficient()
	
	order.prestige_gain = int(min_quality / config.prestige_gain_quality_divisor * complexity)
	
	# Set duration based on complexity
	order.duration_days = int(config.duration_days_multiplier * complexity)
	
	# Calculate base price with required quality
	order.calculate_base_price()
	
	return order
