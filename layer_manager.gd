@tool
extends Node
class_name LayerManager

# Enum для шарів
enum LAYER {FRONT = 0, MID = 1, BACK = 2}

# Сигнал зміни шару
signal layer_changed(object, old_layer, new_layer)

# === Загальні налаштування ===
@export_group("Шляхи до шарів")
@export var front_layer_path: NodePath
@export var middle_layer_path: NodePath
@export var back_layer_path: NodePath

@export_group("Параметри масштабування")
# Y-координати для визначення шару
@export var y_positions: Array[float] = [900.0, 600.0, 300.0]
# Масштаб для кожного шару
@export var scales: Array[float] = [1.0, 0.85, 0.7]
# Допустима похибка
@export var tolerance: float = 20.0

@export_group("Режими роботи")
# Увімкнути/вимкнути автоматичне масштабування
@export var auto_scale: bool = true
# Увімкнути/вимкнути автоматичне сортування по шарах у грі
@export var auto_organize: bool = true
# Увімкнути/вимкнути збереження оригінальних масштабів
@export var respect_original_scale: bool = true
# Режим діагностики
@export var logging: bool = true

# Вузли шарів
var front_layer: Node2D
var middle_layer: Node2D
var back_layer: Node2D

# Для збереження оригінального масштабу
var original_scales = {}

# Заблокувати оновлення на кадр (для методів, що викликаються з інспектора)
var _lock_updates_for_frame = false

func _ready():
	# print("Manager initialized in " + ("EDITOR" if Engine.is_editor_hint() else "GAME") + " mode")
	
	# Отримуємо шари
	front_layer = get_node_or_null(front_layer_path)
	middle_layer = get_node_or_null(middle_layer_path)
	back_layer = get_node_or_null(back_layer_path)
	
	# print("Layers: Front=" + str(front_layer) + ", Middle=" + str(middle_layer) + ", Back=" + str(back_layer))
	
	# Налаштовуємо z-індекси
	if front_layer: front_layer.z_index = 20
	if middle_layer: middle_layer.z_index = 10
	if back_layer: back_layer.z_index = 0
	
	# Зберігаємо оригінальні масштаби всіх об'єктів у редакторі
	if Engine.is_editor_hint():
		scan_original_scales()
	
	# В грі організовуємо об'єкти по шарах
	if not Engine.is_editor_hint() and auto_organize:
		call_deferred("organize_objects_for_game")

func _process(delta):
	if _lock_updates_for_frame:
		_lock_updates_for_frame = false
		return
		
	if Engine.is_editor_hint() and auto_scale:
		update_scales_in_editor()

# Сканує і зберігає оригінальні масштаби всіх об'єктів
func scan_original_scales():
	var parent = get_parent()
	if not parent:
		return
	
	original_scales.clear()
	
	for child in parent.get_children():
		if child is Node2D and child != self and child != front_layer and child != middle_layer and child != back_layer:
			original_scales[child] = child.scale
			print("Saved original scale for " + child.name + ": " + str(child.scale))
	
	print("Scanned and saved original scales for " + str(original_scales.size()) + " objects")

# Скидає оригінальні масштаби і зберігає поточні як нові оригінальні
func reset_original_scales():
	print("Resetting original scales and capturing current scales as new originals")
	_lock_updates_for_frame = true
	scan_original_scales()

# Вимикає автоматичне масштабування
func disable_auto_scale():
	print("Auto-scaling disabled")
	auto_scale = false

# Вмикає автоматичне масштабування
func enable_auto_scale():
	print("Auto-scaling enabled")
	auto_scale = true

# Визначення шару за Y-координатою
func get_layer_index_for_position(y_pos: float) -> int:
	if y_pos >= y_positions[0] - tolerance:
		return LAYER.FRONT  # Передній шар
	elif y_pos >= y_positions[1] - tolerance:
		return LAYER.MID  # Середній шар
	else:
		return LAYER.BACK  # Задній шар

# Оновлення масштабу об'єктів в редакторі
func update_scales_in_editor():
	var parent = get_parent()
	if not parent:
		return
	
	for child in parent.get_children():
		if child is Node2D and child != self and child != front_layer and child != middle_layer and child != back_layer:
			var layer_index = get_layer_index_for_position(child.position.y)
			
			# Встановлюємо змінну layer в об'єкті, якщо можливо
			if "layer" in child:
				child.layer = layer_index
			
			# Зберігаємо оригінальний масштаб при першому виявленні
			if not original_scales.has(child) and respect_original_scale:
				original_scales[child] = child.scale
				print("New object found: " + child.name + " with scale " + str(child.scale))
			
			# Розраховуємо масштаб на основі відношення Y-координат
			var normalized_scale = 1.0
			if layer_index == LAYER.FRONT:
				normalized_scale = scales[LAYER.FRONT]
			elif layer_index == LAYER.MID:
				# Інтерполяція між першим і другим масштабом
				var progress = (child.position.y - y_positions[LAYER.FRONT]) / (y_positions[LAYER.MID] - y_positions[LAYER.FRONT])
				normalized_scale = lerp(scales[LAYER.FRONT], scales[LAYER.MID], progress)
			else:
				# Інтерполяція між другим і третім масштабом
				var progress = (child.position.y - y_positions[LAYER.MID]) / (y_positions[LAYER.BACK] - y_positions[LAYER.MID])
				normalized_scale = lerp(scales[LAYER.MID], scales[LAYER.BACK], progress)
			
			# Застосовуємо масштаб
			var target_scale
			if respect_original_scale and original_scales.has(child):
				# Використовуємо оригінальний масштаб як основу
				var original_scale = original_scales[child]
				target_scale = Vector2(
					original_scale.x * normalized_scale, 
					original_scale.y * normalized_scale
				)
			else:
				# Використовуємо лише розрахований масштаб
				target_scale = Vector2(normalized_scale, normalized_scale)
			
			# Встановлюємо масштаб, якщо він значно змінився
			if abs(child.scale.x - target_scale.x) > 0.01:
				child.scale = target_scale

