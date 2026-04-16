@tool
class_name ClickerPassiveButton extends Button

@onready var texture_icon : TextureRect = $Content/HBoxContainer/TextureRect
@onready var name_label : Label = %NameLabel
@onready var description_label : Label = %Description
@onready var cost_label : Label = %Cost
@onready var quant_label : Label = %CurrentQuantity
var upgrade_name : String = "" :
	set(val):
		name_label.text = val
		upgrade_name = val
var upgrade_desc: String = "":
	set(val):
		description_label.text = val
		upgrade_desc = val
var cost : float = 1.0 :
	set(val) :
		cost_label.text = str(val)
		cost = val
var count : int = 0:
	set(val):
		quant_label.text = str(val)
		count = val


@export var sprite_texture : Texture2D :
	set(val):
		sprite_texture = val
		if texture_icon != null:
			texture_icon.texture = sprite_texture

func _ready() -> void:
	if sprite_texture != null:
		texture_icon.texture = sprite_texture
		
func setup(item : PlaguePassive) -> void:
	upgrade_name = item.name
	cost = item.cost
	count = item.count
	sprite_texture = item.sprite_texture
	
