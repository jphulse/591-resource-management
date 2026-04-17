class_name Enemy extends Node2D

@onready var hitbox: Area2D = $EnemyHitbox
@onready var attack_area: Area2D = $EnemyAttackArea
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

@export var damage: float = 5.0
@export var health: float = 10.0
@export var movement_speed: float = 80.0
@export var attack_cooldown: float = 0.5

var in_attack_range: bool = false
var can_attack: bool = true
var towers_in_range: Array = []

var path_follow: PathFollow2D

func _ready() -> void:
	hitbox.setup(self)
	attack_area.setup(self, damage)

func _process(delta: float) -> void:
	if path_follow:
		if not towers_in_range:
			path_follow.progress += movement_speed * delta
		else:
			if can_attack:
				attack()
		
		if path_follow.progress_ratio >= 0.99:
			queue_free()

func add_path_follow(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	
func death_sequence() -> void:
	pass

func attack() -> void:
	if not towers_in_range:
		return
	can_attack = false
	
	var target: Area2D = towers_in_range[0]
	if target and is_instance_valid(target):
		target.parent.take_damage(damage)
	
	attack_cooldown_timer.start(attack_cooldown)

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		death_sequence()
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