# Організація об'єктів по шарах при запуску гри
func organize_objects_for_game():
	print("Starting organization for game...")
	
	var parent = get_parent()
	if not parent or not front_layer or not middle_layer or not back_layer:
		print("ERROR: Cannot find layers or parent")
		return
	
	# Збираємо об'єкти для сортування
	var objects_to_sort = []
	for child in parent.get_children():
		if child is Node2D and child != self and child != front_layer and child != middle_layer and child != back_layer:
			objects_to_sort.append(child)
			print("Object to sort: " + child.name + " at Y=" + str(child.position.y))
	
	print("Found " + str(objects_to_sort.size()) + " objects to sort")
	
	# Сортуємо об'єкти по шарах
	for obj in objects_to_sort:
		var y_pos = obj.position.y
		var layer_index = get_layer_index_for_position(y_pos)
		
		# Встановлюємо змінну layer в об'єкті, якщо можливо
		if "layer" in obj:
			obj.layer = layer_index
		
		print("Assigning " + obj.name + " at Y=" + str(y_pos) + " to layer " + str(layer_index))
		
		# Зберігаємо глобальну позицію і оригінальний масштаб
		var global_pos = obj.global_position
		var target_scale
		
		if respect_original_scale and original_scales.has(obj):
			var original_scale = original_scales[obj]
			target_scale = Vector2(original_scale.x * scales[layer_index], 
								   original_scale.y * scales[layer_index])
			print("Using saved original scale: " + str(original_scale))
		else:
			target_scale = Vector2(scales[layer_index], scales[layer_index])
			print("No saved scale, using direct scale factor: " + str(scales[layer_index]))
		
		# Видаляємо з поточного батька
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		
		# Визначаємо цільовий шар
		var target_layer
		match layer_index:
			LAYER.FRONT: target_layer = front_layer
			LAYER.MID: target_layer = middle_layer
			LAYER.BACK: target_layer = back_layer
		
		# Додаємо до цільового шару
		target_layer.add_child(obj)
		
		# Відновлюємо глобальну позицію
		obj.global_position = global_pos
		
		# Встановлюємо масштаб
		obj.scale = target_scale
		
		print("Object " + obj.name + " moved to layer " + str(layer_index) + 
			" with scale " + str(obj.scale))

# Метод для ручного сортування через інспектор
func organize_now():
	print("Manual organization requested")
	if Engine.is_editor_hint():
		print("Cannot organize in editor, only update scales")
		update_scales_in_editor()
	else:
		organize_objects_for_game()

func move_to_layer(obj: Node2D, target_layer_index: int, transition_duration: float = 0.5):
	# Перевірка коректності вхідних даних
	if not obj or target_layer_index < 0 or target_layer_index > 2:
		print("Invalid layer movement request")
		return
	
	# Визначаємо поточний шар об'єкта
	var current_layer_index = -1
	var current_parent = obj.get_parent()
	
	if current_parent == front_layer:
		current_layer_index = LAYER.FRONT
	elif current_parent == middle_layer:
		current_layer_index = LAYER.MID
	elif current_parent == back_layer:
		current_layer_index = LAYER.BACK
	
	# Встановлюємо змінну layer в об'єкті
	if "layer" in obj:
		obj.layer = target_layer_index
	
	# Визначаємо цільовий шар
	var target_layer
	match target_layer_index:
		LAYER.FRONT: target_layer = front_layer
		LAYER.MID: target_layer = middle_layer
		LAYER.BACK: target_layer = back_layer
	
	# Перевірка, чи існує цільовий шар
	if not target_layer:
		print("Target layer not found")
		return
	
	# Збереження глобальної позиції
	var global_pos = obj.global_position
	
	# Визначаємо цільовий масштаб
	var target_scale
	if respect_original_scale and original_scales.has(obj):
		var original_scale = original_scales[obj]
		target_scale = Vector2(
			original_scale.x * scales[target_layer_index], 
			original_scale.y * scales[target_layer_index]
		)
	else:
		target_scale = Vector2(scales[target_layer_index], scales[target_layer_index])
	
	# Видаляємо з поточного батька
	if current_parent:
		current_parent.remove_child(obj)
	
	# Додаємо до цільового шару
	target_layer.add_child(obj)
	
	# Відновлюємо глобальну позицію
	obj.global_position = global_pos
	
	# Створюємо твін для плавної зміни позиції та масштабу
	var tween = get_tree().create_tween()
	
	# Встановлюємо Y-координату цільового шару
	var target_y_pos = y_positions[target_layer_index]
	
	# Твін позиції
	tween.tween_property(obj, "position:y", target_y_pos, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Твін масштабу
	tween.parallel().tween_property(obj, "scale", target_scale, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Блокуємо input під час руху
	obj.set_process_input(false)
	
	emit_signal("layer_changed", obj, current_layer_index, target_layer_index)
	
	# Розблоковуємо input після завершення руху
	tween.tween_callback(func(): 
		obj.set_process_input(true)
	)
	
	# Додаткове логування
	print("Moving " + obj.name + " to layer " + str(target_layer_index) + 
		" with target Y=" + str(target_y_pos) + 
		" and scale " + str(target_scale))
