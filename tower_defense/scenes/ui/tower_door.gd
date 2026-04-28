extends AnimatedSprite2D

@export var destroy_on_start = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if destroy_on_start :
		play()

func _process(delta: float) -> void:
	pass
	
func _on_animation_finished() -> void:
	queue_free()
