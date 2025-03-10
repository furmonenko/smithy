extends WeaponComponent
class_name HeavyWeaponComponent

# Підтипи компонентів важкої зброї
enum HeavyWeaponType {
	HEAVY_WEAPON_HEAD,
	HEAVY_WEAPON_HANDLE
}

@export var heavy_weapon_type: HeavyWeaponType

func start_crafting_minigame() -> void:
	match heavy_weapon_type:
		HeavyWeaponType.HEAVY_WEAPON_HEAD:
			print("Запуск послідовності станків для голови важкої зброї: лиття -> кування -> обробка")
		HeavyWeaponType.HEAVY_WEAPON_HANDLE:
			print("Запуск послідовності станків для руків'я важкої зброї: обробка дерева -> посилення")
