class_name Level extends Node2D

@onready var enemy_paths_node: Node2D = $EnemyPaths
@onready var tower_nodes: Node2D = $Projectiles
@onready var projectiles_list: Node2D = $Projectiles
@onready var objective: Node2D = $LevelObjective

@export var enemy_scene: PackedScene = preload("res://tower_defense/scenes/enemies/base_enemy/EnemyBase.tscn")
@export var wave_component: Node2D = null

var towers: Array[Node2D] = []
var enemies: Array[Node2D] = []
var enemy_paths: Array[Path2D] = []
var objective_complete: bool = false

func _ready() -> void:
	for enemy_path in enemy_paths_node.get_children():
		enemy_paths.append(enemy_path)
		
	for tower in tower_nodes.get_children():
		tower.connect("tower_attack", _tower_attack)
	

func _process(_delta: float) -> void:
	if objective.health > 0.0:
		if randi() % 10 == 0:
			spawn_enemy()
	
	if objective.health <= 0.0:
		if not objective_complete:
			#get_tree().paused = true
			objective_complete = true
			print("Objective Destroyed!")
			for enemy in enemies:
				enemy.do_free()

func spawn_enemy() -> void:
	var enemy_path: Path2D = enemy_paths.pick_random()
	var path_to_follow: PathFollow2D = PathFollow2D.new()
	var new_enemy: Enemy = enemy_scene.instantiate()
	
	new_enemy.add_path_follow(path_to_follow)
	path_to_follow.add_child(new_enemy)
	enemy_path.add_child(path_to_follow)

func setup_wave() -> void:
	pass

func _tower_attack() -> void:
	pass
