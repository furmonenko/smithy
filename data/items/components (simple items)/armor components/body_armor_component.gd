extends ArmorComponent
class_name BodyArmorComponent 

# Підтипи компонентів захисту тіла
enum BodyArmorType {
	TORSO_ARMOR,  # Нагрудник, кіраса
	BODY_LINER,   # Підкладка під броню
	LIMB_LINER,   # Підкладка для кінцівок
	ARMS_ARMOR,   # Захист рук
	LEGS_ARMOR    # Захист ніг
}

@export var body_armor_type: BodyArmorType

func initialize_subcategory_materials() -> void:
	match body_armor_type:
		BodyArmorType.TORSO_ARMOR:
			subcategory_materials = {
				Enums.MaterialType.METAL: 5
			}
		
		BodyArmorType.ARMS_ARMOR:
			subcategory_materials = {
				Enums.MaterialType.METAL: 3
			}
		
		BodyArmorType.LEGS_ARMOR:
			subcategory_materials = {
				Enums.MaterialType.METAL: 4
			}
		
		BodyArmorType.BODY_LINER:
			subcategory_materials = {
				Enums.MaterialType.FABRIC: 2,
				Enums.MaterialType.LEATHER: 1
			}
		
		BodyArmorType.LIMB_LINER:
			subcategory_materials = {
				Enums.MaterialType.FABRIC: 1
			}

# Специфічна послідовність крафтингу для компонентів броні тіла
func start_crafting_minigame() -> void:
	match body_armor_type:
		BodyArmorType.TORSO_ARMOR:
			# Запуск послідовності: вирізання -> кування -> полірування
			print("Запуск послідовності станків для нагрудника: вирізання -> кування -> полірування")
		BodyArmorType.ARMS_ARMOR, BodyArmorType.LEGS_ARMOR:
			# Запуск послідовності: вирізання -> кування -> з'єднання
			print("Запуск послідовності станків для захисту кінцівок: вирізання -> кування -> з'єднання")
		BodyArmorType.BODY_LINER, BodyArmorType.LIMB_LINER:
			# Запуск послідовності: крій -> стьобання -> шиття
			print("Запуск послідовності станків для підкладки: крій -> стьобання -> шиття")
