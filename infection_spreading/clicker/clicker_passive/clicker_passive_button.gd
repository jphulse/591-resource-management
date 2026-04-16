@tool
extends Button

@onready var texture_icon : TextureRect = $Content/HBoxContainer/TextureRect

@export var sprite_texture : Texture2D :
	set(val):
		sprite_texture = val
		if texture_icon != null:
			texture_icon.texture = sprite_texture
		
