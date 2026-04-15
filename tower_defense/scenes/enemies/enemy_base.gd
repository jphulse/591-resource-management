class_name Enemy extends Node2D

@onready var attack_area: Area2D = $AttackArea

@export var damage: float = 100.0
@export var health: float = 10000.0
@export var speed: float = 100.0
@export var attack_cooldown: float = 0.5

var in_attack_range: bool = false
var can_attack: bool = true

var path_follow: PathFollow2D

func _ready() -> void:
	attack_area.damage = self.damage

func _process(delta: float) -> void:
	if path_follow:
		path_follow.progress += speed * delta
		if path_follow.progress_ratio >= 0.99:
			queue_free()

func add_path_follow(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	
func death_sequence() -> void:
	pass

func attack() -> void:
	pass

func take_damage(incoming_damage: float) -> void:
	health = health - incoming_damage
	
	if health <= 0.0:
		death_sequence()
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area is TowerHitbox:
		
