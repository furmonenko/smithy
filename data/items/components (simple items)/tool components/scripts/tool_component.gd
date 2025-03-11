extends SimpleItem
class_name ToolComponent

enum ToolComponentType {
	AXE_HEAD,
	HAND_HOE_HEAD,
	SCYTHE_HEAD,
	HAMMER_HEAD,
	SHOVEL_HEAD,
	PICKAXE_HEAD,
	TOOL_HANDLE
}

@export var tool_type: ToolComponentType

func initialize_subcategory_materials() -> void:
	match tool_type:
		ToolComponentType.AXE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentType.HAND_HOE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentType.SCYTHE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentType.SHOVEL_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentType.PICKAXE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		ToolComponentType.TOOL_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 2
			}

# Перевизначення методів для специфіки інструментів
func get_base_prestige() -> int:
	match tool_type:
		ToolComponentType.AXE_HEAD:
			return 25
		ToolComponentType.HAMMER_HEAD:
			return 30
		ToolComponentType.SHOVEL_HEAD:
			return 20
		ToolComponentType.PICKAXE_HEAD:
			return 35
		ToolComponentType.TOOL_HANDLE:
			return 15
		_:
			return 20

# Специфічна послідовність крафтингу для інструментів
func start_crafting_minigame() -> void:
	# Запуск специфічних станків/міні-ігор для компонентів інструментів
	if tool_type == ToolComponentType.AXE_HEAD or tool_type == ToolComponentType.HAMMER_HEAD:
		# Запуск міні-гри кування
		print("Запуск міні-гри кування для компонента інструмента")
	elif tool_type == ToolComponentType.TOOL_HANDLE:
		# Запуск міні-гри обробки дерева
		print("Запуск міні-гри обробки дерева для руків'я")
