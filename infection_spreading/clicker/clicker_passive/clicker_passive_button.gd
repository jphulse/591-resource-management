@tool
class_name ClickerPassiveButton extends Button

@onready var texture_icon : TextureRect = $Content/HBoxContainer/TextureRect
@onready var name_label : Label = %NameLabel
@onready var description_label : Label = %Description
@onready var cost_label : Label = %Cost
@onready var quant_label : Label = %CurrentQuantity
var upgrade_name : String = "" :
	set(val):
		if is_node_ready():
			name_label.text = val
		upgrade_name = val
var upgrade_desc: String = "":
	set(val):
		if is_node_ready():
			description_label.text = val
		upgrade_desc = val
var cost : float = 1.0 :
	set(val) :
		if is_node_ready():
			
			cost_label.text = "%.0f" % val
		cost = val
var count : int = 0:
	set(val):
		if is_node_ready():
			quant_label.text = str(val)
		count = val


@export var sprite_texture : Texture2D :
	set(val):
	
			
		sprite_texture = val
		if texture_icon != null and is_node_ready():
			texture_icon.texture = sprite_texture

func _ready() -> void:
	name_label.text = upgrade_name
	cost_label.text = "%.0f" % cost
	quant_label.text = str(count)
	if sprite_texture != null:
		texture_icon.texture = sprite_texture
		
func setup(item : PlaguePassive) -> void:
	upgrade_name = item.name
	cost = item.cost
	count = item.count
	sprite_texture = item.sprite_texture
	
