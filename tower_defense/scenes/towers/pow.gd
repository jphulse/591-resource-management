extends TowerBase

@onready var radiator : AnimatedSprite2D = $AnimatedRadiator

func attack() -> void:
	if can_attack:
		can_attack = false
		
		#MUZZLE FLASH LOGIC
		var barrel_material = animated_barrel.material as ShaderMaterial
		
		if barrel_material:
			var flash_tween = create_tween()
			
			barrel_material.set_shader_parameter("flash_intensity", .4)
			
			flash_tween.tween_property(barrel_material, 
				"shader_parameter/flash_intensity", 0.0, attack_cooldown/1.5).set_ease(Tween.EASE_OUT)

		var bullet: Bullet = bullet_scene.instantiate()
		projectiles_list.add_child(bullet)
		bullet.setup(self.global_position, PI/2, damage, projectile_speed, bullet_color)
		
		animated_barrel.frame = 0
		animated_barrel.play()
		radiator.frame = 0
		radiator.play()
		audio_player.stream = cannon_sounds.pick_random()
		audio_player.play()
		
		attack_cooldown_timer.start(attack_cooldown)
