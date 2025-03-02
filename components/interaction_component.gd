extends Area2D
class_name InteractionComponent

signal interaction_prompt_changed(text)
signal interaction_prompt_hidden

var current_interactable: Interactable = null
var interactables_in_range: Array[Interactable] = []

func _ready() -> void:
	area_entered.connect(_on_detection_area_entered)
	area_exited.connect(_on_detection_area_exited)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and current_interactable != null:
		current_interactable.interact()

func _on_detection_area_entered(area: Area2D) -> void:
	if area is Interactable:
		# Перевірка, чи об'єкт знаходиться на тому ж шарі, що й гравець
		var player = get_parent() as PlayerController
		if player and player.layer != area.layer:
			return
			
		# Додаємо до списку доступних
		if not interactables_in_range.has(area):
			interactables_in_range.append(area)
		
		print(area.name)
		# Оновлюємо поточний інтерактивний об'єкт
		update_current_interactable()

func _on_detection_area_exited(area: Area2D) -> void:
	if area is Interactable:
		# Видаляємо зі списку доступних
		if interactables_in_range.has(area):
			interactables_in_range.erase(area)
			
		# Якщо вийшли з поточного об'єкта, оновлюємо або ховаємо підказку
		if current_interactable == area:
			if interactables_in_range.is_empty():
				current_interactable.hide_interaction_promt()
				current_interactable = null
			else:
				update_current_interactable()

# Функція для оновлення поточного інтерактивного об'єкта на основі пріоритету
func update_current_interactable() -> void:
	if interactables_in_range.is_empty():
		if current_interactable != null:
			current_interactable.hide_interaction_promt()
			current_interactable = null
			interaction_prompt_hidden.emit()
		return
	
	# Знаходимо найближчий об'єкт
	var player_pos = global_position
	var closest_interactable: Interactable = null
	var closest_distance: float = INF
	
	for interactable in interactables_in_range:
		var distance = player_pos.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable
	
	# Якщо змінився поточний об'єкт
	if closest_interactable != current_interactable:
		if current_interactable != null:
			current_interactable.hide_interaction_promt()
		
		current_interactable = closest_interactable
		current_interactable.show_interaction_promt()
		interaction_prompt_changed.emit(current_interactable.interaction_text)

# Оновлюємо список доступних об'єктів при зміні шару гравця
func on_player_layer_changed(new_layer: int) -> void:
	var updated_interactables: Array[Interactable] = []
	
	# Перевіряємо всі поточні інтерактивні об'єкти
	for interactable in interactables_in_range:
		if interactable.layer == new_layer:
			updated_interactables.append(interactable)
	
	# Оновлюємо список
	interactables_in_range = updated_interactables
	
	# Оновлюємо поточний об'єкт
	update_current_interactable()
