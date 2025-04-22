extends Resource
class_name Order

# --------------------------------
# Core Enums for orders
# --------------------------------

enum OrderType {
	SPECIFIC_ITEM     # Order for specific item
}

enum OrderStatus {
	NEW,               # New order
	ACCEPTED,          # Accepted for production
	IN_PROGRESS,       # Currently being crafted
	COMPLETED,         # Successfully completed
	FAILED,            # Failed to complete
	EXPIRED            # Deadline missed
}

# --------------------------------
# Signals
# --------------------------------

signal order_state_changed(old_state: OrderStatus, new_state: OrderStatus)
signal order_updated

# --------------------------------
# Exported properties
# --------------------------------

# Basic properties
@export_category("Basic Properties")
@export var order_name: String = ""
@export var description: String = ""
@export var required_quality_min: int = 0
@export var duration_days: int = 1  # Duration in days

# Reputation and prestige impact
@export_category("Reputation & Rewards")
@export var reputation_impact: int = 0  # Impact on smith's reputation (+/-)

# --------------------------------
# Internal properties
# --------------------------------

var order_id: String
var customer_id: String  # Customer identifier
var status: OrderStatus = OrderStatus.NEW
var base_price: int = 0
var price_limit: int = 0  # Maximum price customer is willing to pay
var prestige_gain: int = 0      # Base prestige gain

# Price and negotiations
var negotiated_price: int = 0  # Price after negotiations

# Result
var actual_quality: int = 0    # Actual quality of the item
var actual_item_id: String = "" # ID of the actual item
var order_type: OrderType = OrderType.SPECIFIC_ITEM

# --------------------------------
# Initialization methods
# --------------------------------

func _init() -> void:
	# Generate unique ID for the order if it doesn't exist
	if order_id == null or order_id.is_empty():
		order_id = _generate_order_id()

# Generate unique ID for the order
func _generate_order_id() -> String:
	var time = Time.get_unix_time_from_system()
	var random = RandomNumberGenerator.new()
	random.randomize()
	var rand_num = random.randi_range(1000, 9999)
	return "ORD-%d-%d" % [time, rand_num]

func initialize_item():
	# Set price limit if not set
	if price_limit <= 0:
		price_limit = int(base_price * 1.2)  # Default +20% to base price

# --------------------------------
# Order lifecycle management
# --------------------------------

func calculate_base_price() -> int:
	return base_price

# Accept order
func accept() -> void:
	if status != OrderStatus.NEW:
		printerr("Cannot accept order with status " + OrderStatus.keys()[status])
		return
	
	var old_state = status
	status = OrderStatus.ACCEPTED
	
	# Notify about the state change
	order_state_changed.emit(old_state, status)
	order_updated.emit()

# Start crafting the order
func start_crafting() -> void:
	if status != OrderStatus.ACCEPTED:
		printerr("Cannot start crafting order with status " + OrderStatus.keys()[status])
		return
	
	var old_state = status
	status = OrderStatus.IN_PROGRESS
	
	order_state_changed.emit(old_state, status)
	order_updated.emit()

# Complete the order
func complete(item_quality: int, item_id: String) -> bool:
	if status != OrderStatus.IN_PROGRESS:
		printerr("Cannot complete order with status " + OrderStatus.keys()[status])
		return false
	
	# Check quality
	if item_quality < required_quality_min and not accepts_lower_quality():
		return false
	
	var old_state = status
	status = OrderStatus.COMPLETED
	actual_quality = item_quality
	actual_item_id = item_id
	
	order_state_changed.emit(old_state, status)
	order_updated.emit()
	return true

# Mark order as failed
func fail() -> void:
	if status == OrderStatus.COMPLETED or status == OrderStatus.FAILED:
		return
	
	var old_state = status
	status = OrderStatus.FAILED
	
	order_state_changed.emit(old_state, status)
	order_updated.emit()

# Mark order as expired
func expire() -> void:
	if status != OrderStatus.ACCEPTED and status != OrderStatus.IN_PROGRESS:
		return
	
	var old_state = status
	status = OrderStatus.EXPIRED
	
	order_state_changed.emit(old_state, status)
	order_updated.emit()

# --------------------------------
# Price calculations and negotiations
# --------------------------------

# Negotiate with customer
func negotiate_price(offered_price: int) -> bool:
	# Check if price is above limit
	if offered_price > price_limit:
		return false
	
	# Minimum price - 80% of base
	if offered_price < (base_price * 0.8):
		return false
	
	# Successful negotiation
	negotiated_price = offered_price
	order_updated.emit()
	return true

# Check if negotiation is possible
func can_negotiate() -> bool:
	# Can only negotiate for new orders
	return status == OrderStatus.NEW

# Calculate final price
func calculate_final_price(item_quality: int) -> int:
	# If price is already negotiated
	if negotiated_price > 0:
		return negotiated_price
	
	# Base case with quality consideration
	var quality_modifier = 1.0
	
	if item_quality > required_quality_min:
		# Bonus for exceeding quality (up to 20%)
		var quality_diff = item_quality - required_quality_min
		quality_modifier = 1.0 + min(quality_diff / 100.0, 0.2)
	elif item_quality < required_quality_min:
		# Penalty for insufficient quality
		quality_modifier = 0.8
	
	return int(base_price * quality_modifier)

# --------------------------------
# Item validation
# --------------------------------

# Check if item meets order requirements
# Base implementation
func validate_item(item: ItemData) -> bool:
	# Basic quality check
	if item.get_quality() < required_quality_min and not accepts_lower_quality():
		return false
	
	return true

# Check if order can be completed with lower quality
func accepts_lower_quality() -> bool:
	# By default, accept items within 10 quality points below requirement
	return required_quality_min - actual_quality <= 10

# --------------------------------
# Rewards and impacts
# --------------------------------

# Get money reward
func get_money_reward() -> int:
	if status != OrderStatus.COMPLETED:
		return 0
	
	if negotiated_price > 0:
		return negotiated_price
	
	return calculate_final_price(actual_quality)

# Get reputation impact
func get_reputation_impact() -> int:
	if status != OrderStatus.COMPLETED:
		return -abs(reputation_impact)  # Negative impact for non-completion
	
	# Bonus for quality
	if actual_quality > required_quality_min:
		var quality_bonus = (actual_quality - required_quality_min) / 10
		return reputation_impact + quality_bonus
	
	return reputation_impact

# Get prestige gain
func get_prestige_gain() -> int:
	if status != OrderStatus.COMPLETED:
		return 0
	
	# Base prestige gain
	var base_gain = prestige_gain
	
	# Modifier based on quality
	var quality_ratio = actual_quality / 100.0
	
	# Final prestige gain
	return int(base_gain * quality_ratio)

# --------------------------------
# Text representations
# --------------------------------

# Get order type name
func get_order_type_name() -> String:
	return OrderType.keys()[order_type]

# Get status name
func get_status_name() -> String:
	return OrderStatus.keys()[status]

# UI description
func get_ui_description() -> String:
	var desc = order_name + "\n"
	desc += "Status: " + get_status_name() + "\n"
	desc += "Customer: " + (customer_id if not customer_id.is_empty() else "Unknown") + "\n"
	desc += "Min. quality: " + str(required_quality_min) + "\n"
	desc += "Base price: " + str(base_price) + "\n"
	
	if status == OrderStatus.COMPLETED:
		desc += "Actual quality: " + str(actual_quality) + "\n"
		desc += "Reward received: " + str(get_money_reward()) + "\n"
	
	if not description.is_empty():
		desc += "\n" + description
	
	return desc
