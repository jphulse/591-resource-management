class_name PIMain
extends Node2D

const GALAXY_TRANSITION_DURATION : float = 2.35
const GALAXY_TRANSITION_SETTLE_DURATION : float = 0.38
const GALAXY_TRANSITION_SOLAR_END_SCALE : float = 0.065
const GALAXY_TRANSITION_GALAXY_START_SCALE : float = 0.18
const GALAXY_TRANSITION_GALAXY_PEAK_SCALE : float = 1.14
const GALAXY_TRANSITION_CAMERA_ZOOM : Vector2 = Vector2(0.92, 0.92)
const TITLE_SCENE_UID : String = "uid://cxby1rpj5kclj"

@onready var galaxy_system_stage : MapStage = $GalaxyStage
@onready var solar_system_stage : MapStage = $SolarSystemStage
@onready var map_camera : Camera2D = %MapCamera
@onready var clicker : InfectionClicker = $CanvasLayer/MainUi/TabContainer/Clicker
@onready var main_ui : Control = $CanvasLayer/MainUi
@onready var skip_stage_button : Button = $CanvasLayer/SkipStageButton
@onready var endgame_overlay : Control = $CanvasLayer/EndgameOverlay
@onready var solar_map_content : Node2D = $SolarSystemStage/MapContent
@onready var galaxy_map_content : Node2D = $GalaxyStage/MapContent

var galaxy_transition_active : bool = false
var game_finished : bool = false


func _ready() -> void:
	galaxy_system_stage.hide()
	galaxy_system_stage.position = solar_system_stage.position
	galaxy_system_stage.modulate = Color(1.0, 1.0, 1.0, 1.0)
	solar_system_stage.modulate = Color.WHITE
	solar_map_content.scale = Vector2.ONE
	galaxy_map_content.scale = Vector2.ONE
	clicker.set_auto_clicker_tendrils(solar_system_stage.auto_clicker_tendrils)
	solar_system_stage.clicker = clicker
	solar_system_stage.initialize_stage()
	clicker.set_black_hole_mode(false)
	map_camera.zoom = Vector2.ONE
	map_camera.position = solar_system_stage.position
	skip_stage_button.show()
	endgame_overlay.hide()

	solar_system_stage.stage_cleared.connect(_on_solar_system_stage_cleared)
	galaxy_system_stage.stage_cleared.connect(_on_galaxy_stage_cleared)
	if not skip_stage_button.pressed.is_connected(_on_skip_stage_button_pressed):
		skip_stage_button.pressed.connect(_on_skip_stage_button_pressed)

func _on_solar_system_stage_cleared() -> void:
	if not solar_system_stage.visible:
		return

	if galaxy_transition_active:
		return

	galaxy_transition_active = true
	skip_stage_button.hide()
	solar_system_stage.deactivate_stage()
	if solar_system_stage.stage_cleared.is_connected(_on_solar_system_stage_cleared):
		solar_system_stage.stage_cleared.disconnect(_on_solar_system_stage_cleared)
	await _play_galaxy_transition()
	galaxy_transition_active = false


func _on_galaxy_stage_cleared() -> void:
	if game_finished:
		return

	game_finished = true
	skip_stage_button.hide()
	galaxy_system_stage.deactivate_stage()
	main_ui.process_mode = Node.PROCESS_MODE_DISABLED
	_show_endgame_overlay()


func _on_skip_stage_button_pressed() -> void:
	if not solar_system_stage.visible:
		return

	await _on_solar_system_stage_cleared()


func _play_galaxy_transition() -> void:
	var stage_center : Vector2 = solar_system_stage.position

	galaxy_system_stage.position = stage_center
	galaxy_system_stage.clicker = clicker
	galaxy_system_stage.initialize_stage()
	galaxy_system_stage.show()
	galaxy_system_stage.modulate = Color(1.0, 1.0, 1.0, 0.0)
	galaxy_map_content.scale = Vector2.ONE * GALAXY_TRANSITION_GALAXY_START_SCALE
	solar_map_content.scale = Vector2.ONE
	clicker.set_black_hole_mode(true)
	map_camera.position = stage_center
	map_camera.zoom = Vector2.ONE

	var transition_tween : Tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.set_trans(Tween.TRANS_CUBIC)
	transition_tween.set_ease(Tween.EASE_IN_OUT)
	transition_tween.tween_property(solar_map_content, "scale", Vector2.ONE * GALAXY_TRANSITION_SOLAR_END_SCALE, GALAXY_TRANSITION_DURATION)
	transition_tween.tween_property(solar_system_stage, "modulate:a", 0.0, GALAXY_TRANSITION_DURATION * 0.82)
	transition_tween.tween_property(galaxy_map_content, "scale", Vector2.ONE * GALAXY_TRANSITION_GALAXY_PEAK_SCALE, GALAXY_TRANSITION_DURATION)
	transition_tween.tween_property(galaxy_system_stage, "modulate:a", 1.0, GALAXY_TRANSITION_DURATION * 0.72)
	transition_tween.tween_property(map_camera, "zoom", GALAXY_TRANSITION_CAMERA_ZOOM, GALAXY_TRANSITION_DURATION * 0.7)

	await transition_tween.finished

	solar_system_stage.hide()
	solar_system_stage.modulate = Color.WHITE
	solar_map_content.scale = Vector2.ONE
	clicker.set_auto_clicker_tendrils(galaxy_system_stage.auto_clicker_tendrils)

	var settle_tween : Tween = create_tween()
	settle_tween.set_parallel(true)
	settle_tween.set_trans(Tween.TRANS_EXPO)
	settle_tween.set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(galaxy_map_content, "scale", Vector2.ONE, GALAXY_TRANSITION_SETTLE_DURATION)
	settle_tween.tween_property(map_camera, "zoom", Vector2.ONE, GALAXY_TRANSITION_SETTLE_DURATION)

	await settle_tween.finished

	galaxy_system_stage.modulate = Color.WHITE
	galaxy_map_content.scale = Vector2.ONE
	map_camera.position = stage_center
	map_camera.zoom = Vector2.ONE


func _show_endgame_overlay() -> void:
	endgame_overlay.show()
	endgame_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	endgame_overlay.scale = Vector2.ONE * 0.96

	var overlay_tween : Tween = create_tween()
	overlay_tween.set_trans(Tween.TRANS_CUBIC)
	overlay_tween.set_ease(Tween.EASE_OUT)
	overlay_tween.tween_property(endgame_overlay, "modulate:a", 1.0, 0.32)
	overlay_tween.parallel().tween_property(endgame_overlay, "scale", Vector2.ONE, 0.32)


func _return_to_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE_UID)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		_return_to_title()
