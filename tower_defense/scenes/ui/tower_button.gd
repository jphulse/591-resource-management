extends MarginContainer

@export var tower_scene : PackedScene

@onready var texture_button : TextureButton = $TextureButton

signal tower_button_pressed(tower_scene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_pressed() -> void:
	tower_button_pressed.emit(tower_scene)
