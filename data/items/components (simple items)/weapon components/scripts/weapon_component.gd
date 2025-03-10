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

# Перевизначення методів для специфіки зброї
func get_base_prestige() -> int:
	match weapon_type:
		WeaponComponentType.SHORT_BLADE:
			return 40
		WeaponComponentType.LONG_BLADE:
			return 55
		WeaponComponentType.DAGGER_BLADE:
			return 35
		WeaponComponentType.MACE_HEAD:
			return 45
		WeaponComponentType.SPEAR_HEAD:
			return 50
		WeaponComponentType.WEAPON_HANDLE:
			return 30
		_:
			return 40

# Специфічна послідовність крафтингу для зброї
func start_crafting_minigame() -> void:
	# Запуск специфічних станків/міні-ігор для компонентів зброї
	pass
