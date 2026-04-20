extends Enemy

signal ultimate_death()

func _process(delta: float) -> void:
	if path_follow:
		if not towers_in_range:
			path_follow.progress += movement_speed * delta
		else:
			if can_attack:
				attack()
		
		if path_follow.progress_ratio >= 0.99:
			enemy_death.emit(-enemy_value)
			ultimate_death.emit()
			queue_free()

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		death_sequence()
		ultimate_death.emit()
		enemy_death.emit(-enemy_value)
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)
		
	# Check to see if this is the end target to attack
	#if area is Area2D:
		#queue_free()

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area is TowerHitbox or area is ObjectiveArea:
		if area not in towers_in_range:
			towers_in_range.append(area)

func _on_attack_area_area_exited(area: Area2D) -> void:
	if area in towers_in_range:
		towers_in_range.erase(area)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true
