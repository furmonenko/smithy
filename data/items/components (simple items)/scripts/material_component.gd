extends SimpleItem
class_name MaterialComponent 

enum MaterialComponentType {
	USABLE,    # Компоненти, що використовуються у складанні
	UNUSABLE   # Компоненти, що не використовуються у складанні
}

@export var material_component_type: MaterialComponentType

func start_crafting_minigame() -> void:
	print("Запуск міні-гри створення матеріального компонента типу: ", material_component_type)
	
	match material_component_type:
		MaterialComponentType.USABLE:
			print("Створення використовуваного матеріалу")
		MaterialComponentType.UNUSABLE:
			print("Створення невикористовуваного матеріалу")
