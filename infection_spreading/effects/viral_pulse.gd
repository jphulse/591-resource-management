class_name ViralPulse
extends Node2D

var pulse_color : Color = Color("d94452")
var start_radius : float = 18.0
var end_radius : float = 80.0
var duration : float = 0.45
var width : float = 4.0
var elapsed : float = 0.0


## Sets up an expanding fading ring effect
func setup(color : Color, radius : float, pulse_duration : float, pulse_width : float = 4.0) -> void:
	pulse_color = color
	start_radius = radius * 0.45
	end_radius = radius
	duration = max(pulse_duration, 0.01)
	width = pulse_width
	z_index = 90
	queue_redraw()


func _process(delta : float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var progress : float = clamp(elapsed / duration, 0.0, 1.0)
	var current_radius : float = lerp(start_radius, end_radius, progress)
	var current_color : Color = pulse_color
	current_color.a *= 1.0 - progress
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 72, current_color, width, true)
