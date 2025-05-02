extends ComponentRecipe
class_name ToolComponentRecipe

enum ToolComponentRecipeType {
	AXE_HEAD,
	HAND_HOE_HEAD,
	SCYTHE_HEAD,
	HAMMER_HEAD,
	SHOVEL_HEAD,
	PICKAXE_HEAD,
	TOOL_HANDLE
}

@export var tool_type: ToolComponentRecipeType

func initialize_subcategory_materials() -> void:
	match tool_type:
		ToolComponentRecipeType.AXE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentRecipeType.HAND_HOE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentRecipeType.SCYTHE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentRecipeType.SHOVEL_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentRecipeType.PICKAXE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentRecipeType.TOOL_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 2
			}

# Перевизначення методів для специфіки інструментів
func get_base_prestige() -> int:
	match tool_type:
		ToolComponentRecipeType.AXE_HEAD:
			return 25
		ToolComponentRecipeType.HAMMER_HEAD:
			return 30
		ToolComponentRecipeType.SHOVEL_HEAD:
			return 20
		ToolComponentRecipeType.PICKAXE_HEAD:
			return 35
		ToolComponentRecipeType.TOOL_HANDLE:
			return 15
		_:
			return 20

# Специфічна послідовність крафтингу для інструментів
func start_crafting_minigame() -> void:
	# Запуск специфічних станків/міні-ігор для компонентів інструментів
	if tool_type == ToolComponentRecipeType.AXE_HEAD or tool_type == ToolComponentRecipeType.HAMMER_HEAD:
		# Запуск міні-гри кування
		print("Запуск міні-гри кування для компонента інструмента")
	elif tool_type == ToolComponentRecipeType.TOOL_HANDLE:
		# Запуск міні-гри обробки дерева
		print("Запуск міні-гри обробки дерева для руків'я")
