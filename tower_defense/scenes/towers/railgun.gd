extends TowerBase

@onready var railgun_projectile : rail_projectile = $rail_projectile
@onready var delay : Timer = $Delay_Timer

func _ready() -> void:
	super()
	animated_radar.play()
	hitbox.setup(self)
	attack_area.setup(self, damage)
	update_health_bar()
	railgun_projectile.damage = damage

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if enemies && can_attack:
		attack()

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
				
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		
		if railgun_projectile.collider_bar.shape:
			query.shape_rid = railgun_projectile.collider_bar.shape.get_rid()
			
			# THE SMART FIX: Combine the global position with the local offset
			# We multiply the global_transform by the local transform of the collider node
			# This ensures the physics 'sees' the 1000px offset you set in the editor!
			query.transform = railgun_projectile.global_transform * railgun_projectile.collider_bar.transform
			
			query.collision_mask = railgun_projectile.collision_mask
			query.collide_with_areas = true
			query.collide_with_bodies = false
			
			var results = space_state.intersect_shape(query, 1000)
			
			# Track hits to avoid double-damaging one enemy with multiple hitboxes
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
