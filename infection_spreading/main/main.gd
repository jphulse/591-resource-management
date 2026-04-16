class_name PIMain
extends Node2D

@onready var solar_system_stage : MapStage = %SolarSystemStage
@onready var map_camera : Camera2D = %MapCamera


func _ready() -> void:
	solar_system_stage.initialize_stage()
	map_camera.zoom = Vector2.ONE
