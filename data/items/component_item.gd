extends Item
class_name ComponentItem

# Calculate the quality of this component based on materials and execution
func calculate_quality(mini_game_result: float, station_efficiency: float, player_skill: float) -> float:
	# 1. Розрахунок зваженої середньої якості матеріалів
	var weighted_quality_sum = 0.0
	var total_weight = 0
	
	for slot in recipe.component_slots:
		if slot.is_filled():
			weighted_quality_sum += slot.assigned_material.quality * slot.weight * slot.quantity
			total_weight += slot.weight * slot.quantity
	
	if total_weight == 0:
		return 0.0
	
	var weighted_avg_quality = weighted_quality_sum / total_weight
	
	# 2. Розрахунок ефективності виконання
	var execution_efficiency = (mini_game_result * station_efficiency * player_skill) / 100.0
	
	# 3. Розрахунок фактичної якості
	var final_quality = weighted_avg_quality * execution_efficiency * recipe.get_complexity_coefficient()
	
	# Store the calculated quality
	quality = final_quality
	
	# Also calculate and store prestige
	prestige = calculate_prestige()
	
	return final_quality
