# GeneralOrder.gd - General order for a specific category of items
extends Order
class_name GeneralOrder

# Properties for the order - we use enums from the ItemData class
@export var item_category: ItemData.Category  # TOOLS=0, WEAPONS=1, ARMOR=2
@export var creation_difficulty: ItemData.CreationDifficulty  # HOUSEHOLD=1, BASIC=2, MILITARY=3, ELITE=4
@export var is_complex_item: bool = true  # Whether a complex item is required
