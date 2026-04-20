class_name ClickerTreeButton extends TextureButton

@export var minimum_size : Vector2 = Vector2(128.0, 128.0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.custom_minimum_size = minimum_size
	stretch_mode = TextureButton.STRETCH_SCALE
	ignore_texture_size = true
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	update_minimum_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
