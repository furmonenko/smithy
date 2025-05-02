extends Item
class_name ProductItem

# Assembly quality from minigame results
var assembly_quality: float = 0.0

# Calculate the quality of this product based on components and assembly
func calculate_quality() -> float:
	if not recipe.are_all_required_components_assigned():
		return 0.0
		
	var avg_quality = calculate_average_weighted_quality()
	
	# Store the calculated quality
	quality = avg_quality * assembly_quality * recipe.get_complexity_coefficient()
	
	# Also calculate and store prestige
	prestige = calculate_prestige()
	
	return quality

# Calculate the average weighted quality of components
func calculate_average_weighted_quality() -> float:
	var total_quality_weight = 0.0
	var total_weight = 0.0
	
	for i in range(recipe.component_slots.size()):
		var slot = recipe.component_slots[i]
		
		if slot.is_filled():
			var slot_quality = slot.quality
			var weight = slot.weight
			var quantity = slot.quantity
			
			total_quality_weight += slot_quality * weight * quantity
			total_weight += weight * quantity
	
	if total_weight == 0:
		return 0.0
	
	return total_quality_weight / total_weight

# Calculate prestige for a complex item
func calculate_prestige() -> float:
	if not recipe.are_all_required_components_assigned():
		return 0.0
	
	# Weighted prestige calculation from components
	var weighted_prestige_sum = 0.0
	var total_weight = 0.0
	
	for i in range(recipe.component_slots.size()):
		var slot = recipe.component_slots[i]
		
		if slot.is_filled() and components.size() > i:
			var component_prestige = components[i].get_prestige()
			weighted_prestige_sum += component_prestige * slot.weight * slot.quantity
			total_weight += slot.weight * slot.quantity
	
	if total_weight == 0:
		return 0.0
	
	var weighted_avg_prestige = weighted_prestige_sum / total_weight
	
	# Apply complexity coefficient and assembly quality bonus
	return weighted_avg_prestige * recipe.get_complexity_coefficient() * (1.0 + assembly_quality)

# Set assembly quality from minigame results
func set_assembly_quality(quality: float) -> void:
	assembly_quality = clamp(quality, 0.0, 1.0)
	# Recalculate final quality and prestige
	calculate_quality()
