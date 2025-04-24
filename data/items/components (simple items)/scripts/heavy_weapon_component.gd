extends WeaponComponent
class_name HeavyWeaponComponent

# Підтипи компонентів важкої зброї
enum HeavyWeaponType {
	HEAVY_WEAPON_HEAD,
	HEAVY_WEAPON_HANDLE
}

@export var heavy_weapon_type: HeavyWeaponType

func initialize_subcategory_materials() -> void:
	match heavy_weapon_type:
		HeavyWeaponType.HEAVY_WEAPON_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 3
			}
		
		HeavyWeaponType.HEAVY_WEAPON_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 1,
				Enums.MaterialType.LEATHER: 1,
				Enums.MaterialType.METAL: 1
			}

func start_crafting_minigame() -> void:
	match heavy_weapon_type:
		HeavyWeaponType.HEAVY_WEAPON_HEAD:
			print("Запуск послідовності станків для голови важкої зброї: лиття -> кування -> обробка")
		HeavyWeaponType.HEAVY_WEAPON_HANDLE:
			print("Запуск послідовності станків для руків'я важкої зброї: обробка дерева -> посилення")
