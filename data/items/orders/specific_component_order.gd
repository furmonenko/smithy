# specific_component_order.gd
extends Order
class_name SpecificComponentOrder

# @export var required_item_type: ItemData.
@export var required_component: SimpleItem  # Наприклад, "Grip Dagger Handle"

func _init() -> void:
	order_type = OrderType.SPECIFIC_COMPONENT
	super()
