@tool
extends EditorScript

# Import necessary classes to use their constants and types
const WeaponItem = preload("res://data/items/products (complex items)/scripts/weapon_item.gd")
const HeadArmorItem = preload("res://data/items/products (complex items)/scripts/head_armor_item.gd")
const BodyArmorItem = preload("res://data/items/products (complex items)/scripts/body_armor_item.gd")
const ToolItem = preload("res://data/items/products (complex items)/scripts/tool_item.gd")
const ComponentSlot = preload("res://data/items/component_slot.gd")
const MaterialSlot = preload("res://data/items/components (simple items)/material_slot.gd")

# Paths to directories for saving complex item resources
const ARMOR_ITEM_BASE_PATH = "res://data/items/products (complex items)/resources/armor/"
const WEAPON_ITEM_BASE_PATH = "res://data/items/products (complex items)/resources/weapons/"
const TOOL_ITEM_BASE_PATH = "res://data/items/products (complex items)/resources/tools/"

# Paths to directories for loading component resources
const HEAD_ARMOR_COMPONENTS_PATH = "res://data/items/components (simple items)/armor components/resources/head_armor/"
const BODY_ARMOR_COMPONENTS_PATH = "res://data/items/components (simple items)/armor components/resources/body_armor/"
const ONE_HANDED_WEAPON_COMPONENTS_PATH = "res://data/items/components (simple items)/weapon components/resources/one_handed_cut_weapon/"
const LONG_CUT_WEAPON_COMPONENTS_PATH = "res://data/items/components (simple items)/weapon components/resources/long_cut_weapon/"
const POLE_WEAPON_COMPONENTS_PATH = "res://data/items/components (simple items)/weapon components/resources/pole_weapon/"
const HEAVY_WEAPON_COMPONENTS_PATH = "res://data/items/components (simple items)/weapon components/resources/heavy_weapon/"
const DAGGER_COMPONENTS_PATH = "res://data/items/components (simple items)/weapon components/resources/dagger/"
const TOOL_COMPONENTS_PATH = "res://data/items/components (simple items)/tool components/resources/tools/"

# Structure for storing complex items
var complex_items = []

# Cache for loaded components
var component_cache = {}

# Function to run the script
func _run():
	print("Starting Complex Item Generator...")
	
	# Ensure directories exist
	ensure_directories_exist()
	
	# Initialize data for complex items
	init_complex_items()
	
	# Generate the complex items
	generate_complex_items()
	
	print("Complex Item Generation completed!")

# Creates necessary directories if they don't exist
func ensure_directories_exist():
	var dir = DirAccess.open("res://")
	if dir:
		# Create base paths
		var base_paths = [ARMOR_ITEM_BASE_PATH, WEAPON_ITEM_BASE_PATH, TOOL_ITEM_BASE_PATH]
		
		for base_path in base_paths:
			var current_path = ""
			for part in base_path.split("/"):
				if part.is_empty():
					continue
				current_path += "/" + part
				if not dir.dir_exists(current_path):
					dir.make_dir(current_path)
					print("Created directory: " + current_path)
					
		# Create weapon subfolders
		var weapon_subfolders = ["one_handed/", "long_cut/", "pole/", "heavy/", "dagger/"]
		for subfolder in weapon_subfolders:
			var path = WEAPON_ITEM_BASE_PATH + subfolder
			if not dir.dir_exists(path):
				dir.make_dir(path)
				print("Created directory: " + path)
				
		# Create armor subfolders
		var armor_subfolders = ["head_armor/", "body_armor/"]
		for subfolder in armor_subfolders:
			var path = ARMOR_ITEM_BASE_PATH + subfolder
			if not dir.dir_exists(path):
				dir.make_dir(path)
				print("Created directory: " + path)

