class_name TowerBase extends Node2D

@onready var bullet_scene: PackedScene = preload("res://tower_defense/scenes/projectiles/Bullet.tscn")
@onready var hitbox: Area2D = $TowerHitbox
@onready var attack_area: Area2D = $TowerAttackRange
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var projectiles_list: Node2D = $Projectiles
@onready var health_bar: TextureProgressBar = $HealthBar

@export var damage: float = 10.0
@export var max_health: float = 40.0
@export var health: float = 40.0
@export var projectile_speed: float = 500.0
@export var attack_cooldown: float = 0.5

var enemies: Array = []
var can_attack: bool = true

func _ready() -> void:
	hitbox.setup(self)
	attack_area.setup(self, damage)
	update_health_bar()

func _process(delta: float) -> void:
	if enemies:
		attack()

func _on_detection_range_area_entered(area: Area2D) -> void:
	if area is EnemyHitbox and area not in enemies:
		enemies.append(area)

func _on_detection_range_area_exited(area: Area2D) -> void:
	if area in enemies:
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

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		queue_free()
	update_health_bar()

func update_health_bar() -> void:
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is EnemyAttackArea:
		take_damage(area.damage)
