extends Resource
class_name Order

# --------------------------------
# Core Enums for orders
# --------------------------------

enum OrderType {
	NONE,
	GENERAL,           # General order (only item type)
	SPECIFIC_COMPONENT, # Order with specific component
	SPECIFIC_ITEM      # Order for specific item
}

enum OrderStatus {
	NEW,               # New order
	ACCEPTED,          # Accepted for production
	IN_PROGRESS,       # Currently being crafted
	COMPLETED,         # Successfully completed
	FAILED,            # Failed to complete
	EXPIRED,           # Deadline missed
	CANCELED           # Canceled by customer or smith
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
@export var order_type: OrderType = OrderType.NONE
@export var required_quality_min: int = 0
@export var base_price: int = 0
@export var price_limit: int = 0  # Maximum price customer is willing to pay
@export var duration_days: int = 1  # Duration in days

# Reputation and prestige impact
@export_category("Reputation & Rewards")
@export var reputation_impact: int = 0  # Impact on smith's reputation (+/-)
@export var prestige_gain: int = 0      # Base prestige gain

# --------------------------------
# Internal properties
# --------------------------------

var order_id: String
var customer_id: String  # Customer identifier
var status: OrderStatus = OrderStatus.NEW

# Price and negotiations
var negotiated_price: int = 0  # Price after negotiations

# Result
var actual_quality: int = 0    # Actual quality of the item
var actual_item_id: String = "" # ID of the actual item

# --------------------------------
# Initialization methods
# --------------------------------

func _init() -> void:
	# Generate unique ID for the order if it doesn't exist
	if order_id.is_empty():
		order_id = _generate_order_id()
	
	# Set price limit if not set
	if price_limit <= 0:
		price_limit = int(base_price * 1.2)  # Default +20% to base price

# Generate unique ID for the order
func _generate_order_id() -> String:
	var time = Time.get_unix_time_from_system()
	var random = RandomNumberGenerator.new()
	random.randomize()
	var rand_num = random.randi_range(1000, 9999)
	return "ORD-%d-%d" % [time, rand_num]

# --------------------------------
# Order lifecycle management
# --------------------------------

# Accept order
func accept() -> void:
	if status != OrderStatus.NEW:
		push_warning("Cannot accept order with status " + OrderStatus.keys()[status])
		return
	
	var old_state = status
	status = OrderStatus.ACCEPTED
	
	# Time-related calculations should be in GameTime or another time-management class
	# Here we just notify about the state change
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")

# Start crafting the order
func start_crafting() -> void:
	if status != OrderStatus.ACCEPTED:
		push_warning("Cannot start crafting order with status " + OrderStatus.keys()[status])
		return
	
	var old_state = status
	status = OrderStatus.IN_PROGRESS
	
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")

# Complete the order
func complete(item_quality: int, item_id: String) -> bool:
	if status != OrderStatus.IN_PROGRESS:
		push_warning("Cannot complete order with status " + OrderStatus.keys()[status])
		return false
	
	# Check quality
	if item_quality < required_quality_min and not accepts_lower_quality():
		return false
	
	var old_state = status
	status = OrderStatus.COMPLETED
	actual_quality = item_quality
	actual_item_id = item_id
	
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")
	return true

# Mark order as failed
func fail() -> void:
	if status == OrderStatus.COMPLETED or status == OrderStatus.FAILED:
		return
	
	var old_state = status
	status = OrderStatus.FAILED
	
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")

# Cancel the order
func cancel() -> void:
	if status == OrderStatus.COMPLETED or status == OrderStatus.FAILED:
		return
	
	var old_state = status
	status = OrderStatus.CANCELED
	
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")

# Mark order as expired
func expire() -> void:
	if status != OrderStatus.ACCEPTED and status != OrderStatus.IN_PROGRESS:
		return
	
	var old_state = status
	status = OrderStatus.EXPIRED
	
	emit_signal("order_state_changed", old_state, status)
	emit_signal("order_updated")

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
	emit_signal("order_updated")
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
	# Specific calculations will be in subclasses
	return base_price

# --------------------------------
# Item validation
# --------------------------------

# Check if item meets order requirements
# Abstract method, must be overridden in subclasses
func validate_item(item: ItemData) -> bool:
	# Basic quality check
	if item.get_quality() < required_quality_min and not accepts_lower_quality():
		return false
	
	# Other checks are implemented in subclasses
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
# This method will be used by ReputationManager or another class
func get_reputation_impact() -> int:
	if status != OrderStatus.COMPLETED:
		return -abs(reputation_impact)  # Negative impact for non-completion
	
	# Bonus for quality
	if actual_quality > required_quality_min:
		var quality_bonus = (actual_quality - required_quality_min) / 10
		return reputation_impact + quality_bonus
	
	return reputation_impact

# Get prestige gain
# This method will be used by PrestigeManager or another class
func get_prestige_gain() -> int:
	if status != OrderStatus.COMPLETED:
		return 0
	
	# Base prestige gain
	var base_gain = prestige_gain
	
	# Modifier based on quality
	var quality_ratio = actual_quality / 100.0
	
	# Gain = (Item Prestige / Level Divisor)
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

# Detailed description - base implementation that can be expanded in subclasses
func get_detailed_description() -> String:
	var desc = "Order #" + order_id + ": " + order_name + "\n"
	desc += "Type: " + get_order_type_name() + "\n"
	desc += "Status: " + get_status_name() + "\n\n"
	
	desc += "Order details:\n"
	desc += "- Minimum quality: " + str(required_quality_min) + "\n"
	desc += "- Base price: " + str(base_price) + " coins\n"
	desc += "- Price limit: " + str(price_limit) + " coins\n"
	if negotiated_price > 0:
		desc += "- Negotiated price: " + str(negotiated_price) + " coins\n"
	desc += "- Duration: " + str(duration_days) + " days\n"
	
	desc += "\nImpacts:\n"
	desc += "- Reputation impact: " + str(reputation_impact) + "\n"
	desc += "- Prestige gain: " + str(prestige_gain) + "\n"
	
	if status == OrderStatus.COMPLETED:
		desc += "\nResult:\n"
		desc += "- Actual quality: " + str(actual_quality) + "\n"
		desc += "- Reward paid: " + str(get_money_reward()) + " coins\n"
	
	if not description.is_empty():
		desc += "\nDescription:\n" + description
	
	return desc
