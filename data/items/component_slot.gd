# Слот для компонентів
extends Slot
class_name ComponentSlot

@export var allowed_component: SimpleItem  # Зразок компонента, який можна використати в слоті

var assigned_components: Array[SimpleItem] = []  # Масив призначених компонентів

# Отримати поточну кількість компонентів
func get_current_quantity() -> int:
	return assigned_components.size()

# Очистити слот
func clear() -> void:
	assigned_components.clear()
	super()

# Додати компонент у слот
func assign_component(component: SimpleItem) -> bool:
	# Перевірка на відповідність типу
	if is_component_valid(component):
		# Перевірка чи слот не переповнений
		if can_add_more():
			assigned_components.append(component)
			
			# Перерахувати якість
			update_quality()
			
			# Відправити сигнал про додавання компонента
			content_added.emit(component)
			
			# Перевірити чи слот заповнений і відправити сигнал якщо так
			if is_filled() and get_current_quantity() == quantity:
				slot_filled.emit(self)
				
			return true
	return false

# Перевірити чи компонент підходить для цього слота
func is_component_valid(component: SimpleItem) -> bool:
	# Якщо не вказано зразка, приймаємо будь-який компонент
	if allowed_component == null:
		return true
	
	# Виклик відповідної функції перевірки залежно від типу компонента
	if component is WeaponComponent:
		return is_weapon_component_valid(component)
	elif component is ArmorComponent:
		return is_armor_component_valid(component)
	elif component is ToolComponent:
		return is_tool_component_valid(component)
	else:
		return false
	
	# Якщо це невідомий тип, але скрипт той самий, то вважаємо валідним
	return true

# Перевірка компонентів зброї
func is_weapon_component_valid(component: SimpleItem) -> bool:
	# Компоненти одноручної ріжучої зброї
	if component is OneHandedCutWeaponComponent and allowed_component is OneHandedCutWeaponComponent:
		var test_component = component as OneHandedCutWeaponComponent
		var allowed = allowed_component as OneHandedCutWeaponComponent
		
		# Перевірити потрібний тип (якщо він вказаний)
		if allowed.one_handed_cut_weapon_type != -1 and test_component.one_handed_cut_weapon_type != allowed.one_handed_cut_weapon_type:
			return false
	
	# Компоненти дворучної ріжучої зброї
	elif component is LongCutWeaponComponent and allowed_component is LongCutWeaponComponent:
		var test_component = component as LongCutWeaponComponent
		var allowed = allowed_component as LongCutWeaponComponent
		
		if allowed.long_cut_weapon_type != -1 and test_component.long_cut_weapon_type != allowed.long_cut_weapon_type:
			return false
	
	# Компоненти древкової зброї
	elif component is PoleWeaponComponent and allowed_component is PoleWeaponComponent:
		var test_component = component as PoleWeaponComponent
		var allowed = allowed_component as PoleWeaponComponent
		
		if allowed.pole_weapon_type != -1 and test_component.pole_weapon_type != allowed.pole_weapon_type:
			return false
	
	# Компоненти важкої зброї
	elif component is HeavyWeaponComponent and allowed_component is HeavyWeaponComponent:
		var test_component = component as HeavyWeaponComponent
		var allowed = allowed_component as HeavyWeaponComponent
		
		if allowed.heavy_weapon_type != -1 and test_component.heavy_weapon_type != allowed.heavy_weapon_type:
			return false
	
	# Компоненти кинджалів
	elif component is DaggerComponent and allowed_component is DaggerComponent:
		var test_component = component as DaggerComponent
		var allowed = allowed_component as DaggerComponent
		
		if allowed.dagger_type != -1 and test_component.dagger_type != allowed.dagger_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true

# Перевірка компонентів броні
func is_armor_component_valid(component: SimpleItem) -> bool:
	# Компоненти захисту голови
	if component is HeadArmorComponent and allowed_component is HeadArmorComponent:
		var test_component = component as HeadArmorComponent
		var allowed = allowed_component as HeadArmorComponent
		
		if allowed.head_armor_type != -1 and test_component.head_armor_type != allowed.head_armor_type:
			return false
	
	# Компоненти захисту тіла
	elif component is BodyArmorComponent and allowed_component is BodyArmorComponent:
		var test_component = component as BodyArmorComponent
		var allowed = allowed_component as BodyArmorComponent
		
		if allowed.body_armor_type != -1 and test_component.body_armor_type != allowed.body_armor_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true

# Перевірка компонентів інструментів
func is_tool_component_valid(component: SimpleItem) -> bool:
	if component is ToolComponent and allowed_component is ToolComponent:
		var test_component = component as ToolComponent
		var allowed = allowed_component as ToolComponent
		
		if allowed.tool_type != -1 and test_component.tool_type != allowed.tool_type:
			return false
	
	# Якщо дійшли до тут, це означає, що перевірки пройдені успішно або тип не розпізнаний
	return true
	
# Видалити компонент зі слота
func remove_component(index: int) -> SimpleItem:
	if index >= 0 and index < assigned_components.size():
		var component = assigned_components[index]
		assigned_components.remove_at(index)
		
		# Перерахувати якість
		update_quality()
		
		# Відправити сигнал про видалення компонента
		content_removed.emit(component)
		
		return component
	return null

# Розрахувати середню якість компонентів у слоті
func calculate_average_quality() -> float:
	if assigned_components.is_empty():
		return 0.0
	
	var total_quality = 0.0
	for component in assigned_components:
		total_quality += component.calculate_quality()
	
	return total_quality / assigned_components.size()

# Отримати всі компоненти
func get_all_components() -> Array[SimpleItem]:
	return assigned_components
