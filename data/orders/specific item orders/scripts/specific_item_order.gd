extends Order
class_name SpecificItemOrder

# Item properties
@export var required_item: ItemData  # Direct reference to the required item

func _init() -> void:
	super()
	order_type = OrderType.SPECIFIC_ITEM

func initialize_item():
	# Automatically calculate base price if required_item is set
	if required_item != null:
		calculate_base_price()
		
	super()
	
	negotiated_price = calculate_final_price()
	print("neg price - ", negotiated_price)
	

# Override validate_item method to check exact match
func validate_item(item: ItemData) -> bool:
	if not super.validate_item(item):
		return false
	
	# Check if item matches the required item
	if required_item != null and item is ComplexItem:
		return item.name == required_item.name
	
	return false

# Розрахунок базової ціни (лише собівартість матеріалів)
func calculate_base_price() -> int:
	print("[ORDER] Calculating base price (material cost) for order: ", order_name)
	
	if required_item == null:
		print("[ORDER] No required_item set, returning current base_price: ", base_price)
		return base_price
	
	# Розрахунок вартості матеріалів
	var material_cost = 0
	
	if required_item is ComplexItem:
		print("[ORDER] Calculating material cost for ComplexItem")
		material_cost = PriceCalculator.calculate_complex_item_material_cost(required_item)
	elif required_item is SimpleItem:
		print("[ORDER] Calculating material cost for SimpleItem")
		material_cost = PriceCalculator.calculate_simple_item_material_cost(required_item)
	
	print("[ORDER] Total material cost: ", material_cost)
	
	# Оновлюємо базову ціну (лише собівартість)
	base_price = material_cost
	
	# Встановлюємо ліміт ціни (для торгівлі) з урахуванням базової націнки 50%
	price_limit = int(base_price * 2.5)  # 150% над собівартістю
	
	return base_price

# Розрахунок фінальної ціни замовлення з урахуванням усіх факторів
func calculate_final_price(quality_execution: float = 0.8, negotiation_result: float = 0.0):
	# Якщо ціна вже узгоджена під час торгу
	if negotiated_price > 0:
		return negotiated_price
	
	# Базова ціна (собівартість)
	var final_price = base_price
	
	# 1. Модифікатор складності виробу
	var complexity_mod = 1.0
	var complexity_level = 1
	
	if required_item.has_method("get_complexity_level"):
		complexity_level = required_item.get_complexity_level()
	
	match complexity_level:
		1: complexity_mod = 1.02
		2: complexity_mod = 1.05
		3: complexity_mod = 1.075
		4: complexity_mod = 1.1
	
	final_price = int(final_price * complexity_mod)
	print("[ORDER] After complexity: ", final_price, " (mod: ", complexity_mod, ")")
	
	# 2. Базова націнка (20% для покриття витрат кузні)
	var base_markup = 1.2
	final_price = int(final_price * base_markup)
	print("[ORDER] After base markup: ", final_price, " (mod: ", base_markup, ")")
	
	# 3. Модифікатор якості виконання (0-1 від міні-гри)
	var quality_mod = 0.8 + (quality_execution * 0.4)  # від 0.8 (при 0) до 1.2 (при 1)
	final_price = int(final_price * quality_mod)
	print("[ORDER] After quality execution: ", final_price, " (mod: ", quality_mod, ")")
	
	# 4. Бонус престижу кузні (отримуємо з ForgeManager)
	var prestige_bonus = 1.0 + ForgeManager.price_premium
	final_price = int(final_price * prestige_bonus)
	print("[ORDER] After prestige bonus: ", final_price, " (mod: ", prestige_bonus, ")")
	
	# 5. Результат торгів (-10%, 0%, +10%, +20%)
	var negotiation_multiplier = 1.0
	
	match negotiation_result:
		-0.1: negotiation_multiplier = 0.9  # -10%
		0.0: negotiation_multiplier = 1.0   # 0%
		0.1: negotiation_multiplier = 1.1   # +10%
		0.2: negotiation_multiplier = 1.2   # +20%
	
	final_price = int(final_price * negotiation_multiplier)
	print("[ORDER] After negotiation: ", final_price, " (mod: ", negotiation_multiplier, ")")
	
	return final_price

# Create a specific item order from a complex item template
static func create_from_item(item: ComplexItem, customer: String, min_quality: int = 50) -> SpecificItemOrder:
	var order = SpecificItemOrder.new()
	
	order.order_name = "Order for " + item.name
	order.description = "Create a " + item.name + " with at least " + str(min_quality) + " quality."
	order.required_item = item
	order.required_quality_min = min_quality
	order.customer_id = customer
	
	# Calculate reputation impact and prestige gain
	order.reputation_impact = 5
	
	# Prestige gain based on item complexity
	var complexity = 1.0
	if item.has_method("get_complexity_coefficient"):
		complexity = item.get_complexity_coefficient()
	
	order.prestige_gain = int(min_quality / 10.0 * complexity)
	
	# Set duration based on complexity
	order.duration_days = int(3 * complexity)
	
	# Base price is automatically calculated in _init when required_item is set
	return order
