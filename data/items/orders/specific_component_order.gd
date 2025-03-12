# specific_component_order.gd
extends Order
class_name SpecificComponentOrder

@export var required_item_type: Script  # Наприклад, "Dagger"
@export var required_component: String  # Наприклад, "Grip Dagger Handle"

func _init() -> void:
	order_type = OrderType.SPECIFIC_COMPONENT
	super()
