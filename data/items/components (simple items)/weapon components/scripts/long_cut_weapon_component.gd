extends WeaponComponent
class_name LongCutWeaponComponent

# Підтипи компонентів дворучної ріжучої зброї
enum LongCutWeaponType {
	LONG_SWORD_BLADE,
	LONG_SWORD_GUARD,
	LONG_SWORD_POMMEL,
	LONG_SWORD_HANDLE
}

@export var long_cut_weapon_type: LongCutWeaponType

func initialize_subcategory_materials() -> void:
	match long_cut_weapon_type:
		LongCutWeaponType.LONG_SWORD_BLADE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 7
			}
		
		LongCutWeaponType.LONG_SWORD_GUARD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		LongCutWeaponType.LONG_SWORD_POMMEL:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
		
		LongCutWeaponType.LONG_SWORD_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 2,
				Enums.MaterialType.LEATHER: 1
			}

func start_crafting_minigame() -> void:
	match long_cut_weapon_type:
		LongCutWeaponType.LONG_SWORD_BLADE:
			print("Запуск послідовності станків для довгого леза: кування -> гартування -> заточування")
		LongCutWeaponType.LONG_SWORD_GUARD:
			print("Запуск послідовності станків для гарди дворучного меча: кування -> обробка")
		LongCutWeaponType.LONG_SWORD_POMMEL:
			print("Запуск послідовності станків для навершя дворучного меча: лиття -> обробка")
		LongCutWeaponType.LONG_SWORD_HANDLE:
			print("Запуск послідовності станків для руків'я дворучного меча: обробка дерева -> обмотка")
