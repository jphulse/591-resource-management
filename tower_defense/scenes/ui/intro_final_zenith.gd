extends Control

@onready var text1 : Label = self.find_child("Label")
@onready var text2 : Label = self.find_child("Label2")
@onready var text3 : Label = self.find_child("Label3")
@onready var text4 : Label = self.find_child("Label4")
@onready var text5 : Label = self.find_child("Label5")
@onready var text6 : Label = self.find_child("Label6")
@onready var text7 : Label = self.find_child("Label7")
@onready var text8 : Label = self.find_child("Label8")

@export var next_scene : PackedScene

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(text1, "modulate", Color(1,1,1), 2.0)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("uid://cxby1rpj5kclj")

func _on_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text2, "modulate", Color(1,1,1), 2.0)

func _on_timer_2_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text3, "modulate", Color(1,1,1), 2.0)

func _on_timer_3_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text4, "modulate", Color(1,1,1), 2.0)

func _on_timer_4_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text5, "modulate", Color(1,1,1), 2.0)

func _on_timer_5_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text6, "modulate", Color(1,1,1), 2.0)

func _on_timer_6_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text7, "modulate", Color(0,.6,1), 2.0)

func _on_timer_7_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(text8, "modulate", Color(0,.6,1), 2.0)
	
	var list_tween = create_tween().set_parallel(true)
	list_tween.tween_property(text1, "modulate", Color(0,0,0), 3.0)
	list_tween.tween_property(text2, "modulate", Color(0,0,0), 3.33)
	list_tween.tween_property(text3, "modulate", Color(0,0,0), 3.66)
	list_tween.tween_property(text4, "modulate", Color(0,0,0), 4.0)
	list_tween.tween_property(text5, "modulate", Color(0,0,0), 4.33)
	list_tween.tween_property(text6, "modulate", Color(0,0,0), 5.0)

func _on_timer_8_timeout() -> void:
	var tween = create_tween()
	var tween2 = create_tween()
	tween.tween_property(text7, "modulate", Color(0,0,0), 3.0)
	tween2.tween_property(text8, "modulate", Color(0,0,0), 3.0)


func _on_audio_stream_player_finished() -> void:
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)
