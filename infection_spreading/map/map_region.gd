class_name MapRegion
extends Area2D

signal infection_state_changed(region_name : String, infected : bool)

const BORDER_COLOR : Color = Color("d6d9e0")
const LABEL_COLOR : Color = Color("f1f3f8")
const INFECTED_COLOR : Color = Color("d94452")

@export var region_name : String = ""
@export var base_color : Color = Color.WHITE
@export var radius : float = 18.0
@export var infected : bool = false
@export var visual_type : String = "planet"
@export var hover_tint_strength : float = 0.1

var infected_neighbor_count : int = 0
var is_hovered : bool = false

@onready var collision_shape : CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var circle_shape : CircleShape2D = collision_shape.shape as CircleShape2D
	if circle_shape == null:
		circle_shape = CircleShape2D.new()
		collision_shape.shape = circle_shape
	circle_shape.radius = radius + 8.0
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()


func configure(display_name : String, region_position : Vector2, region_radius : float, color : Color, starts_infected : bool, type_name : String = "planet") -> void:
	region_name = display_name
	position = region_position
	radius = region_radius
	base_color = color
	visual_type = type_name
	infected = starts_infected
	queue_redraw()


func set_infected(value : bool) -> void:
	if infected == value:
		return

	infected = value
	infection_state_changed.emit(region_name, infected)
	queue_redraw()


func set_infected_neighbor_count(value : int) -> void:
	if infected_neighbor_count == value:
		return

	infected_neighbor_count = value
	queue_redraw()


func _draw() -> void:
	if visual_type == "ringed_planet":
		_draw_rings()

	var display_color : Color = base_color
	if is_hovered:
		display_color = display_color.lightened(hover_tint_strength)

	draw_circle(Vector2.ZERO, radius + 4.0 + infected_neighbor_count, display_color.darkened(0.65))
	draw_circle(Vector2.ZERO, radius, display_color)
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 40, BORDER_COLOR, 1.6)

	if infected:
		draw_circle(Vector2.ZERO, radius, INFECTED_COLOR.darkened(0.15))
		draw_circle(Vector2.ZERO, radius * 0.82, INFECTED_COLOR)
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 40, INFECTED_COLOR.lightened(0.15), 2.5)

	var highlight_offset : Vector2 = Vector2(-radius * 0.32, -radius * 0.34)
	draw_circle(highlight_offset, radius * 0.26, Color(1, 1, 1, 0.22))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-radius, radius + 17.0),
		region_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		radius * 4.0,
		14,
		LABEL_COLOR
	)


func _draw_rings() -> void:
	draw_set_transform(Vector2.ZERO, deg_to_rad(-18.0), Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 48, Color("cabf9d"), 7.0)
	draw_arc(Vector2.ZERO, radius + 18.0, 0.0, TAU, 48, Color("8e7f62"), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()
