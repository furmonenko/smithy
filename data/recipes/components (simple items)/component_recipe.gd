extends Recipe
class_name ComponentRecipe

var subcategory_materials: Dictionary

# Initialize subcategory materials
func initialize_subcategory_materials() -> void:
	# Will be overridden in subclasses
	subcategory_materials = {}

# Calculate price for a desired quality level
func calculate_price_for_quality(desired_quality: int) -> int:
	var total_price = 0
	
	for material_type in subcategory_materials.keys():
		var quantity = subcategory_materials[material_type]
		var material = CraftMaterialsManager.get_cheapest_material_by_type_and_quality(material_type, desired_quality)
	
		if material:
			total_price += material.cost * quantity
	
	return total_price

# Calculate material cost estimate (for pricing system)
func calculate_material_cost_estimate(desired_quality: int) -> int:
	return calculate_price_for_quality(desired_quality)

# Create a component item from this recipe, with additional processing
func create_item() -> ComponentItem:
	var item = ComponentItem.new()
	item.recipe = self
	item.name = name
	item.description = description
	item.category = get_category()
	item.creation_difficulty = creation_difficulty
	
	# Set base values
	item.base_price = calculate_base_price()
	
	return item
