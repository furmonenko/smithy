# input_manager.gd
extends Node

signal input_type_changed(device_type)

enum INPUT_TYPE { KEYBOARD, GAMEPAD }

var current_input_type: int = INPUT_TYPE.KEYBOARD

func _ready():
	process_input_device()

func _input(event):
	var new_input_type = current_input_type
	
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		new_input_type = INPUT_TYPE.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_input_type = INPUT_TYPE.GAMEPAD
	
	if new_input_type != current_input_type:
		current_input_type = new_input_type
		input_type_changed.emit(current_input_type)
		process_input_device()

func process_input_device():
	if current_input_type == INPUT_TYPE.KEYBOARD:
		print("Switching to keyboard controls")
	else:
		print("Switching to gamepad controls")

func get_button_texture(action_name: String) -> Texture2D:
	# Повертає правильну текстуру для поточного типу вводу
	if current_input_type == INPUT_TYPE.KEYBOARD:
		return get_keyboard_button_texture(action_name)
	else:
		return get_gamepad_button_texture(action_name)

func get_keyboard_button_texture(action_name: String) -> Texture2D:
	# Карта відповідності дій до текстур клавіатури
	var keyboard_textures = {
		"hit_button_a": preload("res://assets/buttons/keyboard/key_e.png"),
		"hit_button_b": preload("res://assets/buttons/keyboard/key_z.png"),
		"hit_button_x": preload("res://assets/buttons/keyboard/key_q.png"),
		"hit_button_y": preload("res://assets/buttons/keyboard/key_c.png"),
		"ui_up": preload("res://assets/buttons/keyboard/key_up.png"),
		"ui_down": preload("res://assets/buttons/keyboard/key_down.png"),
		"ui_left": preload("res://assets/buttons/keyboard/key_left.png"),
		"ui_right": preload("res://assets/buttons/keyboard/key_right.png")
	}
	
	return keyboard_textures.get(action_name, null)

func get_gamepad_button_texture(action_name: String) -> Texture2D:
	# Карта відповідності дій до текстур геймпада
	var gamepad_textures = {
		"hit_button_a": preload("res://assets/buttons/xbox_gamepad/hit_button_a.png"),
		"hit_button_b": preload("res://assets/buttons/xbox_gamepad/hit_button_b.png"),
		"hit_button_x": preload("res://assets/buttons/xbox_gamepad/hit_button_x.png"),
		"hit_button_y": preload("res://assets/buttons/xbox_gamepad/hit_button_y.png"),
		"ui_up": preload("res://assets/buttons/xbox_gamepad/dpad_up.png"),
		"ui_down": preload("res://assets/buttons/xbox_gamepad/dpad_down.png"),
		"ui_left": preload("res://assets/buttons/xbox_gamepad/dpad_left.png"),
		"ui_right": preload("res://assets/buttons/xbox_gamepad/dpad_right.png")
	}
	
	return gamepad_textures.get(action_name, null)

func get_button_display_name(action_name: String) -> String:
	# Повертає відображуване ім'я кнопки залежно від пристрою
	if current_input_type == INPUT_TYPE.KEYBOARD:
		var keyboard_names = {
			"hit_button_a": "E",
			"hit_button_b": "Z",
			"hit_button_x": "Q",
			"hit_button_y": "C",
			"ui_up": "↑",
			"ui_down": "↓",
			"ui_left": "←",
			"ui_right": "→"
		}
		return keyboard_names.get(action_name, action_name)
	else:
		var gamepad_names = {
			"hit_button_a": "A",
			"hit_button_b": "B",
			"hit_button_x": "X",
			"hit_button_y": "Y",
			"ui_up": "D-Pad ↑",
			"ui_down": "D-Pad ↓",
			"ui_left": "D-Pad ←",
			"ui_right": "D-Pad →"
		}
		return gamepad_names.get(action_name, action_name)
