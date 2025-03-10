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
