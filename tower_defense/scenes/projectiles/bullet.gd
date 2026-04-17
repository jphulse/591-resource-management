class_name Bullet extends Area2D

var projectile_speed: float = 500.0
var direction: Vector2
var damage: float

func _process(delta: float) -> void:
	global_position += direction * projectile_speed * delta
	check_despawn()

func setup(new_position: Vector2, new_angle: float, new_damage: float) -> void:
	global_position = new_position
	direction = Vector2.UP.rotated(new_angle)
	rotation = new_angle
	damage = new_damage

func check_despawn() -> void:
	if position.x > 2000.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is EnemyHitbox:
		queue_free()
