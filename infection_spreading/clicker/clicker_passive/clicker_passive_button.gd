@tool
extends Button

@export var texture_icon : TextureRect
@export var sprite_texture : Texture2D :
	set(val):
		sprite_texture = val
		if texture_icon != null:
			texture_icon.texture = sprite_texture
		
