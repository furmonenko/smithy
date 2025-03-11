extends WeaponComponent
class_name OneHandedCutWeaponComponent

# Підтипи компонентів одноручної ріжучої зброї
enum OneHandedCutWeaponType {
	ONE_HANDED_SWORD_BLADE,
	SABER_BLADE,
	ONE_HANDED_GUARD,
	ONE_HANDED_POMMEL,
	ONE_HANDED_HANDLE
}

@export var one_handed_cut_weapon_type: OneHandedCutWeaponType

func initialize_subcategory_materials() -> void:
	match one_handed_cut_weapon_type:
		OneHandedCutWeaponType.ONE_HANDED_SWORD_BLADE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 4
			}
		
		OneHandedCutWeaponType.SABER_BLADE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 4
			}
		
		OneHandedCutWeaponType.ONE_HANDED_GUARD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
		
		OneHandedCutWeaponType.ONE_HANDED_POMMEL:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
		
		OneHandedCutWeaponType.ONE_HANDED_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 1,
				Enums.MaterialType.LEATHER: 1
			}

func start_crafting_minigame() -> void:
	match one_handed_cut_weapon_type:
		OneHandedCutWeaponType.ONE_HANDED_SWORD_BLADE, OneHandedCutWeaponType.SABER_BLADE:
			print("Запуск послідовності станків для леза: кування -> гартування -> заточування")
		OneHandedCutWeaponType.ONE_HANDED_GUARD:
			print("Запуск послідовності станків для гарди: кування -> обробка")
		OneHandedCutWeaponType.ONE_HANDED_POMMEL:
			print("Запуск послідовності станків для навершя: лиття -> обробка")
		OneHandedCutWeaponType.ONE_HANDED_HANDLE:
			print("Запуск послідовності станків для руків'я: обробка дерева -> обмотка")
