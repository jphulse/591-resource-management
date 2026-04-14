class_name Bullet extends Area2D

var projectile_speed: float = 200.0
var direction: Vector2

func _process(delta: float) -> void:
	global_position += direction * projectile_speed * delta
	print(global_position)

func setup(new_position: Vector2, new_angle: float) -> void:
	print("POS", new_position)
	global_position = new_position
	direction = Vector2.UP.rotated(new_angle)
	rotation = new_angle
