class_name TowerBase extends Node2D

@onready var sprite_node : Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $TowerHitbox
@onready var attack_area: Area2D = $TowerAttackRange
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var projectiles_list: Node2D = $Projectiles
@onready var health_bar: ProgressBar = $HealthBar
@onready var animated_radar : AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_barrel : AnimatedSprite2D = $AnimatedBarrel
@onready var audio_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var bullet_scene: PackedScene = preload("res://tower_defense/scenes/projectiles/Bullet.tscn")
@export var damage: float = 10.0
@export var max_health: float = 40.0
@export var health: float = 40.0
@export var projectile_speed: float = 500.0
@export var attack_cooldown: float = 0.5
@export var building_value: float = 75.0
@export var cannon_sounds: Array[AudioStream]
@export var bullet_color: Color
@export var cost : int

signal defense_built(value : int)
signal defense_destroyed(value: int)

var enemies: Array = []
var can_attack: bool = true

func _ready() -> void:
	if animated_barrel.material:
		animated_barrel.material = animated_barrel.material.duplicate()
	animated_radar.play()
	health_bar.max_value = max_health
	health_bar.value = health

func _process(delta: float) -> void:
	if enemies:
		for enemy in enemies :
			if enemy.global_position.x < 1650 :
				attack()
				break

func _on_detection_range_area_entered(area: Area2D) -> void:
	if area is EnemyHitbox and area not in enemies:
		enemies.append(area)

func _on_detection_range_area_exited(area: Area2D) -> void:
	if area in enemies:
		enemies.erase(area)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

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
		audio_player.stream = cannon_sounds.pick_random()
		audio_player.play()
		
		attack_cooldown_timer.start(attack_cooldown)

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		defense_destroyed.emit(-building_value)
		queue_free()
	update_health_bar()

func update_health_bar() -> void:
	health_bar.value = health
