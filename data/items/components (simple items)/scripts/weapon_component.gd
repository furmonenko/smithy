extends SimpleItem
class_name WeaponComponent

enum WeaponComponentType {
	SHORT_BLADE,
	LONG_BLADE,
	DAGGER_BLADE,
	MACE_HEAD,
	SPEAR_HEAD,
	WEAPON_HANDLE
}

@export var weapon_type: WeaponComponentType

# Специфічна послідовність крафтингу для зброї
func start_crafting_minigame() -> void:
	# Запуск специфічних станків/міні-ігор для компонентів зброї
	pass
