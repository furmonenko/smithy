extends Camera2D

# Налаштування камери
@export var follow_player: bool = true

# Налаштування зуму для кожного шару
@export var layer_zooms: Array[float] = [1.0, 1.1, 1.2]
# Швидкість зміни зуму та позиції
@export var transition_speed: float = 2.0

# Змінні
@export var player: Node2D
@export var layer_manager: LayerManager

var target_zoom: Vector2 = Vector2(1, 1)
var target_position: Vector2 = Vector2.ZERO
var current_layer: int = 0
var initial_offset: Vector2 = Vector2.ZERO
var layer_offsets: Array[Vector2] = [
	Vector2(0, 0),       # Передній шар (без зміщення)
	Vector2(0, 60),     # Середній шар (невелике зміщення вгору)
	Vector2(0, 100)      # Задній шар (більше зміщення вгору)
]

func _ready():
	# Отримуємо посилання на гравця
	if layer_manager.has_signal("layer_changed"):
		layer_manager.layer_changed.connect(_on_layer_changed)
		print("DepthCamera: Підключено до сигналу layer_changed")
	else:
		print("DepthCamera: Менеджер шарів не знайдено! Перевірте шлях.")
	
	# Зберігаємо початкове зміщення камери
	initial_offset = offset
	
	# Встановлюємо початковий зум та зміщення
	if player and player.has_method("get_current_layer"):
		current_layer = player.get_current_layer()
	else:
		current_layer = 0  # За замовчуванням - передній шар
		
	target_zoom = Vector2(layer_zooms[current_layer], layer_zooms[current_layer])
	target_position = Vector2.ZERO

func _process(delta):
	# Плавно змінюємо зум
	zoom = zoom.lerp(target_zoom, transition_speed * delta)
	
	# Плавно змінюємо зміщення
	offset = offset.lerp(initial_offset + layer_offsets[current_layer], transition_speed * delta)
	
# Обробник зміни шару
func _on_layer_changed(object, old_layer, new_layer):
	# Перевіряємо, чи це наш гравець змінив шар
	if object == player:
		update_camera_for_layer(new_layer)

# Оновлення камери при зміні шару
func update_camera_for_layer(new_layer: int):
	current_layer = new_layer
	
	# Оновлюємо цільовий зум
	if new_layer >= 0 and new_layer < layer_zooms.size():
		target_zoom = Vector2(layer_zooms[new_layer], layer_zooms[new_layer])
	
	print("DepthCamera: Оновлення для шару ", new_layer, ", новий зум: ", target_zoom)

# Публічний метод для встановлення шару напряму
func set_layer(layer: int):
	if layer >= 0 and layer < layer_zooms.size():
		update_camera_for_layer(layer)
