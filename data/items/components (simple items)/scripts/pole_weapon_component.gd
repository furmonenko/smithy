extends WeaponComponent
class_name PoleWeaponComponent

# Підтипи компонентів важкої зброї
enum PoleWeaponType {
	POLE_HEAD,
	POLE_HANDLE
}

@export var pole_weapon_type :PoleWeaponType

func initialize_subcategory_materials() -> void:
	match pole_weapon_type:
		PoleWeaponType.POLE_HEAD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 3
			}
		
		PoleWeaponType.POLE_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 3,
				Enums.MaterialType.LEATHER: 1
			}
