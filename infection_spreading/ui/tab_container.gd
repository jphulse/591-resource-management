extends TabContainer

@export var radius_size_percentage : float = .25

@onready var area : Area2D = $Clicker/ClickerArea
@onready var click_circle :CircleShape2D = $Clicker/ClickerArea/CollisionShape2D.shape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_center_node(area)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Centers the node in the overall tab selection
func _center_node(node: Node2D) -> void:
	area.position = size / 2.0
	var rel_side: float = size.x if size.x < size.y else size.y
	click_circle.radius =  rel_side * radius_size_percentage
