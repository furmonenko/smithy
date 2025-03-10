extends ArmorItem
class_name BodyArmorItem 

enum BodyArmorType {
	TORSO_ARMOR,
	CHAINMAIL,
	ARMS_ARMOR,
	LEGS_ARMOR
}

@export var body_armor_type: BodyArmorType

# Перевизначення методу для запуску міні-гри збірки
func start_assembly_minigame() -> void:
	print("Запуск міні-гри збірки броні для тіла типу: ", body_armor_type)
	
	match body_armor_type:
		BodyArmorType.TORSO_ARMOR:
			print("Складання нагрудної броні")
		BodyArmorType.CHAINMAIL:
			print("Складання кольчуги")
		BodyArmorType.ARMS_ARMOR:
			print("Складання наруків")
		BodyArmorType.LEGS_ARMOR:
			print("Складання поножів")

# Метод для налаштування слотів компонентів
func setup_component_slots() -> void:
	component_slots.clear()
	
	# Головний слот для основної частини
	var main_slot = ComponentSlot.new()
	main_slot.quantity = 1
	main_slot.weight = 3
	main_slot.is_required = true
	
	var body_component = BodyArmorComponent.new()
	
	match body_armor_type:
		BodyArmorType.TORSO_ARMOR:
			body_component.body_armor_type = BodyArmorComponent.BodyArmorType.TORSO_ARMOR
		# BodyArmorType.CHAINMAIL:
			# body_component.body_armor_type = BodyArmorComponent.BodyArmorType.CHAINMAIL
		BodyArmorType.ARMS_ARMOR:
			body_component.body_armor_type = BodyArmorComponent.BodyArmorType.ARMS_ARMOR
		BodyArmorType.LEGS_ARMOR:
			body_component.body_armor_type = BodyArmorComponent.BodyArmorType.LEGS_ARMOR
	
	main_slot.allowed_component = body_component
	component_slots.append(main_slot)
	
	# Додаємо підкладку для всіх типів
	var liner_slot = ComponentSlot.new()
	liner_slot.quantity = 1
	liner_slot.weight = 1
	liner_slot.is_required = true
	
	var liner_component = BodyArmorComponent.new()
	
	match body_armor_type:
		BodyArmorType.TORSO_ARMOR:
			liner_component.body_armor_type = BodyArmorComponent.BodyArmorType.BODY_LINER
		BodyArmorType.ARMS_ARMOR, BodyArmorType.LEGS_ARMOR:
			liner_component.body_armor_type = BodyArmorComponent.BodyArmorType.LIMB_LINER
		_:
			liner_component.body_armor_type = BodyArmorComponent.BodyArmorType.BODY_LINER
	
	liner_slot.allowed_component = liner_component
	component_slots.append(liner_slot)
