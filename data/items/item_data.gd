extends Resource
class_name ItemData

enum Category {
	TOOLS,          # Інструменти
	ARMOR,          # Обладунки
	WEAPONS         # Зброя
}

enum CreationDifficulty {
	HOUSEHOLD = 1,  # Господарський (0.8)
	BASIC = 2,      # Базовий (0.9)
	MILITARY = 3,   # Військовий (1.0)
	ELITE = 4       # Елітний (1.1)
}

@export var name: String
@export var description: String = ""
@export var creation_difficulty: CreationDifficulty = CreationDifficulty.BASIC
@export var produced_quantity: int = 1
@export var component_slots: Array[Slot] = []

const PRESTIGE_LOW_QUALITY: int = 30
const PRESTIGE_MEDIUM_QUALITY: int = 40
const PRESTIGE_HIGH_QUALITY: int = 60

var quality: float = 0.0  # 0-100
var prestige: float = 0.0
var base_price: int = 0
var required_craftsman_level: Enums.CraftsmanLevel

# Базові методи
func calculate_quality() -> float:
	return 0.0  # Перевизначається в дочірніх класах

func calculate_prestige() -> float:
	return 0.0  # Перевизначається в дочірніх класах

func get_selling_price(forge_premium: float = 0.0) -> int:
	return base_price + int(base_price * forge_premium)
