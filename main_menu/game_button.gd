extends Button

@export var packed_scene : PackedScene


func _on_pressed() -> void:
	if packed_scene != null:
		get_tree().change_scene_to_packed(packed_scene)
