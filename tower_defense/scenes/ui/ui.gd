extends CanvasLayer

signal to_lab(entering : bool)
signal final_stand(starting : bool)
signal tower_selected(tower_resource: PackedScene, cost : int)

@onready var health_value : Label = self.find_child("health_value")
@onready var tech_value : Label = self.find_child("tech_value")
@onready var resource_value : Label = self.find_child("power_value")
@onready var tower_bar : PanelContainer = self.find_child("Tower_Selection")
@onready var info_bar : PanelContainer = self.find_child("Info_Menu")
@onready var to_lab_button : Button = $Button
@onready var from_lab_button : Button = $Button2


var ui_tweens : Dictionary = {}

var current_resource_value : int

var at_lab : bool = false
var desperation : bool = false



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
	_tween_object(from_lab_button, Vector2(1960.0, 33.0), 400)
	_tween_object(tower_bar, Vector2(0, 908.0), 700)
	_tween_object(info_bar, Vector2(1268.0, 908.0), 700)
	
func _on_button_pressed() -> void:
	at_lab = true
	to_lab.emit(at_lab)
	
	_tween_object(tower_bar, Vector2(0, 1808.0), 500)
	_tween_object(info_bar, Vector2(1268.0, 1808.0), 500)
	_tween_object(to_lab_button, Vector2(-250, 33), 400)
	_tween_object(from_lab_button, Vector2(1680.0, 33.0), 400)

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
	
func _on_tech_update(value : int) :
	tech_value.text = str(value)
