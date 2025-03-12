extends Order
class_name GeneralOrder

# Замовлення для певної категорії виробу
@export var item_category: ItemData
@export var creation_difficulty: ItemData.CreationDifficulty

func _init() -> void:
	order_type = OrderType.GENERAL
	super()

# Локалізований опис для UI
func get_ui_description() -> String:
	var desc = super.get_ui_description()
	
	desc += "\nТип: "
	match item_category:
		ItemData.Category.TOOLS:
			desc += "Інструмент"
		ItemData.Category.WEAPONS:
			desc += "Зброя"
		ItemData.Category.ARMOR:
			desc += "Броня"
	
	desc += "\nСкладність: "
	match creation_difficulty:
		ItemData.CreationDifficulty.HOUSEHOLD:
			desc += "Господарський"
		ItemData.CreationDifficulty.BASIC:
			desc += "Базовий"
		ItemData.CreationDifficulty.MILITARY:
			desc += "Військовий"
		ItemData.CreationDifficulty.ELITE:
			desc += "Елітний"
	
	return desc
