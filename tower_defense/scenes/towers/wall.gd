class_name Wall extends TowerBase

@onready var wall_sprite : AnimatedSprite2D = $AnimatedWall

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	
func _process(delta: float) -> void:
	pass

func _on_detection_range_area_entered(area: Area2D) -> void:
	pass


func _on_detection_range_area_exited(area: Area2D) -> void:
	pass


func _on_attack_cooldown_timer_timeout() -> void:
	pass


func attack() -> void:
	pass

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health > 375:
		wall_sprite.frame = 0
	elif health > 250:
		wall_sprite.frame = 1
	elif health > 125:
		wall_sprite.frame = 2
	elif health > 0:
		wall_sprite.frame = 3
	elif health <= 0.0:
		defense_destroyed.emit(-building_value)
		queue_free()
	update_health_bar()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is EnemyAttackArea:
		take_damage(area.damage)
