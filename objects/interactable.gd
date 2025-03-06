# Interactable.gd (modified)
extends Area2D
class_name Interactable

@export var interaction_text: String = "Interact"
@export var layer: int = 0  # Default to front layer

signal interaction_activated(interactable)

func _ready():
	# Add to the interactables group so main can find it
	add_to_group("interactables")

func interact():
	# Base method to be overridden by child classes
	interaction_activated.emit(self)

func show_interaction_promt():
	%InteractionLabel.visible = true
	
func hide_interaction_promt():
	%InteractionLabel.visible = false
