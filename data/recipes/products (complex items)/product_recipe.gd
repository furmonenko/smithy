extends Recipe
class_name ProductRecipe

signal component_added(component: ComponentRecipe, slot_index: int)
signal component_removed(component: ComponentRecipe, slot_index: int)

# Create a product item from this recipe
func create_item() -> ProductItem:
	var item = ProductItem.new()
	item.recipe = self
	item.name = name
	item.description = description
	item.category = get_category()
	item.creation_difficulty = creation_difficulty
	
	# Set base values
	item.base_price = calculate_base_price()
	
	return item

# Utility methods for component management
func assign_component_to_slot(slot_index: int, component: ComponentRecipe) -> bool:
	if slot_index < 0 or slot_index >= component_slots.size():
		return false
	
	var slot = component_slots[slot_index]
	
	if slot.assign_component(component):
		emit_signal("component_added", component, slot_index)
		return true
	
	return false

func remove_component_from_slot(slot_index: int, component_index: int) -> ComponentRecipe:
	if slot_index < 0 or slot_index >= component_slots.size():
		return null
	
	var slot = component_slots[slot_index]
	var component = slot.remove_component(component_index)
	
	if component != null:
		emit_signal("component_removed", component, slot_index)
	
	return component

# Check if all required components are assigned
func are_all_required_components_assigned() -> bool:
	for slot in component_slots:
		if slot.is_required and not slot.is_filled():
			return false
	return true
