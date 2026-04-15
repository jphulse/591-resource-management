extends Node2D

@onready var enemy_paths_node: Node2D = $EnemyPaths
@onready var tower_nodes: Node2D = $Projectiles
@onready var projectiles_list: Node2D = $Projectiles

@export var enemy_scene: PackedScene = preload("res://tower_defense/scenes/enemies/EnemyBase.tscn")

var towers: Array = []
var enemies: Array = []
var enemy_paths: Array = []

func _ready() -> void:
	for enemy_path in enemy_paths_node.get_children():
		enemy_paths.append(enemy_path)
		
	for tower in tower_nodes.get_children():
		tower.connect("tower_attack", _tower_attack)
	

func _process(_delta: float) -> void:
	if randi() % 10 == 0:
		spawn_enemy()
	pass

func spawn_enemy() -> void:
	var enemy_path: Path2D = enemy_paths.pick_random()
	var path_to_follow: PathFollow2D = PathFollow2D.new()
	var new_enemy: Enemy = enemy_scene.instantiate()
	
	new_enemy.add_path_follow(path_to_follow)
	path_to_follow.add_child(new_enemy)
	enemy_path.add_child(path_to_follow)

func _tower_attack() -> void:
	pass
