class_name Enemy extends Node2D

@onready var hitbox: Area2D = $EnemyHitbox
@onready var attack_area: Area2D = $EnemyAttackArea
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var health_bar : ProgressBar = $ProgressBar

@export var damage: float = 5.0
@export var health: float = 10.0
@export var movement_speed: float = 80.0
@export var attack_cooldown: float = 0.5
@export var enemy_value : float = 20.0
@export var armour : int = 0

var current_move_speed : float = 80

signal enemy_death(value : int)

var in_attack_range: bool = false
var can_attack: bool = true
var towers_in_range: Array = []

var path_follow: PathFollow2D

func _ready() -> void:
	hitbox.setup(self)
	attack_area.setup(self, damage)
	health_bar.value = health
	health_bar.max_value = health

func _process(delta: float) -> void:
	if path_follow:
		if towers_in_range.size() < 1:
			current_move_speed = movement_speed
			path_follow.progress += movement_speed * delta
		else:
			current_move_speed = 0
			if can_attack:
				attack()
		
		if path_follow.progress_ratio >= 0.99:
			enemy_death.emit(-enemy_value)
			path_follow.queue_free()
			queue_free()

func add_path_follow(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	
func death_sequence() -> void:
	pass

func attack() -> void:
	if towers_in_range.size() < 1:
		return
	can_attack = false
	
	#grab link to the physics engine
	var space_state = get_world_2d().direct_space_state
	#specify to search for 2D physics shapes (2D colliders I believe)
	var query = PhysicsShapeQueryParameters2D.new()
	
	#this assumes that the collider for the railgun projectile - the thing being used to scan
	# for enemies exists - checks if it has an assigned shape
	if attack_area.collider.shape:
		
		#grab the ID - will be used to query the physics engine
		query.shape_rid = attack_area.collider.shape.get_rid()
		
		#adjust to be accurate with real space railgun bar
		query.transform = attack_area.global_transform * attack_area.collider.transform
		
		# match collision mask of railgun bar
		query.collision_mask = attack_area.collision_mask
		
		# we want area2D thingies only
		query.collide_with_areas = true
		query.collide_with_bodies = false
		
		#send it to engine
		var results = space_state.intersect_shape(query, 1000)
		
		var targets_hit = []
		
		for dictionary in results:
			var hit_area = dictionary["collider"]
			
			if hit_area is TowerHitbox:
				var root_node = hit_area.owner
				
				if root_node is TowerBase:
					if not root_node in targets_hit:
						root_node.take_damage(damage)
						targets_hit.append(root_node)
	
	attack_cooldown_timer.start(attack_cooldown)

func take_damage(incoming_damage: float) -> void:
	var total_incoming_damage = incoming_damage - armour
	if total_incoming_damage < .5 :
		total_incoming_damage = .2
	health = health - total_incoming_damage
	health_bar.value = health
	
	if health <= 0.0:
		death_sequence()
		enemy_death.emit(-enemy_value)
		path_follow.queue_free()
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)
		area.monitorable = false
		area.monitoring = false
		area.queue_free()
		
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
