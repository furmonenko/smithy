# Save order data to a resource
extends Resource
class_name OrdersData 

@export var active_orders: Array[Order]
@export var completed_orders: Array[Order]
@export var failed_orders: Array[Order]
@export var characters: Dictionary

# Save orders data
func save_orders(save_path: String = "user://orders_save.tres") -> Error:
	var save_data = OrdersData.new()
	
	save_data.active_orders = active_orders
	save_data.completed_orders = completed_orders
	save_data.failed_orders = failed_orders
	save_data.characters = characters
	
	return ResourceSaver.save(save_data, save_path)

# Load orders data
func load_orders(save_path: String = "user://orders_save.tres") -> Error:
	if not FileAccess.file_exists(save_path):
		return ERR_FILE_NOT_FOUND
	
	var save_data = ResourceLoader.load(save_path)
	if save_data is OrdersData:
		active_orders = save_data.active_orders
		completed_orders = save_data.completed_orders
		failed_orders = save_data.failed_orders
		characters = save_data.characters
		return OK
	
	return ERR_INVALID_DATA
