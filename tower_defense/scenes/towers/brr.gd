extends TowerBase

@onready var radiator : AnimatedSprite2D = $AnimatedRadiator
@onready var attack_duration_timer : Timer = $AttackDurationTimer
@onready var attack_frequency_timer : Timer = $AttackFrequencyTimer

var firing = false

func attack() -> void:
	if can_attack:
		can_attack = false
		firing = true
		
		#MUZZLE FLASH LOGIC
		var barrel_material = animated_barrel.material as ShaderMaterial
		
		if barrel_material:
			var flash_tween = create_tween()
			
			barrel_material.set_shader_parameter("flash_intensity", .4)
			
			flash_tween.tween_property(barrel_material, 
				"shader_parameter/flash_intensity", 0.0, attack_cooldown/1.5).set_ease(Tween.EASE_OUT)
		
		animated_barrel.frame = 0
		animated_barrel.play()
		radiator.frame = 0
		radiator.play()
		audio_player.stream = cannon_sounds.pick_random()
		audio_player.play()
		
		attack_duration_timer.start(3.6) #duration of sound audio clip
		attack_frequency_timer.start()
		attack_cooldown_timer.start(attack_cooldown)


func _on_animated_barrel_animation_finished() -> void:
	if firing:
		animated_barrel.frame = 0
		animated_barrel.play()


func _on_attack_duration_timer_timeout() -> void:
	firing = false


func _on_attack_frequency_timer_timeout() -> void:
	if firing :
		attack_frequency_timer.start()
		var bullet: Bullet = bullet_scene.instantiate()
		projectiles_list.add_child(bullet)
		bullet.setup(self.global_position, (PI/2 + randf_range(-0.05, 0.05)), damage, projectile_speed, bullet_color)
