extends CanvasLayer

signal to_lab(entering : bool)
signal final_stand(starting : bool)
signal tower_selected(tower_resource: PackedScene)

var at_lab : bool = false
var desperation : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_3_pressed() -> void:
	desperation = !desperation
	final_stand.emit(desperation)


func _on_button_pressed() -> void:
	at_lab = !at_lab
	to_lab.emit(at_lab)

func _on_tower_button_pressed(tower: PackedScene) -> void:
	tower_selected.emit(tower)
