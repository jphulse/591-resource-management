@tool
class_name SolarOrbitRings
extends Node2D

@export var orbit_radii : PackedFloat32Array = PackedFloat32Array([
	70.0,
	102.0,
	140.0,
	176.0,
	220.0,
	262.0,
	308.0,
	350.0,
]):
	set(value):
		orbit_radii = value
		queue_redraw()
@export var orbit_color : Color = Color("bcbcbc", 0.48):
	set(value):
		orbit_color = value
		queue_redraw()
@export var line_width : float = 1.4:
	set(value):
		line_width = max(value, 0.1)
		queue_redraw()


func _draw() -> void:
	for orbit_radius : float in orbit_radii:
		draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 100, orbit_color, line_width, true)
