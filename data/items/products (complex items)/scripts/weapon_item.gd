extends ComplexItem
class_name WeaponItem

enum WeaponType {
	ONE_HANDED_SWORD,
	SABER,
	LONG_SWORD,
	POLE_WEAPON,
	HEAVY_WEAPON,
	DAGGER
}

@export var weapon_type: WeaponType

# Перевизначення методу для запуску міні-гри збірки
func start_assembly_minigame() -> void:
	print("Запуск міні-гри збірки зброї типу: ", weapon_type)
	
	match weapon_type:
		WeaponType.ONE_HANDED_SWORD:
			print("Складання одноручного меча")
		WeaponType.SABER:
			print("Складання шаблі")
		WeaponType.LONG_SWORD:
			print("Складання дворучного меча")
		WeaponType.POLE_WEAPON:
			print("Складання двогострої зброї")
		WeaponType.HEAVY_WEAPON:
			print("Складання важкої зброї")
		WeaponType.DAGGER:
			print("Складання кинджала")
