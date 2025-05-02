extends ComponentRecipe
class_name WeaponComponentRecipe

enum WeaponComponentRecipeType {
	SHORT_BLADE,
	LONG_BLADE,
	DAGGER_BLADE,
	MACE_HEAD,
	SPEAR_HEAD,
	WEAPON_HANDLE
}

@export var weapon_type: WeaponComponentRecipeType

# Специфічна послідовність крафтингу для зброї
func start_crafting_minigame() -> void:
	# Запуск специфічних станків/міні-ігор для компонентів зброї
	pass
