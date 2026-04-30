extends CanvasLayer

signal to_lab(entering : bool)
signal final_stand(starting : bool)
signal tower_selected(tower_resource: PackedScene, cost : int)

signal attempt_storage_upgrade()
signal attempt_generation_upgrade()
signal attempt_tech_upgrade()
signal win()
signal destroy_mode(tower: PackedScene)
signal change_wave(increase : bool)
signal change_subwave(increase : bool)

@onready var health_value : Label = self.find_child("health_value")
@onready var wave_value : Label = self.find_child("wave_value")
@onready var subwave_value : Label = self.find_child("wave_value3")
@onready var tech_value : Label = self.find_child("tech_value")
@onready var resource_value : Label = self.find_child("power_value")
@onready var storage_value : Label = self.find_child("power_storage")
@onready var tower_bar : SubViewportContainer = self.find_child("Tower_Menu")
@onready var progress_bar : SubViewportContainer = self.find_child("Progress_Menu")
@onready var win_bar : ProgressBar = self.find_child("Win_Bar")
@onready var info_bar : SubViewportContainer = self.find_child("Info_Menu")
@onready var to_lab_button : Button = $Button
@onready var from_lab_button : Button = $Button2
@onready var power_storage : Button = $Power_Storage
@onready var power_generation : Button = $Power_Generation
@onready var tech_level : Button = $Tech_Level
@onready var victory_timer : Timer = $Victory_Timer
@onready var update_timer : Timer = $Update_Timer
@onready var win_button : Button = $Win
@onready var wave_labelButton : Button = $Button9
@onready var subwave_labelButton : Button = $Button8
@onready var door_tech1_1 : AnimatedSprite2D = self.find_child("tower_door4")
@onready var door_tech1_2 : AnimatedSprite2D = self.find_child("tower_door5")
@onready var door_tech2_1 : AnimatedSprite2D = self.find_child("tower_door6")

var ui_tweens : Dictionary = {}

var current_resource_value : int

var at_lab : bool = false
var desperation : bool = false
var reveal_victory_button : bool = false


func _tween_object(node: Node, target_pos: Vector2, pixels_per_second: int) -> void:
	if ui_tweens.has(node) and ui_tweens[node].is_running():
		ui_tweens[node].kill()
	
	var current_pos = node.global_position
	var distance = current_pos.distance_to(target_pos)
	var duration = distance / pixels_per_second

	#no glitches please
	if duration > 0.001:
		var t = create_tween()
		ui_tweens[node] = t
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		t.tween_property(node, "global_position", target_pos, duration)
	else:
		node.global_position = target_pos



func _on_button_2_pressed() -> void:
	at_lab = false
	to_lab.emit(at_lab)
	_tween_object(to_lab_button, Vector2(33, 33), 400)
	_tween_object(from_lab_button, Vector2(2260.0, 33.0), 400)
	_tween_object(tower_bar, Vector2(0, 908.0), 700)
	_tween_object(progress_bar, Vector2(-4000, 908.0), 2000)
	_tween_object(tech_level, Vector2(tech_level.position.x, -400), 300)
	_tween_object(power_generation, Vector2(power_generation.position.x, -400), 300)
	_tween_object(power_storage, Vector2(power_storage.position.x, -400), 300)
	_tween_object(win_button, Vector2(win_button.position.x, -400), 300)

func _on_button_pressed() -> void:
	at_lab = true
	to_lab.emit(at_lab)
	
	_tween_object(tower_bar, Vector2(0, 1808.0), 500)
	_tween_object(progress_bar, Vector2(0, 908.0), 1700)
	_tween_object(to_lab_button, Vector2(-550, 33), 400)
	_tween_object(from_lab_button, Vector2(1680.0, 33.0), 400)
	_tween_object(tech_level, Vector2(tech_level.position.x, 33), 300)
	_tween_object(power_generation, Vector2(power_generation.position.x, 33), 300)
	_tween_object(power_storage, Vector2(power_storage.position.x, 33), 300)
	_tween_object(win_button, Vector2(win_button.position.x, 33), 300)

func _on_tower_button_pressed(tower: PackedScene, cost : int) -> bool:
	if cost > current_resource_value:
		return false
	tower_selected.emit(tower, cost)
	return true

func _on_destroy_button_pressed(tower_scene, cost : int):
	destroy_mode.emit(tower_scene)

func _on_health_update(value : int) :
	health_value.text = str(value)

func _on_resource_update(value : int) :
	resource_value.text = str(value)
	current_resource_value = value
	
func _on_tech_update(value : float, level : int) :
	tech_value.text = str(level)
	tech_level.text = "Increase Tech Level\n" + str(value)
	if level == 1:
		door_tech1_1.play()
		door_tech1_2.play()
	elif level == 2:
		door_tech2_1.play()
	
func _on_storage_update(value : float) :
	storage_value.text = "/" + str(value * 2)
	power_storage.text = "Increase Power Storage\n" + str(value)
	
func _on_generation_update(value : float):
	power_generation.text = "Increase Power Generation\n" + str(value)

func _on_tech_level_pressed() -> void:
	attempt_tech_upgrade.emit()

func _on_power_generation_pressed() -> void:
	attempt_generation_upgrade.emit()

func _on_power_storage_pressed() -> void:
	attempt_storage_upgrade.emit()

func _on_victory_timer_timeout() -> void:
	reveal_victory_button = true
	win_button.add_theme_color_override("font_color", Color(255,255,255,255))
	
func _on_update_timer_timeout() -> void:
	var raw_progress = victory_timer.wait_time - victory_timer.time_left
	var step_threshold = 9.0
	var floored_value = floor(raw_progress / step_threshold) * step_threshold
	
	win_bar.value = floored_value
	
	# For your debugging
	print("Actual Time: ", raw_progress, " | Stepped Value: ", floored_value)


func _on_win_pressed() -> void:
	if reveal_victory_button :
		win.emit()


func _on_wave_up_pressed() -> void:
	change_wave.emit(true)

func _on_wave_down_pressed() -> void:
	change_wave.emit(false)

func _on_subwave_up_pressed() -> void:
	change_subwave.emit(true)

func _on_subwave_down_pressed() -> void:
	change_subwave.emit(false)

func _on_wave_update(value : int) -> void:
	wave_labelButton.text = "wave " + str(value)
	print("wave " + str(value))
	wave_value.text = str(value)
	
func _on_subwave_update(value : int) -> void:
	subwave_labelButton.text = "subwave " + str(value)
	print("subwave " + str(value))
	subwave_value.text = str(value)
