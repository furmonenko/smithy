extends Node2D

# Оригінальні налаштування камери
var original_camera_offset: Vector2
var original_camera_zoom: Vector2
var mini_game_instance = null
var сamera_in_mini_game_mode: bool = false  # Прапорець для контролю режиму камери

# Налаштування камери для міні-гри
@export var mini_game_camera_zoom: Vector2 = Vector2(0.8, 0.8)
@export var mini_game_camera_offset: Vector2 = Vector2(200, 0)
@export var transition_duration: float = 0.3

# Отримуємо посилання на гравця та камеру
@onready var player: PlayerController = %Blacksmith
@onready var camera: Camera2D = $Blacksmith/Camera2D

func _ready():
	сonnect_interactables()

func сonnect_interactables():
	var interactables = get_tree().get_nodes_in_group("interactables")
	for interactable in interactables:
		if interactable.has_signal("interaction_activated"):
			if not interactable.is_connected("interaction_activated", on_interactable_activated):
				interactable.interaction_activated.connect(on_interactable_activated)

func on_interactable_activated(interactable):
	if interactable.has_method("get_mini_game_scene"):
		var mini_game_scene = interactable.get_mini_game_scene()
		if mini_game_scene:
			start_mini_game(mini_game_scene, interactable)

func start_mini_game(mini_game_scene: PackedScene, source_interactable = null):
	# Не запускаємо, якщо міні-гра вже активна
	if mini_game_instance != null:
		return
	
	# Перевіряємо наявність гравця та камери
	if not player or not camera:
		return
	
	# Повідомляємо камері, що ми переходимо в режим міні-гри
	if camera.has_method("set_mini_game_mode"):
		camera.set_mini_game_mode(true)
	else:
		# Якщо метод не існує, додаємо тимчасовий прапорець
		сamera_in_mini_game_mode = true
	
	# Зберігаємо оригінальні налаштування камери
	original_camera_offset = camera.offset
	original_camera_zoom = camera.zoom
	
	# Вимикаємо управління гравцем
	disable_player_controls(true)
	
	# Встановлюємо нові значення безпосередньо, щоб уникнути поступової зміни в _process
	var direct_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	direct_tween.tween_property(camera, "offset", mini_game_camera_offset, transition_duration)
	direct_tween.parallel().tween_property(camera, "zoom", mini_game_camera_zoom, transition_duration)
	
	# Чекаємо завершення анімації камери
	await direct_tween.finished
	
	# Створюємо екземпляр міні-гри
	mini_game_instance = mini_game_scene.instantiate()
	add_child(mini_game_instance)
	
	# Підключаємо сигнали міні-гри
	mini_game_instance.mini_game_completed.connect(_on_mini_game_completed)
	mini_game_instance.mini_game_cancelled.connect(_on_mini_game_cancelled)
	
	# Запускаємо міні-гру
	mini_game_instance.start_game()

func _on_mini_game_completed(success, score):
	print("Міні-гра завершена. Успіх: ", success, " Рахунок: ", score)
	_cleanup_mini_game()

func _on_mini_game_cancelled():
	print("Міні-гра скасована.")
	_cleanup_mini_game()

func _cleanup_mini_game():
	# Повертаємо камеру в звичайний режим
	if camera.has_method("set_mini_game_mode"):
		camera.set_mini_game_mode(false)
	else:
		сamera_in_mini_game_mode = false
	
	# Створюємо tween для повернення налаштувань камери
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "offset", original_camera_offset, transition_duration)
	tween.parallel().tween_property(camera, "zoom", original_camera_zoom, transition_duration)
	
	# Чекаємо завершення анімації камери
	await tween.finished
	
	# Повертаємо управління гравцем
	disable_player_controls(false)
	
	# Очищаємо екземпляр міні-гри
	if mini_game_instance:
		mini_game_instance.queue_free()
		mini_game_instance = null

func disable_player_controls(disabled: bool):
	if player:
		player.set_process(not disabled)
		player.set_process_input(not disabled)
		player.set_process_unhandled_input(not disabled)
		player.set_physics_process(not disabled)
		
		# Якщо у гравця є компонент взаємодії, вимикаємо і його
		var interaction_component = player.get_node_or_null("%InteractionArea")
		if interaction_component:
			interaction_component.set_process(not disabled)
			interaction_component.set_process_input(not disabled)
