# HeadArmorItem.gd
class_name HeadArmorItem extends ArmorItem

enum HeadArmorType {
	WITHOUT_VISOR,
	WITH_VISOR,
	COIF
}

@export var head_armor_type: HeadArmorType

# Перевизначення методу для запуску міні-гри збірки
func start_assembly_minigame() -> void:
	print("Запуск міні-гри збірки броні для голови типу: ", head_armor_type)
	
	match head_armor_type:
		HeadArmorType.WITHOUT_VISOR:
			print("Складання шолома без забрала")
		HeadArmorType.WITH_VISOR:
			print("Складання шолома з забралом")
		HeadArmorType.COIF:
			print("Складання койфа")

# Метод для налаштування слотів компонентів
func setup_component_slots() -> void:
	component_slots.clear()
	
	# Головний слот для купола шолома
	var dome_slot = ComponentSlot.new()
	dome_slot.quantity = 1
	dome_slot.weight = 3
	dome_slot.is_required = true
	
	var dome_component = HeadArmorComponent.new()
	dome_component.head_armor_type = HeadArmorComponent.HeadArmorType.DOME
	dome_slot.allowed_component = dome_component
	
	component_slots.append(dome_slot)
	
	# Додаємо забрало для типу WITH_VISOR
	if head_armor_type == HeadArmorType.WITH_VISOR:
		var visor_slot = ComponentSlot.new()
		visor_slot.quantity = 1
		visor_slot.weight = 2
		visor_slot.is_required = true
		
		var visor_component = HeadArmorComponent.new()
		visor_component.head_armor_type = HeadArmorComponent.HeadArmorType.VISOR
		visor_slot.allowed_component = visor_component
		
		component_slots.append(visor_slot)
	
	# Додаємо підкладку для всіх типів
	var liner_slot = ComponentSlot.new()
	liner_slot.quantity = 1
	liner_slot.weight = 1
	liner_slot.is_required = true
	
	var liner_component = HeadArmorComponent.new()
	liner_component.head_armor_type = HeadArmorComponent.HeadArmorType.HEAD_LINER
	liner_slot.allowed_component = liner_component
	
	component_slots.append(liner_slot)
