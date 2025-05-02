extends ComponentRecipe
class_name MaterialComponentRecipe 

enum MaterialComponentRecipeType {
	USABLE,    # Компоненти, що використовуються у складанні
	UNUSABLE   # Компоненти, що не використовуються у складанні
}

@export var material_component_type: MaterialComponentRecipeType

func start_crafting_minigame() -> void:
	print("Запуск міні-гри створення матеріального компонента типу: ", material_component_type)
	
	match material_component_type:
		MaterialComponentRecipeType.USABLE:
			print("Створення використовуваного матеріалу")
		MaterialComponentRecipeType.UNUSABLE:
			print("Створення невикористовуваного матеріалу")
