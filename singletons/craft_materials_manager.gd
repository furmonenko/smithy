# craft_material_manager.gd
extends Node

# Словники для збереження матеріалів по типах
var metals: Dictionary = {}          # name -> CraftMaterial
var woods: Dictionary = {}           # name -> CraftMaterial
var leathers: Dictionary = {}        # name -> CraftMaterial
var fabrics: Dictionary = {}         # name -> CraftMaterial
var decorations: Dictionary = {}     # name -> CraftMaterial

# Словник всіх матеріалів
var all_materials: Dictionary = {}   # name -> CraftMaterial

# Шляхи до ресурсів матеріалів
const METAL_PATH = "res://data/materials/resources/non-combinational/metals/"
const WOOD_PATH = "res://data/materials/resources/non-combinational/wood/"
const LEATHER_PATH = "res://data/materials/resources/combinational/leather/"
const FABRIC_PATH = "res://data/materials/resources/combinational/fabrics/"
const DECORATION_PATH = "res://data/materials/resources/combinational/decorations/"

func _ready() -> void:
	load_all_materials()

# Завантаження всіх матеріалів
func load_all_materials() -> void:
	load_materials_of_type(METAL_PATH, metals, Enums.MaterialType.METAL)
	load_materials_of_type(WOOD_PATH, woods, Enums.MaterialType.WOOD)
	load_materials_of_type(LEATHER_PATH, leathers, Enums.MaterialType.LEATHER)
	load_materials_of_type(FABRIC_PATH, fabrics, Enums.MaterialType.FABRIC)
	load_materials_of_type(DECORATION_PATH, decorations, Enums.MaterialType.DECORATION)
	
	# Об'єднати всі матеріали в один словник
	all_materials.merge(metals)
	all_materials.merge(woods)
	all_materials.merge(leathers)
	all_materials.merge(fabrics)
	all_materials.merge(decorations)
	
	print("Loaded materials: ", all_materials.size())

# Завантаження матеріалів певного типу
func load_materials_of_type(path: String, dict: Dictionary, material_type: Enums.MaterialType) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var material = load(path + file_name) as CraftMaterial
				if material:
					# Додаткова перевірка, що матеріал правильного типу
					if material.material_type == material_type:
						dict[material.name] = material
						print("Loaded material: ", material.name)
					else:
						push_warning("Material %s has incorrect type: expected %s, got %s" % [material.name, material_type, material.material_type])
				else:
					push_warning("Failed to load material: " + path + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("An error occurred when trying to access the path: " + path)

# Отримати матеріал за ім'ям
func get_material(name: String) -> CraftMaterial:
	if all_materials.has(name):
		return all_materials[name]
	push_warning("Material not found: " + name)
	return null

# Отримати всі матеріали певного типу
func get_materials_by_type(type: Enums.MaterialType) -> Array[CraftMaterial]:
	var result: Array[CraftMaterial] = []
	
	match type:
		Enums.MaterialType.METAL:
			for material in metals.values():
				result.append(material)
		Enums.MaterialType.WOOD:
			for material in woods.values():
				result.append(material)
		Enums.MaterialType.LEATHER:
			for material in leathers.values():
				result.append(material)
		Enums.MaterialType.FABRIC:
			for material in fabrics.values():
				result.append(material)
		Enums.MaterialType.DECORATION:
			for material in decorations.values():
				result.append(material)
	
	return result

# Отримати матеріали за типом і якістю (підходить для subcategory_materials)
func get_materials_by_type_and_quality(type: Enums.MaterialType, min_quality: int, max_quality: int = 100) -> Array[CraftMaterial]:
	var materials = get_materials_by_type(type)
	var filtered: Array[CraftMaterial] = []
	
	for material in materials:
		if material.quality >= min_quality and material.quality <= max_quality:
			filtered.append(material)
	
	# Сортування за якістю (від найнижчої до найвищої)
	filtered.sort_custom(func(a, b): return a.quality < b.quality)
	
	return filtered

# Отримати найкращий доступний матеріал для певного типу і мінімальної якості
func get_best_material_by_type_and_quality(type: Enums.MaterialType, min_quality: int) -> CraftMaterial:
	var materials = get_materials_by_type_and_quality(type, min_quality)
	
	if materials.size() > 0:
		# Повертаємо матеріал з найвищою якістю
		return materials[-1]
	
	return null

# Отримати найдешевший матеріал відповідної якості
func get_cheapest_material_by_type_and_quality(type: Enums.MaterialType, min_quality: int) -> CraftMaterial:
	var materials = get_materials_by_type_and_quality(type, min_quality)
	
	if materials.size() > 0:
		# Сортування за ціною
		materials.sort_custom(func(a, b): return a.cost < b.cost)
		return materials[0]
	
	return null
