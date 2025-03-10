extends ComplexItem
class_name ToolItem 

enum ToolType {
	AXE,
	HAND_HOE,
	SCYTHE,
	SHOVEL,
	PICKAXE
}

@export var tool_type: ToolType

# Перевизначення методу для запуску міні-гри збірки
func start_assembly_minigame() -> void:
	print("Запуск міні-гри збірки інструмента типу: ", tool_type)
	
	# Тут буде різна логіка для різних типів інструментів
	match tool_type:
		ToolType.AXE:
			print("Складання сокири")
		ToolType.HAND_HOE:
			print("Складання мотики")
		ToolType.SCYTHE:
			print("Складання коси")
		ToolType.SHOVEL:
			print("Складання лопати")
		ToolType.PICKAXE:
			print("Складання кирки")

# Метод для налаштування слотів компонентів на основі типу інструменту
func setup_component_slots() -> void:
	pass
