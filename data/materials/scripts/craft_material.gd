extends Resource
class_name CraftMaterial

@export var name: String
@export var quality: int  # 0-100
@export var cost: int  # вартість у грошах
@export var rarity: Enums.Rarity 
@export var required_level: Enums.CraftsmanLevel
@export var material_type: Enums.MaterialType
@export var is_combinable: bool  # Комбінаційний чи ні

func get_base_prestige_by_quality(quality_value: int) -> int:
	# Логіка з таблиці категорій якості
	if quality_value >= 0 and quality_value <= 49:
		return 30
	elif quality_value >= 50 and quality_value <= 79:
		return 50
	elif quality_value >= 80 and quality_value <= 100:
		return 70
	return 0
