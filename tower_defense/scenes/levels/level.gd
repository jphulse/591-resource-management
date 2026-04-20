class_name Level extends Node2D

@onready var enemy_paths_node: Node2D = $EnemyPaths
@onready var tower_nodes: Node2D = $Towers
@onready var projectiles_list: Node2D = $Projectiles
@onready var objective: Node2D = $LevelObjective
@onready var level_map : TileMapLayer = $TileMapLayer

@export var enemy_scene: PackedScene = preload("res://tower_defense/scenes/enemies/base_enemy/EnemyBase.tscn")
@export var wave_component: Node2D = null

signal update_enemy(value : int)
signal update_fortifications(value : int)

const GRID_START = Vector2i(1, 1) # Example: starts at tile (2,2)
const GRID_WIDTH = 10
const GRID_HEIGHT = 5

var tower_grid: Dictionary = {} # Key: Vector2i, Value: Node2D
var enemies: Array[Node2D] = []
var enemy_paths: Array[Path2D] = []
var objective_complete: bool = false

func _ready() -> void:
	for enemy_path in enemy_paths_node.get_children():
		enemy_paths.append(enemy_path)
		
	for tower in tower_nodes.get_children():
		tower.connect("tower_attack", _tower_attack)

func _physics_process(delta: float) -> void: 
	if is_instance_valid(objective) && objective.health > 0.0:
		if randi() % 10 == 0:
			spawn_enemy()

func _process(_delta: float) -> void:

	
	if objective.health <= 0.0:
		if not objective_complete:
			#get_tree().paused = true
			objective_complete = true
			print("Objective Destroyed!")
			for enemy in enemies:
				if is_instance_valid(enemy):
					enemy.queue_free()
			enemies.clear() # ALWAYS clear the list after freeing the contents!

func spawn_enemy() -> void:
	var enemy_path: Path2D = enemy_paths.pick_random()
	var path_to_follow: PathFollow2D = PathFollow2D.new()
	var new_enemy: Enemy = enemy_scene.instantiate()
	
	new_enemy.add_path_follow(path_to_follow)
	path_to_follow.add_child(new_enemy)
	enemy_path.add_child(path_to_follow)
	
	enemies.append(new_enemy)

func setup_wave() -> void:
	pass

func _tower_attack() -> void:
	pass

func is_within_placement_bounds(cell_coord: Vector2i) -> bool:
	var inside_x = cell_coord.x >= GRID_START.x and cell_coord.x < GRID_START.x + GRID_WIDTH
	var inside_y = cell_coord.y >= GRID_START.y and cell_coord.y < GRID_START.y + GRID_HEIGHT
	
	return inside_x and inside_y

func request_tower_placement(tower_scene: PackedScene, global_pos: Vector2) -> bool:
	var local_pos = level_map.to_local(global_pos)
	var cell_coord = level_map.local_to_map(local_pos)
	
	if not is_within_placement_bounds(cell_coord):
		print("Out of bounds!")
		return false
		
	if is_cell_occupied(cell_coord):
		print("Space occupied!")
		return false
		
	spawn_tower(tower_scene, level_map.map_to_local(cell_coord))
	return true

func is_cell_occupied(cell: Vector2i) -> bool:
	if tower_grid.has(cell):
		if is_instance_valid(tower_grid[cell]):
			return true
		else:
			tower_grid.erase(cell)
	
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e):
			enemies.remove_at(i)
			continue
			
		var enemy_local = level_map.to_local(e.global_position)
		var enemy_cell = level_map.local_to_map(enemy_local)
		
		if enemy_cell == cell:
			print("Can't build here: Enemy in the way!")
			return true
			
	return false

func spawn_tower(scene: PackedScene, local_pos: Vector2) -> void:
	var new_tower = scene.instantiate()
	tower_nodes.add_child(new_tower)
	new_tower.position = local_pos
	
	var cell = level_map.local_to_map(local_pos)
	tower_grid[cell] = new_tower
	update_fortifications.emit(new_tower.building_value)
	
	new_tower.connect("tower_attack", _tower_attack)
	new_tower.connect("defense_destroyed", _update_defense)
	
func _update_defense(value : int):
	update_fortifications.emit(value)
	
func _update_enemies(value : int):
	update_enemy.emit(value)
