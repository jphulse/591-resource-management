extends Node2D

@onready var enemy_paths_node: Node2D = $EnemyPaths

@export var enemy_scene: PackedScene = preload("res://tower_defense/scenes/enemies/EnemyBase.tscn")

var towers: Array = []
var enemies: Array = []
var enemy_paths: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for enemy_path in enemy_paths_node.get_children():
		enemy_paths.append(enemy_path)
	spawn_enemy()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_enemy() -> void:
	var enemy_path: Path2D = enemy_paths.pick_random()
	var path_to_follow: PathFollow2D = PathFollow2D.new()
	var new_enemy: Enemy = enemy_scene.instantiate()
	
	new_enemy.add_path_follow(path_to_follow)
	path_to_follow.add_child(new_enemy)
	enemy_path.add_child(path_to_follow)
