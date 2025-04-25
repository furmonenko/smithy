extends Resource
class_name GameConfig

# ----- Ціни та економіка -----
@export_category("Price Configuration")
# Базова націнка для покриття витрат кузні
@export var base_markup: float = 1.2  # 20%

# Множники для модифікатора складності виробу
@export_group("Complexity Modifiers")
@export var complexity_mod_level_1: float = 1.02
@export var complexity_mod_level_2: float = 1.05
@export var complexity_mod_level_3: float = 1.075
@export var complexity_mod_level_4: float = 1.1

# Діапазон модифікатора якості виконання
@export_group("Quality Execution Modifiers")
@export var quality_mod_min: float = 0.8  # Мінімальний множник (при якості виконання 0)
@export var quality_mod_range: float = 0.4  # Діапазон від мін до макс (0.8 - 1.2)

# Множники для результатів торгів
@export_group("Negotiation Result Modifiers")
@export var negotiation_result_bad: float = 0.9   # -10%
@export var negotiation_result_normal: float = 1.0  # 0%
@export var negotiation_result_good: float = 1.1   # +10%
@export var negotiation_result_excellent: float = 1.2   # +20%

# Ліміт ціни для торгівлі (відносно базової собівартості)
@export var price_limit_multiplier: float = 2.5  # 150% над собівартістю

# ----- Замовлення -----
@export_category("Order Configuration")
# Базовий вплив на репутацію за виконання замовлення
@export var base_reputation_impact: int = 5

# Множник для розрахунку тривалості замовлення
@export var duration_days_multiplier: int = 3  # Днів на одиницю складності

# Мінімальна якість за замовчуванням
@export var default_min_quality: int = 50

# Множник для розрахунку престижу від якості
@export var prestige_gain_quality_divisor: float = 10.0  # Престиж = якість / цей дільник * складність

# ----- Кузня -----
@export_category("Forge Configuration")
# Максимальна кількість активних замовлень
@export var max_active_orders: int = 5

# Початкові значення
@export_group("Starting Values")
@export var starting_money: int = 100
@export var starting_prestige: int = 0

# ----- Престиж -----
@export_category("Prestige Configuration")
# Базові значення престижу для різних рівнів якості
@export_group("Base Prestige Values")
@export var prestige_low_quality: int = 30   # Звичайна якість
@export var prestige_medium_quality: int = 40  # Відмінна якість
@export var prestige_high_quality: int = 60  # Видатна якість

# Рівні престижу для застосування цінової премії
@export_group("Prestige Levels")
@export var prestige_level_1: int = 50
@export var prestige_level_2: int = 150
@export var prestige_level_3: int = 300
@export var prestige_level_4: int = 500
@export var prestige_level_5: int = 700
@export var prestige_level_6: int = 900

# Цінові премії за рівнями престижу
@export_group("Price Premium Values")
@export var price_premium_level_1: float = 0.01  # 1%
@export var price_premium_level_2: float = 0.02  # 2%
@export var price_premium_level_3: float = 0.05  # 5%
@export var price_premium_level_4: float = 0.08  # 8%
@export var price_premium_level_5: float = 0.12  # 12%
@export var price_premium_level_6: float = 0.15  # 15%

# Параметри для розрахунку престижу
@export_group("Prestige Calculation")
@export var prestige_level_divisor_low: int = 5
@export var prestige_level_divisor_medium: int = 10
@export var prestige_level_divisor_high: int = 20

@export var prestige_modifier_level_1: float = 1.0
@export var prestige_modifier_level_2: float = 0.8
@export var prestige_modifier_level_3: float = 0.6
@export var prestige_modifier_level_4: float = 0.4
@export var prestige_modifier_minimum: float = 0.1

@export var prestige_modifier_decline_rate_1: float = 1000.0
@export var prestige_modifier_decline_rate_2: float = 1500.0
@export var prestige_modifier_decline_rate_3: float = 2000.0

@export var prestige_modifier_bonus_military: float = 0.2
@export var prestige_modifier_bonus_elite: float = 0.3

# Рівні престижу для знижок постачальників
@export_group("Supplier Discount Levels")
@export var supplier_discount_level_1: int = 300
@export var supplier_discount_level_2: int = 500
@export var supplier_discount_level_3: int = 700
@export var supplier_discount_level_4: int = 900

# Знижки від постачальників за рівнями престижу
@export_group("Supplier Discount Values")
@export var supplier_discount_value_1: float = 0.03  # 3%
@export var supplier_discount_value_2: float = 0.05  # 5%
@export var supplier_discount_value_3: float = 0.07  # 7%
@export var supplier_discount_value_4: float = 0.10  # 10%

# ----- Матеріали -----
@export_category("Material Configuration")
# Базові вартості матеріалів
@export_group("Base Material Costs")
@export var metal_base_cost: int = 20
@export var leather_base_cost: int = 15
@export var wood_base_cost: int = 10
@export var fabric_base_cost: int = 8

# Множник якості для вартості матеріалу
@export var quality_cost_multiplier: float = 0.01  # Вартість збільшується на 1% за кожну одиницю якості
