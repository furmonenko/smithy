extends MaterialComponent
class_name UsableMaterialComponent 

enum UsableMaterialType {
	WIRE,           # Дріт
	METAL_RING,     # Металеве кільце
	CHAINMAIL_PIECE, # Частина кольчуги
	METAL_PLATE,    # Металева пластина
}

@export var usable_material_type: UsableMaterialType

func _init() -> void:
	material_component_type = MaterialComponentType.USABLE

func start_crafting_minigame() -> void:
	print("Запуск міні-гри створення використовуваного матеріалу типу: ", usable_material_type)
	
	match usable_material_type:
		UsableMaterialType.WIRE:
			print("Створення дроту")
		UsableMaterialType.METAL_RING:
			print("Створення металевого кільця")
		UsableMaterialType.CHAINMAIL_PIECE:
			print("Створення елемента кольчуги")
		UsableMaterialType.METAL_PLATE:
			print("Створення металевої пластини")

# Метод для ініціалізації матеріалів підкатегорії
func initialize_subcategory_materials() -> void:
	match usable_material_type:
		UsableMaterialType.WIRE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 1
			}
		
		UsableMaterialType.METAL_RING:
			subcategory_materials = {
				Enums.MaterialType.CREATED: 1  # Wire
			}
		
		UsableMaterialType.CHAINMAIL_PIECE:
			subcategory_materials = {
				Enums.MaterialType.CREATED: 5  # Metal Ring
			}
		
		UsableMaterialType.METAL_PLATE:
			subcategory_materials = {
				Enums.MaterialType.METAL: 2
			}
