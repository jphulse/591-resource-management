class_name Level extends Node2D

@onready var enemy_paths_node: Node2D = $EnemyPaths
@onready var tower_nodes: Node2D = $Towers
@onready var projectiles_list: Node2D = $Projectiles
@onready var objective: Node2D = $LevelObjective
@onready var level_map : TileMapLayer = $TileMapLayer
@onready var spawn_timer : Timer = $spawn_timer
@onready var frequency_timer : Timer = $frequency_timer
@onready var resource_timer : Timer = $resource_timer

@export var enemy_scene: PackedScene = preload("res://tower_defense/scenes/enemies/base_enemy/EnemyBase.tscn")
@export var siege_scene: PackedScene = preload("res://tower_defense/scenes/enemies/base_enemy/SiegeBreaker.tscn")
@export var wave_component: Node2D = null
@export var max_storage : int = 50
@export var generation_rate : float = .4

signal update_enemy(value : int)
signal update_fortifications(value : int)
signal ultimateEnemy(spawning : bool)
signal update_resource(value : int)
signal update_health(value : int)
signal update_tech(value : float)
signal update_storage(value : float)
signal update_generation(value : float)
signal lose()

const GRID_START = Vector2i(1, 1) # Example: starts at tile (2,2)
const GRID_WIDTH = 10
const GRID_HEIGHT = 5

var tower_grid: Dictionary = {} # Key: Vector2i, Value: Node2D
var enemies: Array[Node2D] = []
var enemy_paths: Array[Path2D] = []
var objective_complete: bool = false
var total_resources : int = 0
var tech_level : int = 0

var difficulty_ramp : int = 3

var spawn_delay : Array[float] = [0.003, 0.004, 0.01, 25, 0.006, 0.03, 0.08, 25]

func _ready() -> void:
	for enemy_path in enemy_paths_node.get_children():
		enemy_paths.append(enemy_path)
		
	for tower in tower_nodes.get_children():
		tower.connect("tower_attack", _tower_attack)
	
	resource_timer.wait_time = generation_rate
	update_generation.emit(10/generation_rate)
	update_storage.emit(max_storage/2)
	update_generation.emit(10/generation_rate)

func _spawn_enemy_timer() -> void:
	if difficulty_ramp > 0 :
		frequency_timer.wait_time *= 1.5
		difficulty_ramp -= 1
		return
	frequency_timer.wait_time = spawn_delay.pick_random()
	if frequency_timer.wait_time == 25 && is_instance_valid(objective):
		for lane in enemy_paths:
			spawn_enemy(siege_scene, lane)
			ultimateEnemy.emit(true)
		frequency_timer.wait_time = .1

func _frequency_timer() -> void:
	if is_instance_valid(objective) && objective.health > 0.0:
		if randi() % 10 == 0:
			var enemy_path: Path2D = enemy_paths.pick_random()
			spawn_enemy(enemy_scene, enemy_path)

func _on_resource_timer_timeout() -> void:
	if total_resources < max_storage :
		total_resources += 1
		update_resource.emit(total_resources)

func _on_generation_increase_attempt() :
	if total_resources >= 10/generation_rate * 1.5 :
		total_resources -= 10/generation_rate * 1.5
		generation_rate /= 1.1
		resource_timer.wait_time = generation_rate
		update_generation.emit(10/generation_rate * 1.5)

func _on_attempt_storage_upgrade() -> void:
	if total_resources >= max_storage/2 :
		total_resources -= max_storage/2
		max_storage *= 2
		update_storage.emit(max_storage/2)

func _process(_delta: float) -> void:
	if objective.health <= 0.0:
		if not objective_complete:
			#get_tree().paused = true
			objective_complete = true
			print("Objective Destroyed!")
			lose.emit()

func spawn_enemy(enemy : PackedScene, enemy_path : Path2D) -> void:
	var path_to_follow: PathFollow2D = PathFollow2D.new()
	path_to_follow.rotates = false
	var new_enemy: Enemy = enemy.instantiate()
	
	new_enemy.add_path_follow(path_to_follow)
	path_to_follow.add_child(new_enemy)
	enemy_path.add_child(path_to_follow)
	new_enemy.enemy_death.connect(_update_enemies)
	if new_enemy.health == 2 : 
		breakpoint
	if new_enemy.has_signal("ultimate_death"):
		new_enemy.ultimate_death.connect(_ultimate_death)
		new_enemy.parent_path = enemy_path
		new_enemy.summon_minion.connect(spawn_enemy)
	enemies.append(new_enemy)
	_update_enemies(new_enemy.enemy_value)

func setup_wave() -> void:
	pass

func _tower_attack() -> void:
	pass

func is_within_placement_bounds(cell_coord: Vector2i) -> bool:
	var inside_x = cell_coord.x >= GRID_START.x and cell_coord.x < GRID_START.x + GRID_WIDTH
	var inside_y = cell_coord.y >= GRID_START.y and cell_coord.y < GRID_START.y + GRID_HEIGHT
	
	return inside_x and inside_y

func request_tower_placement(tower_scene: PackedScene, global_pos: Vector2, cost : int) -> bool:
	var local_pos = level_map.to_local(global_pos)
	var cell_coord = level_map.local_to_map(local_pos)
	
	if not is_within_placement_bounds(cell_coord):
		print("Out of bounds!")
		return false
		
	if is_cell_occupied(cell_coord):
		print("Space occupied!")
		return false
	
	total_resources -= cost
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
		if not is_instance_valid(e) or not e.is_inside_tree():
			if not is_instance_valid(e):
				enemies.remove_at(i)
			continue
			
		var enemy_local = level_map.to_local(e.global_position)
		var enemy_cell = level_map.local_to_map(enemy_local)
		
		if enemy_cell == cell:
			print("Collision with enemy at: ", cell)
			return true
			
	return false 

func spawn_tower(scene: PackedScene, local_pos: Vector2) -> void:
	var new_tower = scene.instantiate()
	tower_nodes.add_child(new_tower)
	new_tower.position = local_pos
	
	var cell = level_map.local_to_map(local_pos)
	tower_grid[cell] = new_tower
	update_fortifications.emit(new_tower.building_value)
	
	new_tower.defense_destroyed.connect(_update_defense)

func _update_defense(value : int):
	update_fortifications.emit(value)
	
func _update_enemies(value : int):
	update_enemy.emit(value)

func _ultimate_death():
	ultimateEnemy.emit(false)
