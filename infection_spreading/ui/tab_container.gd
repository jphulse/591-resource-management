extends TabContainer


@onready var area : Area2D = $Clicker/ClickerArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_center_node(area)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Centers the node in the overall tab selection
func _center_node(node: Node2D) -> void:
	area.position = size / 2.0
