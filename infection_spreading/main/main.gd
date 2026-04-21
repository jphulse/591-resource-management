class_name PIMain
extends Node2D

@onready var solar_system_stage : MapStage = %SolarSystemStage
@onready var map_camera : Camera2D = %MapCamera
@onready var clicker : InfectionClicker = $CanvasLayer/MainUi/TabContainer/Clicker


func _ready() -> void:
	solar_system_stage.clicker = clicker
	solar_system_stage.initialize_stage()
	map_camera.zoom = Vector2.ONE

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("uid://cxby1rpj5kclj")
