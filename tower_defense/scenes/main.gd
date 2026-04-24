extends Node2D

@onready var ui_node : CanvasLayer = $Ui
@onready var audio_system : Node2D = $AudioSystem
@onready var level_node : Node2D = $Level
@onready var level_map: TileMapLayer = $Level/TileMapLayer
@onready var camera : Camera2D = $Camera2D

# We store the PackedScene so we can 'instantiate' it later
var current_tower_scene: PackedScene = null
var ghost_preview: Node2D = null
var current_cost = 0

var defense : int = 0
var combat : int = 0
var at_lab : bool = false
var desperation : bool = false
var ultimate_enemies : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ui_node.to_lab.connect(_lab_audio)
	ui_node.final_stand.connect(_desperation_audio)
	audio_system.evaluate.connect(_evaluate_audio)
	audio_system.play_game_audio()
	level_node.update_enemy.connect(_adjust_combat_points)
	level_node.update_fortifications.connect(_adjust_defense_points)
	level_node.ultimateEnemy.connect(_adjust_ultimate_count)
	
func _process(_delta: float) -> void:
	if ghost_preview:
		var global_mouse = get_global_mouse_position()
		var local_mouse = level_map.to_local(global_mouse)
		
		var cell_coord = level_map.local_to_map(local_mouse)
		var local_snapped_pos = level_map.map_to_local(cell_coord)
		
		ghost_preview.global_position = level_map.to_global(local_snapped_pos)
	if combat < 0:
		combat = 0
	if defense < 0:
		defense = 0
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("uid://cxby1rpj5kclj")

#if in place mode, do not place behind ui, right click to stop
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and current_tower_scene:
		place_tower()
	elif event.is_action_pressed("right_click"):
		cancel_placement()

func start_placement(tower: PackedScene, cost : int) -> void:
	current_cost = cost
	current_tower_scene = tower
	
	ghost_preview = tower.instantiate() 
	add_child(ghost_preview)
	ghost_preview.sprite_node.modulate.a = 0.5
	ghost_preview.z_index = 100 
	
	ghost_preview.process_mode = Node.PROCESS_MODE_DISABLED 
	

func place_tower() -> void:
	if not is_instance_valid(ghost_preview):
		return

	var target_pos = ghost_preview.global_position
	
	if level_node.request_tower_placement(current_tower_scene, target_pos, current_cost):
		cancel_placement()

func cancel_placement() -> void:
	current_tower_scene = null
	if ghost_preview:
		ghost_preview.queue_free()
		ghost_preview = null

#####AUDIO STUFFS BELOW#####

func _evaluate_audio() -> void:
	if at_lab:
		return
	audio_system.update_combat(combat, desperation)
	audio_system.update_defense(defense)
	if ultimate_enemies > 0:
		desperation = true
	else :
		desperation = false
	audio_system.set_desperation(desperation)
	
func _lab_audio(entering: bool) -> void:
	at_lab = entering
	audio_system.lab(at_lab)
	
	if entering :
		ui_node._tween_object(camera, Vector2(-2500, 0), 1500)
	else :
		ui_node._tween_object(camera, Vector2(0, 0), 1500)

func _desperation_audio (desperate : bool) -> void:
	desperation = desperate
	if at_lab:
		return
	audio_system.set_desperation(desperation)


func _on_timer_timeout() -> void:
	pass # Replace with function body.

func _adjust_defense_points(value : int):
	defense += value
	
func _adjust_combat_points(value : int):
	combat += value

func _adjust_ultimate_count(spawning : bool) :
	if spawning == true:
		ultimate_enemies += 1
	else :
		ultimate_enemies -= 1
