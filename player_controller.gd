extends CharacterBody2D

# Налаштування руху
@export var speed: float = 200.0
@export var layer_manager_path: NodePath
@export var layer_manager: LayerManager

# Налаштування анімації
@export var has_animations: bool = false
@export var animation_player_path: NodePath
@onready var animation_player = get_node_or_null(animation_player_path) if has_animations else null

# Поточний шар персонажа (0 - передній, 1 - середній, 2 - задній)
var current_layer = 0  # Починаємо з переднього шару

# Прапорець блокування руху під час переходу між шарами
var is_layer_transitioning = false

func _ready() -> void:
	move_to_new_layer(current_layer)

func _process(delta: float) -> void:
	# Забороняємо рух під час переходу між шарами
	if is_layer_transitioning:
		return
	
	# Горизонтальний рух
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	
	# Зміна напрямку спрайту (якщо є)
	if direction < 0 and has_node("Sprite2D"):
		$Sprite2D.flip_h = true
	elif direction > 0 and has_node("Sprite2D"):
		$Sprite2D.flip_h = false
	
	# Рух між шарами (вперед/назад по глибині)
	if Input.is_action_just_pressed("ui_down") and current_layer > 0 and layer_manager:
		# Рух до камери (зменшення шару)
		move_to_new_layer(current_layer - 1)
		
	if Input.is_action_just_pressed("ui_up") and current_layer < 2 and layer_manager:
		# Рух від камери (збільшення шару)
		move_to_new_layer(current_layer + 1)
	
	move_and_slide()
	
	# Оновлення анімації
	update_animation(direction)

# Метод для переміщення на новий шар з анімацією
func move_to_new_layer(new_layer: int):
	if new_layer == current_layer:
		return
	
	# Блокуємо рух під час переходу
	is_layer_transitioning = true
	
	# Запам'ятовуємо старий шар для анімації
	var old_layer = current_layer
	current_layer = new_layer
	
	# Запускаємо анімацію переходу між шарами
	play_layer_transition_animation(old_layer, new_layer)
	
	# Переміщуємо персонажа на новий шар
	layer_manager.move_to_layer(self, new_layer)
	
	# Створюємо таймер для розблокування руху після завершення переходу
	var timer = get_tree().create_timer(0.5)  # Час має збігатися з тривалістю переходу в LayerManager
	timer.timeout.connect(func(): 
		is_layer_transitioning = false
	)

# Метод для оновлення анімації руху
func update_animation(direction: float):
	if not has_animations or animation_player == null:
		return
		
	if direction != 0:
		if animation_player.has_animation("walk"):
			if animation_player.current_animation != "walk":
				animation_player.play("walk")
	else:
		if animation_player.has_animation("idle"):
			if animation_player.current_animation != "idle":
				animation_player.play("idle")

# Анімація переходу між шарами
func play_layer_transition_animation(from_layer: int, to_layer: int):
	if not has_animations or animation_player == null:
		return
		
	# Перевіряємо, чи є відповідні анімації
	var anim_name = ""
	
	if from_layer < to_layer:
		# Рух назад (вглиб)
		anim_name = "move_back"
	else:
		# Рух вперед (до камери)
		anim_name = "move_front"
	
	# Відтворюємо анімацію, якщо вона існує
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
