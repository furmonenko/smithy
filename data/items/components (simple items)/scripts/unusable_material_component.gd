extends MaterialComponent
class_name UnusableMaterialComponent 

enum UnusableMaterialType {
	NAILS,       # Цвяхи
	HORSESHOE    # Підкова
}

@export var unusable_material_type: UnusableMaterialType

func _init() -> void:
	material_component_type = MaterialComponentType.UNUSABLE

func start_crafting_minigame() -> void:
	print("Запуск міні-гри створення невикористовуваного матеріалу типу: ", unusable_material_type)
	
	match unusable_material_type:
		UnusableMaterialType.NAILS:
			print("Створення цвяхів")
		UnusableMaterialType.HORSESHOE:
			print("Створення підкови")

# Метод для ініціалізації матеріалів підкатегорії
func initialize_subcategory_materials() -> void:
	match unusable_material_type:
		UnusableMaterialType.NAILS:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
		
		UnusableMaterialType.HORSESHOE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
