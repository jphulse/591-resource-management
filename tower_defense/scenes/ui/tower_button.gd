extends MarginContainer

@export var tower_scene : PackedScene
@export var texture_sprite: Texture2D

@onready var texture_button : TextureButton = $TextureButton

signal tower_button_pressed(tower_scene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_button.texture_normal  = texture_sprite


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_pressed() -> void:
	tower_button_pressed.emit(tower_scene)
