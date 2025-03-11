extends ArmorComponent
class_name HeadArmorComponent

# Підтипи компонентів захисту голови
enum HeadArmorType {
	DOME,       # Основна частина шолома
	VISOR,      # Забрало/візор
	HEAD_LINER  # Підкладка шолома
}

@export var head_armor_type: HeadArmorType

func initialize_subcategory_materials() -> void:
	match head_armor_type:
		HeadArmorType.DOME:
			subcategory_materials = {
				Enums.MaterialType.METAL: 3
			}
		
		HeadArmorType.VISOR:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		HeadArmorType.HEAD_LINER:
			subcategory_materials = {
				Enums.MaterialType.FABRIC: 1,
				Enums.MaterialType.LEATHER: 1
			}

# Специфічна послідовність крафтингу для компонентів шолома
func start_crafting_minigame() -> void:
	match head_armor_type:
		HeadArmorType.DOME:
			# Запуск послідовності: вирізання -> кування -> полірування
			print("Запуск послідовності станків для купола шолома: вирізання -> кування -> полірування")
		HeadArmorType.VISOR:
			# Запуск послідовності: вирізання -> кування -> шліфування
			print("Запуск послідовності станків для забрала: вирізання -> кування -> шліфування")
		HeadArmorType.HEAD_LINER:
			# Запуск послідовності: крій -> шиття
			print("Запуск послідовності станків для підкладки шолома: крій -> шиття")
