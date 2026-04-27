extends TowerBase

@onready var railgun_projectile : rail_projectile = $rail_projectile
@onready var delay : Timer = $Delay_Timer

func _ready() -> void:
	super()
	hitbox.setup(self)
	attack_area.setup(self, damage)
	update_health_bar()
	railgun_projectile.damage = damage

func attack() -> void:
	if can_attack:
		can_attack = false
		
		#MUZZLE FLASH LOGIC
		var barrel_material = animated_barrel.material as ShaderMaterial
		
		if barrel_material:
			var flash_tween = create_tween()
			
			barrel_material.set_shader_parameter("flash_intensity", .5)
			
			flash_tween.tween_property(barrel_material, 
				"shader_parameter/flash_intensity", 0.0, 4).set_ease(Tween.EASE_OUT)
		
		#grab link to the physics engine
		var space_state = get_world_2d().direct_space_state
		#specify to search for 2D physics shapes (2D colliders I believe)
		var query = PhysicsShapeQueryParameters2D.new()
		
		#this assumes that the collider for the railgun projectile - the thing being used to scan
		# for enemies exists - checks if it has an assigned shape
		if railgun_projectile.collider_bar.shape:
			
			#grab the ID - will be used to query the physics engine
			query.shape_rid = railgun_projectile.collider_bar.shape.get_rid()
			
			#adjust to be accurate with real space railgun bar
			query.transform = railgun_projectile.global_transform * railgun_projectile.collider_bar.transform
			
			# match collision mask of railgun bar
			query.collision_mask = railgun_projectile.collision_mask
			
			# we want area2D thingies only
			query.collide_with_areas = true
			query.collide_with_bodies = false
			
			#send it to engine
			var results = space_state.intersect_shape(query, 1000)
			
			var targets_hit = []
			
			for dictionary in results:
				var hit_node = dictionary["collider"]
				var target = hit_node.owner
				
				if target is Enemy and not target in targets_hit:
					target.take_damage(damage)
					targets_hit.append(target)
		
		# Feedback and Juice!
		railgun_projectile.sprite_rail.frame = 0
		railgun_projectile.sprite_rail.play()
		animated_barrel.frame = 0
		animated_barrel.play()
		
		audio_player.stream = cannon_sounds.pick_random()
		audio_player.play()
		
		attack_cooldown_timer.start(attack_cooldown)
		
		# Visuals and Feedback
		railgun_projectile.sprite_rail.play()
		animated_barrel.frame = 0
		animated_barrel.play()
		
		audio_player.stream = cannon_sounds.pick_random()
		audio_player.play()
		
		attack_cooldown_timer.start(attack_cooldown)
		
func _on_attack_cooldown_timer_timeout() -> void:
	delay.start(randf_range(0.0, 2.0))


func _on_delay_timer_timeout() -> void:
	can_attack = true
