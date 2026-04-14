class_name Enemy extends Node2D

@export var damage: float = 1.0
@export var health: float = 10.0
@export var speed: float = 100.0

var path_follow: PathFollow2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if path_follow:
		path_follow.progress += speed * delta
	if path_follow.progress_ratio >= 0.99:
		queue_free()

func add_path_follow(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
