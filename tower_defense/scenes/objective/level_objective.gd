class_name LevelObjective extends Node2D

@onready var objective_area: Area2D = $ObjectiveArea
@export var health: float = 10.0

func _ready() -> void:
	objective_area.setup(self)

func take_damage(incoming_damage: float) -> void:
	health -= incoming_damage
	#if health <= 0.0:
		#queue_free()
	


func _on_objective_area_area_entered(area: Area2D) -> void:
	if area.get_parent() is Enemy:
		take_damage(area.get_parent().damage)
