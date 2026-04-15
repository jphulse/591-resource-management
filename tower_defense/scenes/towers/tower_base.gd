class_name TowerBase extends Node2D

@onready var bullet_scene: PackedScene = preload("res://tower_defense/scenes/projectiles/Bullet.tscn")
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var projectiles_list: Node2D = $Projectiles

@export var damage: float = 10.0
@export var health: float = 10.0
@export var projectile_speed: float = 200.0
@export var detection_range: float = 100.0
@export var attack_cooldown: float = 0.5

var enemies: Array = []
var can_attack: bool = true

func _ready() -> void:
	#print("Local Position:", position)
	#print("Global Position:", global_position)
	pass

func _process(delta: float) -> void:
	if enemies:
		attack()
	pass

func _on_detection_range_area_entered(area: Area2D) -> void:
	if area is EnemyHitbox and area not in enemies:
		#print("Enemy Detected!")
		enemies.append(area)

func _on_detection_range_area_exited(area: Area2D) -> void:
	if area in enemies:
		#print("Enemy Gone!")
		enemies.erase(area)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func attack() -> void:
	# Fire a projectile or something
	if can_attack:
		can_attack = false
		
		var bullet: Bullet = bullet_scene.instantiate()
		projectiles_list.add_child(bullet)
		bullet.setup(self.global_position, PI/2, damage)
		
		attack_cooldown_timer.start(attack_cooldown)
		
		#print("Attacking!", bullet)

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is EnemyAttackArea:
		take_damage(area.damage)
