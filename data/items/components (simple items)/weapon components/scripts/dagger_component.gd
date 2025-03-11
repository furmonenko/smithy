extends WeaponComponent
class_name DaggerComponent 

# Підтипи компонентів кинджалів
enum DaggerType {
	DAGGER_BLADE,
	DAGGER_HANDLE,
	DAGGER_POMMEL,
	DAGGER_GUARD
}

@export var dagger_type: DaggerType

func initialize_subcategory_materials() -> void:
	match dagger_type:
		DaggerType.DAGGER_BLADE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 3
			}
		
		DaggerType.DAGGER_HANDLE:
			subcategory_materials = {
				Enums.MaterialType.WOOD: 1,
				Enums.MaterialType.LEATHER: 1
			}
		
		DaggerType.DAGGER_POMMEL:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
		
		DaggerType.DAGGER_GUARD:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}

func start_crafting_minigame() -> void:
	match dagger_type:
		DaggerType.DAGGER_BLADE:
			print("Запуск послідовності станків для леза кинджала: кування -> гартування -> заточування")
		DaggerType.DAGGER_HANDLE:
			print("Запуск послідовності станків для руків'я кинджала: обробка -> обмотка")
		DaggerType.DAGGER_POMMEL:
			print("Запуск послідовності станків для навершя кинджала: лиття -> обробка")
		DaggerType.DAGGER_GUARD:
			print("Запуск послідовності станків для гарди кинджала: кування -> обробка")
