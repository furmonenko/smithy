extends Node

enum MaterialType {
	METAL,
	WOOD,
	FABRIC,
	LEATHER,
	DECORATION,
	CREATED
}

enum Rarity {
	COMMON,         # Звичайний
	WIDESPREAD,     # Поширений
	UNCOMMON,       # Малопоширений
	RARE,           # Рідкісний
	VERY_RARE,      # Дуже рідкісний
	LEGENDARY       # Легендарний
}

enum CraftsmanLevel {
	APPRENTICE,     # Учень
	JOURNEYMAN,     # Підмайстер
	BLACKSMITH,     # Коваль
	MASTER_SMITH,   # Майстер-коваль
	MASTER_ARMORER  # Майстер-зброяр
}

enum ForgeLevel {
	UNKNOWN,        # Невідома
	LOCAL,          # Місцева
	RESPECTED,      # Поважна
	KNOWN,          # Відома
	MASTERFUL,      # Майстерна
	ELITE,          # Еліта
	LEGENDARY       # Легендарна
}