# Initialize data for complex items based on images
func init_complex_items():
	print("Initializing complex items data...")
	
	# HEAD ARMOR
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "Without Visor",
		"name": "Kettle-Hat",
		"difficulty": "2",
		"components": [
			{"name": "Kettle-Hat Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Leather Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "Without Visor",
		"name": "Simple Bascinet",
		"difficulty": "2",
		"components": [
			{"name": "Bascinet Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "Without Visor",
		"name": "Szyszak",
		"difficulty": "2",
		"components": [
			{"name": "Szyszak Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Leather Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "With Visor",
		"name": "Bascinet With Visor",
		"difficulty": "3",
		"components": [
			{"name": "Bascinet Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Static Visor", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 3}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "With Visor",
		"name": "Armet",
		"difficulty": "3",
		"components": [
			{"name": "Armet Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Folding Visor", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Leather Liner", "quantity": 1, "weight": 1, "slot": 3}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "With Visor",
		"name": "Noble Szyszak",
		"difficulty": "3",
		"components": [
			{"name": "Szyszak Dome", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Nose Protection", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 3}
		]
	})
	
	complex_items.append({
		"type": "HeadArmorItem",
		"category": "Head Armor",
		"subcategory": "Coif",
		"name": "Chainmail Coif",
		"difficulty": "2",
		"head_armor_type": 2,  # COIF
		"components": [
			{"name": "Chainmail Piece", "quantity": 4, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	# BODY ARMOR
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Torso Armor",
		"name": "Simple Cuirass",
		"difficulty": "2",
		"body_armor_type": 0,  # TORSO_ARMOR
		"components": [
			{"name": "Front Cuirass", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Leather Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Torso Armor",
		"name": "Full Cuirass",
		"difficulty": "3",
		"body_armor_type": 0,  # TORSO_ARMOR
		"components": [
			{"name": "Front Cuirass", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Back Cuirass", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 3}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Torso Armor",
		"name": "Brigandine",
		"difficulty": "2",
		"body_armor_type": 0,  # TORSO_ARMOR
		"components": [
			{"name": "Metal Plate", "quantity": 4, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Plates on rope", "quantity": 1, "weight": 1, "slot": 3}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Torso Armor",
		"name": "Cuirass and Chainmail",
		"difficulty": "3",
		"body_armor_type": 0,  # TORSO_ARMOR
		"components": [
			{"name": "Front Cuirass", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Back Cuirass", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Chainmail Piece", "quantity": 4, "weight": 2, "slot": 3},
			{"name": "Leather Liner", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Chainmail",
		"name": "Short Chainmail Shirt",
		"difficulty": "2",
		"body_armor_type": 1,  # CHAINMAIL
		"components": [
			{"name": "Chainmail Piece", "quantity": 8, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Chainmail",
		"name": "Long Chainmail Shirt",
		"difficulty": "2",
		"body_armor_type": 1,  # CHAINMAIL
		"components": [
			{"name": "Chainmail Piece", "quantity": 10, "weight": 3, "slot": 1},
			{"name": "Leather Liner", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Arms Armor",
		"name": "Pauldrons",
		"difficulty": "2",
		"body_armor_type": 2,  # ARMS_ARMOR
		"components": [
			{"name": "Pauldrons Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Arms Armor",
		"name": "Rerebracers",
		"difficulty": "2",
		"body_armor_type": 2,  # ARMS_ARMOR
		"components": [
			{"name": "Rerebracers Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Arms Armor",
		"name": "Vambraces",
		"difficulty": "2",
		"body_armor_type": 2,  # ARMS_ARMOR
		"components": [
			{"name": "Vambraces Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Arms Armor",
		"name": "Gauntlets",
		"difficulty": "2",
		"body_armor_type": 2,  # ARMS_ARMOR
		"components": [
			{"name": "Gauntlets Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Legs Armor",
		"name": "Cuisses",
		"difficulty": "2",
		"body_armor_type": 3,  # LEGS_ARMOR
		"components": [
			{"name": "Cuisses Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Legs Armor",
		"name": "Greaves",
		"difficulty": "2",
		"body_armor_type": 3,  # LEGS_ARMOR
		"components": [
			{"name": "Greaves Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "BodyArmorItem",
		"category": "Body Armor",
		"subcategory": "Legs Armor",
		"name": "Sabatons",
		"difficulty": "2",
		"body_armor_type": 3,  # LEGS_ARMOR
		"components": [
			{"name": "Sabatons Plate", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Fabric Liner", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	# ONE-HANDED WEAPONS
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "One-Handed Sword",
		"name": "Short Sword",
		"difficulty": "2",
		"weapon_type": 0,  # ONE_HANDED_SWORD
		"components": [
			{"name": "Short Sword Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Round Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Simple Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "One-Handed Sword",
		"name": "Arming Sword",
		"difficulty": "2",
		"weapon_type": 0,  # ONE_HANDED_SWORD
		"components": [
			{"name": "Arming Sword Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Straight Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Simple Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "One-Handed Sword",
		"name": "Falchion",
		"difficulty": "2",
		"weapon_type": 0,  # ONE_HANDED_SWORD
		"components": [
			{"name": "Falchion Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Simple Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Simple Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "One-Handed Sword",
		"name": "Estoc",
		"difficulty": "3",
		"weapon_type": 0,  # ONE_HANDED_SWORD
		"components": [
			{"name": "Estoc Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Straight Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Long Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "One-Handed Sword",
		"name": "Noble Short Sword",
		"difficulty": "4",
		"weapon_type": 0,  # ONE_HANDED_SWORD
		"components": [
			{"name": "Noble Short Sword Bide", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Guard", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Decorated Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Decorated Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "Saber",
		"name": "Simple Saber",
		"difficulty": "2",
		"weapon_type": 1,  # SABER
		"components": [
			{"name": "Simple Saber Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Curved Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Simple Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Simple Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "Saber",
		"name": "Polish Saber",
		"difficulty": "3",
		"weapon_type": 1,  # SABER
		"components": [
			{"name": "Polish Saber Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Curved Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Pentagon Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "Saber",
		"name": "Tatar Saber",
		"difficulty": "3",
		"weapon_type": 1,  # SABER
		"components": [
			{"name": "Tatar Saber Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Curved Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Round Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "Saber",
		"name": "Magyar Saber",
		"difficulty": "3",
		"weapon_type": 1,  # SABER
		"components": [
			{"name": "Magyar Saber Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Curved Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Pentagon Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "One-Handed Cut Weapon",
		"subcategory": "Saber",
		"name": "Noble Saber",
		"difficulty": "4",
		"weapon_type": 1,  # SABER
		"components": [
			{"name": "Noble Saber Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Guard", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Decorated Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Decorated Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	# LONG CUT WEAPONS
	complex_items.append({
		"type": "WeaponItem",
		"category": "Long Cut Weapon",
		"subcategory": "Long Sword",
		"name": "Bastard Sword",
		"difficulty": "2",
		"weapon_type": 2,  # LONG_SWORD
		"components": [
			{"name": "Bastard Sword Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Simple Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Simple Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Long Cut Weapon",
		"subcategory": "Long Sword",
		"name": "Zweihänder",
		"difficulty": "3",
		"weapon_type": 2,  # LONG_SWORD
		"components": [
			{"name": "Zweihänder Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Straight Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Heavy Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 2, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Long Cut Weapon",
		"subcategory": "Long Sword",
		"name": "Claymore",
		"difficulty": "3",
		"weapon_type": 2,  # LONG_SWORD
		"components": [
			{"name": "Claymore Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Straight Guard", "quantity": 1, "weight": 1, "slot": 2},
			{"name": "Heavy Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Grip Handle", "quantity": 1, "weight": 2, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Long Cut Weapon",
		"subcategory": "Long Sword",
		"name": "Noble Bastard Sword",
		"difficulty": "4",
		"weapon_type": 2,  # LONG_SWORD
		"components": [
			{"name": "Noble Bastard Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Guard", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Decorated Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Decorated Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Long Cut Weapon",
		"subcategory": "Long Sword",
		"name": "Noble Zweihänder",
		"difficulty": "4",
		"weapon_type": 2,  # LONG_SWORD
		"components": [
			{"name": "Noble Zweihänder Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Guard", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Decorated Pommel", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Decorated Handle", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	# POLE WEAPONS
	complex_items.append({
		"type": "WeaponItem",
		"category": "Pole Weapon",
		"subcategory": "Pole Weapon",
		"name": "Spear",
		"difficulty": "2",
		"weapon_type": 3,  # POLE_WEAPON
		"components": [
			{"name": "Spear Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Pole Weapon",
		"subcategory": "Pole Weapon",
		"name": "Bardiche",
		"difficulty": "2",
		"weapon_type": 3,  # POLE_WEAPON
		"components": [
			{"name": "Bardiche Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Grip Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Pole Weapon",
		"subcategory": "Pole Weapon",
		"name": "Halberd",
		"difficulty": "3",
		"weapon_type": 3,  # POLE_WEAPON
		"components": [
			{"name": "Halberd Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Grip Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Pole Weapon",
		"subcategory": "Pole Weapon",
		"name": "Pike",
		"difficulty": "2",
		"weapon_type": 3,  # POLE_WEAPON
		"components": [
			{"name": "Pike Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	# HEAVY WEAPONS
	complex_items.append({
		"type": "WeaponItem",
		"category": "Heavy Weapon",
		"subcategory": "Heavy Weapon",
		"name": "War Hammer",
		"difficulty": "2",
		"weapon_type": 4,  # HEAVY_WEAPON
		"components": [
			{"name": "War Hammer Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Wooden Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Heavy Weapon",
		"subcategory": "Heavy Weapon",
		"name": "Mace",
		"difficulty": "2",
		"weapon_type": 4,  # HEAVY_WEAPON
		"components": [
			{"name": "Mace Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Wooden Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Heavy Weapon",
		"subcategory": "Heavy Weapon",
		"name": "Morning Star",
		"difficulty": "2",
		"weapon_type": 4,  # HEAVY_WEAPON
		"components": [
			{"name": "Morning Start Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Grip Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Heavy Weapon",
		"subcategory": "Heavy Weapon",
		"name": "Battle Axe",
		"difficulty": "2",
		"weapon_type": 4,  # HEAVY_WEAPON
		"components": [
			{"name": "Battle Axe Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Wooden Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Heavy Weapon",
		"subcategory": "Heavy Weapon",
		"name": "Noble Pernach",
		"difficulty": "4",
		"weapon_type": 4,  # HEAVY_WEAPON
		"components": [
			{"name": "Noble Pernach Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Metal Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	# DAGGERS
	complex_items.append({
		"type": "WeaponItem",
		"category": "Dagger",
		"subcategory": "Knife",
		"name": "Knife",
		"difficulty": "1",
		"weapon_type": 5,  # DAGGER
		"components": [
			{"name": "Knife Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Simple Dagger Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Dagger",
		"subcategory": "Dagger",
		"name": "Thieves Dagger",
		"difficulty": "1",
		"weapon_type": 5,  # DAGGER
		"components": [
			{"name": "Thieves Dagger Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Grip Dagger Handle", "quantity": 1, "weight": 2, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Dagger",
		"subcategory": "Dagger",
		"name": "Knights Dagger",
		"difficulty": "2",
		"weapon_type": 5,  # DAGGER
		"components": [
			{"name": "Knights Dagger Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Grip Dagger Handle", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Simple Dagger Guard", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Simple Dagger Pommel", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	complex_items.append({
		"type": "WeaponItem",
		"category": "Dagger",
		"subcategory": "Dagger",
		"name": "Rich Dagger",
		"difficulty": "3",
		"weapon_type": 5,  # DAGGER
		"components": [
			{"name": "Rich Dagger Blade", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Decorated Dagger Handle", "quantity": 1, "weight": 2, "slot": 2},
			{"name": "Extended Dagger Guard", "quantity": 1, "weight": 1, "slot": 3},
			{"name": "Large Dagger Pommel", "quantity": 1, "weight": 1, "slot": 4}
		]
	})
	
	# TOOLS
	complex_items.append({
		"type": "ToolItem",
		"category": "Tools",
		"subcategory": "Tools",
		"name": "Axe",
		"difficulty": "1",
		"tool_type": 0,  # AXE
		"components": [
			{"name": "Axe Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Tool Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "ToolItem",
		"category": "Tools",
		"subcategory": "Tools",
		"name": "Hand Hoe",
		"difficulty": "1",
		"tool_type": 1,  # HAND_HOE
		"components": [
			{"name": "Hand Hoe Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Tool Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "ToolItem",
		"category": "Tools",
		"subcategory": "Tools",
		"name": "Scythe",
		"difficulty": "1",
		"tool_type": 2,  # SCYTHE
		"components": [
			{"name": "Scythe Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Tool Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "ToolItem",
		"category": "Tools",
		"subcategory": "Tools",
		"name": "Shovel",
		"difficulty": "1",
		"tool_type": 3,  # SHOVEL
		"components": [
			{"name": "Shovel Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Tool Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	complex_items.append({
		"type": "ToolItem",
		"category": "Tools",
		"subcategory": "Tools",
		"name": "Pickaxe",
		"difficulty": "1",
		"tool_type": 4,  # PICKAXE
		"components": [
			{"name": "Pickaxe Head", "quantity": 1, "weight": 3, "slot": 1},
			{"name": "Tool Handle", "quantity": 1, "weight": 1, "slot": 2}
		]
	})
	
	print("Initialized complex items: " + str(complex_items.size()))
	
# Function to load a component resource
func load_component(component_name: String) -> Resource:
	# Check if the component is already in cache
	if component_name in component_cache:
		return component_cache[component_name]
	
	# Create a normalized name for file path
	var file_name = component_name.to_snake_case() + ".tres"
	
	# Define all possible search paths
	var search_paths = [
		HEAD_ARMOR_COMPONENTS_PATH,
		BODY_ARMOR_COMPONENTS_PATH,
		ONE_HANDED_WEAPON_COMPONENTS_PATH,
		LONG_CUT_WEAPON_COMPONENTS_PATH,
		POLE_WEAPON_COMPONENTS_PATH,
		HEAVY_WEAPON_COMPONENTS_PATH,
		DAGGER_COMPONENTS_PATH,
		TOOL_COMPONENTS_PATH,
		"res://data/items/components (simple items)/tool components/resources/materials/"
	]
	
	# First try direct file path based on component name
	for path in search_paths:
		var full_path = path + file_name
		if ResourceLoader.exists(full_path):
			var resource = load(full_path)
			if resource:
				print("Found component at: " + full_path)
				component_cache[component_name] = resource
				return resource
	
	# If not found by filename, search by examining all resources
	for path in search_paths:
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if !dir.current_is_dir() and file.ends_with(".tres"):
					var full_path = path + file
					var resource = load(full_path)
					if resource and resource.name == component_name:
						print("Found component by name at: " + full_path)
						component_cache[component_name] = resource
						return resource
				file = dir.get_next()
	
	# Special case for Chainmail Piece which might be named differently
	if "Chainmail" in component_name:
		var chainmail_path = "res://data/items/components (simple items)/tool components/resources/materials/chainmail_piece.tres"
		if ResourceLoader.exists(chainmail_path):
			var resource = load(chainmail_path)
			if resource:
				print("Found Chainmail at: " + chainmail_path)
				component_cache[component_name] = resource
				return resource
	
	# Special case for Metal Plate
	if "Metal Plate" in component_name:
		var plate_path = "res://data/items/components (simple items)/tool components/resources/materials/metal_plate.tres"
		if ResourceLoader.exists(plate_path):
			var resource = load(plate_path)
			if resource:
				print("Found Metal Plate at: " + plate_path)
				component_cache[component_name] = resource
				return resource
	
	# Try another approach - check if a file name matches part of the component name
	for path in search_paths:
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if !dir.current_is_dir() and file.ends_with(".tres"):
					# Convert file name back to readable form for comparison
					var file_base = file.get_basename()
					var readable_name = file_base.replace("_", " ").capitalize()
					
					# Check if any word in component_name is in file_base
					var name_parts = component_name.to_lower().split(" ")
					for part in name_parts:
						if part.length() > 3 and part.to_lower() in file_base.to_lower():
							var full_path = path + file
							var resource = load(full_path)
							if resource:
								print("Found approximate match: " + component_name + " -> " + full_path)
								component_cache[component_name] = resource
								return resource
				file = dir.get_next()
	
	print("WARNING: Could not find component: " + component_name)
	return null

# Function to generate a description for an item
func generate_description(item_name: String, category: String) -> String:
	# Generate descriptions based on item category and name
	var descriptions = {
		"Head Armor": [
			"Protects your thinking apparatus from unwanted modifications.",
			"Makes your head slightly less crushable in combat situations.",
			"Turns lethal blows into merely painful ones.",
			"Keeps your brain where it belongs - inside your skull.",
			"A fine addition to any knight's wardrobe."
		],
		"Body Armor": [
			"Ensures your vital organs stay on the inside where they belong.",
			"Transforms deadly strikes into annoying bruises.",
			"Makes you harder to kill, but also harder to dress quickly.",
			"Protects against sword cuts, mace blows, and bad fashion choices.",
			"A sturdy barrier between you and pointy objects with ill intent."
		],
		"One-Handed Cut Weapon": [
			"Elegant, deadly, and surprisingly good at opening mail.",
			"Perfect for making decisive points in arguments.",
			"Brings a certain gravitas to diplomatic negotiations.",
			"Classic design with excellent weight distribution and balance.",
			"Makes a statement both on and off the battlefield."
		],
		"Long Cut Weapon": [
			"Requires two hands, considerable strength, and questionable judgment.",
			"Ensures enemies maintain a respectful distance.",
			"Impressively large and intimidating, much like its wielder should be.",
			"When you absolutely, positively need to reach out and touch someone.",
			"Makes up in reach what it lacks in subtlety."
		],
		"Pole Weapon": [
			"Perfect for keeping enemies at a comfortable distance.",
			"Extends your reach and your survival prospects in battle.",
			"Long, deadly, and surprisingly versatile.",
			"Offers more range than conventional weapons, with similar lethality.",
			"An excellent choice for the cautious warrior."
		],
		"Heavy Weapon": [
			"Substitutes finesse with raw crushing power.",
			"Makes a compelling argument for armor obsolescence.",
			"When subtlety is no longer an option.",
			"Perfect for when you need to make a dent in something.",
			"Transforms armored opponents into noisy containers."
		],
		"Dagger": [
			"Small, concealable, and unexpectedly persuasive.",
			"Perfect for close encounters of the fatal kind.",
			"Makes a point quickly and efficiently.",
			"The discerning assassin's tool of choice.",
			"Small in size, big in consequences."
		],
		"Tools": [
			"Surprisingly useful for both peaceful and desperate situations.",
			"Built for work, but adaptable to emergencies.",
			"A practical tool for everyday tasks around the homestead.",
			"Quality craftsmanship means reliability when you need it most.",
			"Essential equipment for any self-respecting farmer or craftsman."
		]
	}
	
	# Special descriptions for specific items
	if "Kettle" in item_name:
		return "Protects your head while reminding everyone of soup."
	
	if "Bascinet" in item_name:
		return "The fashion-forward knight's choice in battlefield headwear."
	
	if "Armet" in item_name:
		return "Encloses the head completely, making identification of friend or foe delightfully challenging."
	
	if "Chainmail" in item_name:
		return "Thousands of tiny rings joined together by an apprentice questioning their life choices."
	
	if "Noble" in item_name:
		return "Unnecessarily ornate and expensive. Perfect for dying with style."
	
	if "Bastard Sword" in item_name:
		return "Neither short nor long, the identity crisis of swords."
	
	if "Claymore" in item_name:
		return "Scottish engineering at its finest - a sword as subtle as the people who created it."
	
	if "War Hammer" in item_name:
		return "When you need to open a heavily armored knight like a tin can."
	
	if "Axe" in item_name and category == "Tools":
		return "The lumberjack's best friend. Trees tremble when you approach."
	
	if "Shovel" in item_name:
		return "Moves dirt from one place to another. Revolutionary technology."
	
	if "Scythe" in item_name:
		return "Not just for the Grim Reaper anymore. Works great on wheat too!"
	
	# If no special description, pick a random one from the category
	if category in descriptions:
		var category_descriptions = descriptions[category]
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var index = rng.randi_range(0, category_descriptions.size() - 1)
		return category_descriptions[index]
	
	# Default description
	return "A finely crafted item that would make any craftsman proud."

# Function to generate complex items based on initialized data
func generate_complex_items():
	print("Generating complex items...")
	
	for item_data in complex_items:
		# Create the appropriate complex item based on its type
		match item_data.type:
			"HeadArmorItem":
				create_head_armor_item(item_data)
			"BodyArmorItem":
				create_body_armor_item(item_data)
			"WeaponItem":
				create_weapon_item(item_data)
			"ToolItem":
				create_tool_item(item_data)
			_:
				print("Unknown item type: " + item_data.type)
	
	print("Generated " + str(complex_items.size()) + " complex items")

# Create head armor item based on data
func create_head_armor_item(item_data):
	# Create a new HeadArmorItem instance
	var head_armor = HeadArmorItem.new()
	
	# Set basic properties
	head_armor.name = item_data.name
	head_armor.description = generate_description(item_data.name, item_data.category)
	
	# Set item difficulty
	match item_data.difficulty:
		"1": head_armor.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": head_armor.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": head_armor.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": head_armor.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: head_armor.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Set produced quantity
	head_armor.produced_quantity = 1
	
	# Set head armor type if specified
	if "head_armor_type" in item_data:
		head_armor.head_armor_type = item_data.head_armor_type
	else:
		# Set default type based on subcategory
		match item_data.subcategory:
			"Without Visor":
				head_armor.head_armor_type = HeadArmorItem.HeadArmorType.WITHOUT_VISOR
			"With Visor":
				head_armor.head_armor_type = HeadArmorItem.HeadArmorType.WITH_VISOR
			"Coif":
				head_armor.head_armor_type = HeadArmorItem.HeadArmorType.COIF
			_:
				head_armor.head_armor_type = HeadArmorItem.HeadArmorType.WITHOUT_VISOR
	
	# Add component slots
	setup_item_components(head_armor, item_data.components)
	
	# Save the item
	var file_name = item_data.name.to_snake_case() + ".tres"
	var save_path = ARMOR_ITEM_BASE_PATH + "head_armor/" + file_name
	var result = ResourceSaver.save(head_armor, save_path)
	
	if result == OK:
		print("Created head armor item: " + item_data.name)
	else:
		push_error("Failed to save head armor item: " + item_data.name)

# Create body armor item based on data
func create_body_armor_item(item_data):
	# Create a new BodyArmorItem instance
	var body_armor = BodyArmorItem.new()
	
	# Set basic properties
	body_armor.name = item_data.name
	body_armor.description = generate_description(item_data.name, item_data.category)
	
	# Set item difficulty
	match item_data.difficulty:
		"1": body_armor.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": body_armor.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": body_armor.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": body_armor.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: body_armor.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Set produced quantity
	body_armor.produced_quantity = 1
	
	# Set body armor type
	if "body_armor_type" in item_data:
		body_armor.body_armor_type = item_data.body_armor_type
	else:
		# Default body armor type based on subcategory
		match item_data.subcategory:
			"Torso Armor":
				body_armor.body_armor_type = BodyArmorItem.BodyArmorType.TORSO_ARMOR
			"Chainmail":
				body_armor.body_armor_type = BodyArmorItem.BodyArmorType.CHAINMAIL
			"Arms Armor":
				body_armor.body_armor_type = BodyArmorItem.BodyArmorType.ARMS_ARMOR
			"Legs Armor":
				body_armor.body_armor_type = BodyArmorItem.BodyArmorType.LEGS_ARMOR
			_:
				body_armor.body_armor_type = BodyArmorItem.BodyArmorType.TORSO_ARMOR
	
	# Add component slots
	setup_item_components(body_armor, item_data.components)
	
	# Save the item
	var file_name = item_data.name.to_snake_case() + ".tres"
	var save_path = ARMOR_ITEM_BASE_PATH + "body_armor/" + file_name
	var result = ResourceSaver.save(body_armor, save_path)
	
	if result == OK:
		print("Created body armor item: " + item_data.name)
	else:
		push_error("Failed to save body armor item: " + item_data.name)

# Create weapon item based on data
func create_weapon_item(item_data):
	# Create a new WeaponItem instance
	var weapon = WeaponItem.new()
	
	# Set basic properties
	weapon.name = item_data.name
	weapon.description = generate_description(item_data.name, item_data.category)
	
	# Set item difficulty
	match item_data.difficulty:
		"1": weapon.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": weapon.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": weapon.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": weapon.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: weapon.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Set produced quantity
	weapon.produced_quantity = 1
	
	# Set weapon type
	if "weapon_type" in item_data:
		weapon.weapon_type = item_data.weapon_type
	else:
		# Default weapon type based on category
		match item_data.category:
			"One-Handed Cut Weapon":
				match item_data.subcategory:
					"One-Handed Sword":
						weapon.weapon_type = 0  # ONE_HANDED_SWORD
					"Saber":
						weapon.weapon_type = 1  # SABER
					_:
						weapon.weapon_type = 0  # Default to ONE_HANDED_SWORD
			"Long Cut Weapon":
				weapon.weapon_type = 2  # LONG_SWORD
			"Pole Weapon":
				weapon.weapon_type = 3  # POLE_WEAPON
			"Heavy Weapon":
				weapon.weapon_type = 4  # HEAVY_WEAPON
			"Dagger":
				weapon.weapon_type = 5  # DAGGER
			_:
				weapon.weapon_type = 0  # Default
	
	# Add component slots
	setup_item_components(weapon, item_data.components)
	
	# Determine subfolder based on category
	var subfolder = ""
	match item_data.category:
		"One-Handed Cut Weapon":
			subfolder = "one_handed/"
		"Long Cut Weapon":
			subfolder = "long_cut/"
		"Pole Weapon":
			subfolder = "pole/"
		"Heavy Weapon":
			subfolder = "heavy/"
		"Dagger":
			subfolder = "dagger/"
	
	# Save the item
	var file_name = item_data.name.to_snake_case() + ".tres"
	var save_path = WEAPON_ITEM_BASE_PATH + subfolder + file_name
	var result = ResourceSaver.save(weapon, save_path)
	
	if result == OK:
		print("Created weapon item: " + item_data.name)
	else:
		push_error("Failed to save weapon item: " + item_data.name)

# Create tool item based on data
func create_tool_item(item_data):
	# Create a new ToolItem instance
	var tool_item = ToolItem.new()
	
	# Set basic properties
	tool_item.name = item_data.name
	tool_item.description = generate_description(item_data.name, item_data.category)
	
	# Set item difficulty
	match item_data.difficulty:
		"1": tool_item.creation_difficulty = ItemData.CreationDifficulty.HOUSEHOLD
		"2": tool_item.creation_difficulty = ItemData.CreationDifficulty.BASIC
		"3": tool_item.creation_difficulty = ItemData.CreationDifficulty.MILITARY
		"4": tool_item.creation_difficulty = ItemData.CreationDifficulty.ELITE
		_: tool_item.creation_difficulty = ItemData.CreationDifficulty.BASIC
	
	# Set produced quantity
	tool_item.produced_quantity = 1
	
	# Set tool type
	if "tool_type" in item_data:
		tool_item.tool_type = item_data.tool_type
	else:
		# Default tool type based on name
		match item_data.name:
			"Axe":
				tool_item.tool_type = ToolItem.ToolType.AXE
			"Hand Hoe":
				tool_item.tool_type = ToolItem.ToolType.HAND_HOE
			"Scythe":
				tool_item.tool_type = ToolItem.ToolType.SCYTHE
			"Shovel":
				tool_item.tool_type = ToolItem.ToolType.SHOVEL
			"Pickaxe":
				tool_item.tool_type = ToolItem.ToolType.PICKAXE
			_:
				tool_item.tool_type = ToolItem.ToolType.AXE  # Default
	
	# Add component slots
	setup_item_components(tool_item, item_data.components)
	
	# Save the item
	var file_name = item_data.name.to_snake_case() + ".tres"
	var save_path = TOOL_ITEM_BASE_PATH + file_name
	var result = ResourceSaver.save(tool_item, save_path)
	
	if result == OK:
		print("Created tool item: " + item_data.name)
	else:
		push_error("Failed to save tool item: " + item_data.name)

# Helper function to set up component slots for items
func setup_item_components(item, components_data):
	# Clear existing slots if any
	item.component_slots.clear()
	
	# Sort components by slot index for consistent order
	components_data.sort_custom(func(a, b): return a.slot < b.slot)
	
	# Create slots for each component
	for component_data in components_data:
		# Create a new component slot
		var component_slot = ComponentSlot.new()
		
		# Set the quantity
		component_slot.quantity = component_data.quantity
		
		# Set the weight
		component_slot.weight = component_data.weight
		
		# Set required
		component_slot.is_required = true
		
		# Load the component and set as allowed component
		var component = load_component(component_data.name)
		if component:
			component_slot.allowed_component = component
		else:
			# Create a placeholder component if we can't find the real one
			push_warning("Could not find component: " + component_data.name + " for item: " + item.name)
			
			# Try to guess the type of component to create
			var placeholder
			if "Blade" in component_data.name or "Guard" in component_data.name or "Pommel" in component_data.name:
				placeholder = WeaponComponent.new()
				placeholder.name = component_data.name
			elif "Dome" in component_data.name or "Visor" in component_data.name:
				placeholder = HeadArmorComponent.new()
				placeholder.name = component_data.name
			elif "Cuirass" in component_data.name or "Plate" in component_data.name or "Liner" in component_data.name:
				placeholder = BodyArmorComponent.new()
				placeholder.name = component_data.name
			elif "Head" in component_data.name and "Tool" in component_data.name:
				placeholder = ToolComponent.new()
				placeholder.name = component_data.name
			elif "Handle" in component_data.name:
				placeholder = ToolComponent.new()
				placeholder.name = component_data.name
				placeholder.tool_type = ToolComponent.ToolComponentType.TOOL_HANDLE
			elif "Chainmail" in component_data.name or "Metal Plate" in component_data.name:
				placeholder = UsableMaterialComponent.new()
				placeholder.name = component_data.name
			else:
				# Generic fallback
				placeholder = WeaponComponent.new()
				placeholder.name = component_data.name
			
			component_slot.allowed_component = placeholder
		
		# Add the slot to the item
		item.component_slots.append(component_slot)
