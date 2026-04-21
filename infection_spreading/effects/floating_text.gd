class_name FloatingText
extends Label

var drift : Vector2 = Vector2(0.0, -52.0)
var duration : float = 0.8
var elapsed : float = 0.0
var start_position : Vector2 = Vector2.ZERO
var start_color : Color = Color.WHITE


## Sets up short-lived floating text feedback
func setup(display_text : String, color : Color, text_drift : Vector2, text_duration : float) -> void:
	text = display_text
	start_color = color
	drift = text_drift
	duration = max(text_duration, 0.01)
	modulate = color
	z_index = 100
	custom_minimum_size = Vector2(140.0, 32.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	pivot_offset = size * 0.5


func _ready() -> void:
	start_position = position
	pivot_offset = size * 0.5


func _process(delta : float) -> void:
	elapsed += delta
	var progress : float = clamp(elapsed / duration, 0.0, 1.0)
	position = start_position + (drift * progress)
	scale = Vector2.ONE * lerp(1.0, 1.22, sin(progress * PI))
	modulate = start_color
	modulate.a = 1.0 - progress

	if elapsed >= duration:
		queue_free()
