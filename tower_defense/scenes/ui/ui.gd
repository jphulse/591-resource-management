extends CanvasLayer

signal to_lab(entering : bool)
signal final_stand(starting : bool)
signal tower_selected(tower_resource: PackedScene, cost : int)

signal attempt_storage_upgrade()
signal attempt_generation_upgrade()
signal attempt_tech_upgrade()
signal win()

@onready var health_value : Label = self.find_child("health_value")
@onready var tech_value : Label = self.find_child("tech_value")
@onready var resource_value : Label = self.find_child("power_value")
@onready var storage_value : Label = self.find_child("power_storage")
@onready var tower_bar : PanelContainer = self.find_child("Tower_Selection")
@onready var progress_bar : PanelContainer = self.find_child("Progress_Bar")
@onready var win_bar : ProgressBar = self.find_child("Win_Bar")
@onready var info_bar : PanelContainer = self.find_child("Info_Menu")
@onready var to_lab_button : Button = $Button
@onready var from_lab_button : Button = $Button2
@onready var power_storage : Button = $Power_Storage
@onready var power_generation : Button = $Power_Generation
@onready var tech_level : Button = $Tech_Level
@onready var victory_timer : Timer = $Victory_Timer
@onready var update_timer : Timer = $Update_Timer
@onready var win_button : Button = $Win

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

func _on_health_update(value : int) :
	health_value.text = str(value)

func _on_resource_update(value : int) :
	resource_value.text = str(value)
	current_resource_value = value
	
func _on_tech_update(value : float) :
	tech_value.text = str(value)

func _on_storage_update(value : float) :
	storage_value.text = "/" + str(value * 2)
	power_storage.text = "Increase Power Storage\n" + str(value)
	
func _on_generation_update(value : float):
	power_generation.text = "Increase Power Generation\n" + str(value)

func _on_power_generation_pressed() -> void:
	attempt_generation_upgrade.emit()

func _on_power_storage_pressed() -> void:
	attempt_storage_upgrade.emit()

func _on_victory_timer_timeout() -> void:
	reveal_victory_button = true
	win_button.add_theme_color_override("font_color", Color(255,255,255,255))
	
func _on_update_timer_timeout() -> void:
	var raw_progress = victory_timer.wait_time - victory_timer.time_left
	var step_threshold = 45.0
	var floored_value = floor(raw_progress / step_threshold) * step_threshold
	
	win_bar.value = floored_value
	
	# For your debugging
	print("Actual Time: ", raw_progress, " | Stepped Value: ", floored_value)


func _on_win_pressed() -> void:
	if reveal_victory_button :
		win.emit()
