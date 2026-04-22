class_name MapRegion
extends Area2D

signal infection_state_changed(region_name : String, infected : bool)

const BORDER_COLOR : Color = Color("d6d9e0")
const LABEL_COLOR : Color = Color("f1f3f8")
const INFECTED_COLOR : Color = Color("d94452")
const INFECTING_COLOR : Color = Color("ff0033")
const VEIN_COLOR : Color = Color("cf2f47")
const VEIN_PURPLE_COLOR : Color = Color("b43aa8")
const VEIN_CORE_COLOR : Color = Color("6b0612")
const VEIN_PURPLE_CORE_COLOR : Color = Color("4c0b42")
const VEIN_FLESH_HIGHLIGHT : Color = Color("ff6f83")
const DISTRESS_COLOR : Color = Color("ff9aa5")
const REGION_LABEL_WIDTH : float = 98.0
const DISTRESS_LABEL_WIDTH : float = 168.0

@export var region_name : String = ""
@export var base_color : Color = Color.WHITE
@export var radius : float = 18.0
@export var infected : bool = false
@export var infecting : bool = false
@export var infection_progress : float = 0.0
@export var visual_type : String = "planet"
@export var hover_tint_strength : float = 0.1

var infected_neighbor_count : int = 0
var is_hovered : bool = false
var death_flash_amount : float = 0.0
var memory_pulse_strength : float = 0.0

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
	infecting = false
	infection_progress = 1.0 if infected else 0.0
	queue_redraw()


func set_infected(value : bool) -> void:
	if infected == value:
		return

	infected = value
	infecting = false
	infection_progress = 1.0 if infected else 0.0
	infection_state_changed.emit(region_name, infected)
	queue_redraw()


func start_infection() -> void:
	if infected or infecting:
		return

	infecting = true
	infection_progress = 0.0
	queue_redraw()


func set_infection_progress(value : float) -> void:
	var new_progress : float = clamp(value, 0.0, 1.0)
	if is_equal_approx(infection_progress, new_progress):
		return

	infection_progress = new_progress
	queue_redraw()


func set_infected_neighbor_count(value : int) -> void:
	if infected_neighbor_count == value:
		return

	infected_neighbor_count = value
	queue_redraw()


## Gives a newly infected region a quick gross pop
func play_infection_burst() -> void:
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.38, 0.14)
	tween.parallel().tween_property(self, "modulate", Color("ff315b"), 0.14)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.28)


## Drains the old planet color out, then reveals the infected surface
func play_infection_death_animation() -> void:
	death_flash_amount = 1.0
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.42, 0.16)
	tween.parallel().tween_property(self, "modulate", Color("ff315b"), 0.16)
	tween.parallel().tween_property(self, "death_flash_amount", 0.0, 0.48)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.28)


## Makes conquered planets pulse in the order they fell
func play_memory_pulse() -> void:
	if not infected:
		return

	memory_pulse_strength = 1.0
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "memory_pulse_strength", 0.0, 0.9)


func _draw() -> void:
	if visual_type == "ringed_planet":
		_draw_rings()

	if _should_draw_neighbor_pressure():
		_draw_neighbor_pressure()

	var display_color : Color = base_color
	if is_hovered:
		display_color = display_color.lightened(hover_tint_strength)

	draw_circle(Vector2.ZERO, radius + 4.0 + infected_neighbor_count, display_color.darkened(0.65))
	draw_circle(Vector2.ZERO, radius, display_color)
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 40, BORDER_COLOR, 1.6)

	if infected:
		_draw_infected_surface()
		_draw_death_drain_overlay()
		_draw_memory_pulse()
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 40, INFECTED_COLOR.lightened(0.15), 2.5)
	elif infecting:
		_draw_infection_progress()

	var highlight_offset : Vector2 = Vector2(-radius * 0.32, -radius * 0.34)
	draw_circle(highlight_offset, radius * 0.26, Color(1, 1, 1, 0.22))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-REGION_LABEL_WIDTH * 0.5, radius + 17.0),
		region_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		REGION_LABEL_WIDTH,
		14,
		LABEL_COLOR
	)

	if infecting:
		_draw_distress_label()


func _process(_delta : float) -> void:
	if infected or infecting or death_flash_amount > 0.0 or memory_pulse_strength > 0.0 or _should_draw_neighbor_pressure():
		queue_redraw()


func _draw_infection_progress() -> void:
	var progress : float = clamp(infection_progress, 0.0, 1.0)
	var glow_color : Color = INFECTING_COLOR
	glow_color.a = 0.16 + progress * 0.34
	var fill_color : Color = INFECTED_COLOR
	fill_color.a = 0.10 + progress * 0.24

	draw_circle(Vector2.ZERO, radius + 5.0 + sin(Time.get_ticks_msec() / 180.0) * 1.5, glow_color)
	draw_circle(Vector2.ZERO, radius * lerp(0.25, 0.72, progress), fill_color)
	_draw_infection_veins(progress)

	if progress > 0.0:
		var start_angle : float = -PI * 0.5
		var end_angle : float = start_angle + TAU * progress
		draw_arc(Vector2.ZERO, radius + 6.0, start_angle, end_angle, 48, INFECTING_COLOR, 4.0, true)


func _draw_infected_surface() -> void:
	var wash_color : Color = INFECTED_COLOR.darkened(0.32)
	wash_color.a = 0.78
	draw_circle(Vector2.ZERO, radius, wash_color)
	draw_circle(Vector2.ZERO, radius * 0.58, INFECTED_COLOR.darkened(0.08))
	_draw_infection_veins(1.0)


func _draw_death_drain_overlay() -> void:
	if death_flash_amount <= 0.0:
		return

	var drain_color : Color = base_color.lerp(Color("f1f3f8"), 0.68)
	drain_color.a = death_flash_amount * 0.72
	draw_circle(Vector2.ZERO, radius * (0.92 + death_flash_amount * 0.08), drain_color)

	var snap_color : Color = INFECTING_COLOR
	snap_color.a = death_flash_amount * 0.35
	draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 48, snap_color, 4.0, true)


func _draw_memory_pulse() -> void:
	if memory_pulse_strength <= 0.0:
		return

	var pulse_color : Color = INFECTING_COLOR.lightened(0.18)
	pulse_color.a = memory_pulse_strength * 0.42
	draw_arc(Vector2.ZERO, radius + 8.0 + (1.0 - memory_pulse_strength) * 16.0, 0.0, TAU, 54, pulse_color, 2.2, true)


func _should_draw_neighbor_pressure() -> bool:
	return infected_neighbor_count > 0 and not infected and not infecting


func _draw_neighbor_pressure() -> void:
	var pulse : float = sin(Time.get_ticks_msec() / 160.0) * 0.5 + 0.5
	var pressure_color : Color = INFECTING_COLOR
	pressure_color.a = 0.12 + pulse * 0.18
	draw_circle(Vector2.ZERO, radius + 8.0 + infected_neighbor_count * 2.0 + pulse * 3.0, pressure_color)

	for index : int in range(min(infected_neighbor_count + 1, 3)):
		var ring_color : Color = VEIN_COLOR
		ring_color.a = 0.22 - float(index) * 0.045 + pulse * 0.16
		draw_arc(Vector2.ZERO, radius + 9.0 + float(index) * 5.0 + pulse * 4.0, 0.0, TAU, 48, ring_color, 1.8, true)


func _draw_infection_veins(progress : float) -> void:
	var vein_count : int = int(lerp(3.0, 9.0, progress))
	var pulse : float = sin(Time.get_ticks_msec() / 210.0) * 0.5 + 0.5

	for index : int in range(vein_count):
		var angle : float = _get_vein_angle(index)
		var direction : Vector2 = Vector2.RIGHT.rotated(angle)
		var normal : Vector2 = direction.orthogonal()
		var length_scale : float = 0.72 + float((index * 5) % 9) / 18.0
		var end_length : float = radius * lerp(0.58, 2.05, progress) * length_scale
		var wave_amount : float = radius * lerp(0.05, 0.34, progress)
		var points : PackedVector2Array = _get_tendril_points(direction, normal, end_length, wave_amount, index, progress)
		var vein_color : Color = _get_vein_color(index, pulse, progress)
		var core_color : Color = _get_vein_core_color(index)
		var line_width : float = (2.25 + progress * 2.0) * lerp(0.78, 1.18, length_scale)
		var shadow_color : Color = Color(0.0, 0.0, 0.0, 0.34)
		vein_color.a = 0.48 + progress * 0.38
		core_color.a = 0.72
		draw_polyline(points, shadow_color, line_width + 4.8, true)
		draw_polyline(points, core_color, line_width + 2.2, true)
		draw_polyline(points, vein_color, line_width, true)
		_draw_tendril_highlight(points, line_width, pulse, progress)

		if progress > 0.42 and index % 2 == 0:
			var branch_side : float = -1.0 if index % 4 == 0 else 1.0
			var branch_start : Vector2 = points[points.size() - 2]
			var branch_direction : Vector2 = direction.rotated(branch_side * (0.62 + pulse * 0.18))
			var branch_end_length : float = radius * progress * 0.58
			var branch_points : PackedVector2Array = PackedVector2Array([
				branch_start,
				branch_start + branch_direction * branch_end_length * 0.46 + normal * branch_side * wave_amount * 0.28,
				branch_start + branch_direction * branch_end_length,
			])
			draw_polyline(branch_points, shadow_color, line_width * 0.72 + 2.8, true)
			draw_polyline(branch_points, core_color, line_width * 0.72 + 1.2, true)
			draw_polyline(branch_points, vein_color, line_width * 0.52, true)

		if progress > 0.62:
			var bulb_color : Color = vein_color
			bulb_color.a *= 0.82
			draw_circle(points[points.size() - 1], line_width * 0.62, core_color)
			draw_circle(points[points.size() - 1], line_width * 0.42, bulb_color)


func _get_tendril_points(direction : Vector2, normal : Vector2, end_length : float, wave_amount : float, index : int, progress : float) -> PackedVector2Array:
	var time : float = Time.get_ticks_msec() / 350.0
	var points : PackedVector2Array = PackedVector2Array()
	var start_offset : float = radius * lerp(0.02, 0.16, progress)

	for point_index : int in range(6):
		var point_progress : float = float(point_index) / 5.0
		var length : float = lerp(start_offset, end_length, point_progress)
		var wave : float = sin(time + index * 1.31 + point_progress * PI * 2.2) * wave_amount * point_progress
		var secondary_wave : float = cos(time * 0.7 + index * 0.9 + point_progress * PI) * wave_amount * 0.35 * point_progress
		points.append((direction * length) + (normal * wave) + (direction.orthogonal() * secondary_wave))

	return points


func _draw_tendril_highlight(points : PackedVector2Array, line_width : float, pulse : float, progress : float) -> void:
	if points.size() < 3:
		return

	var highlight_points : PackedVector2Array = PackedVector2Array()
	for point : Vector2 in points:
		highlight_points.append(point * 0.94)

	var highlight_color : Color = VEIN_FLESH_HIGHLIGHT
	highlight_color.a = (0.16 + pulse * 0.16) * progress
	draw_polyline(highlight_points, highlight_color, max(line_width * 0.32, 1.0), true)


func _get_vein_angle(index : int) -> float:
	var name_offset : float = float(region_name.length() % 11) * 0.17
	return index * 2.399 + name_offset


func _get_vein_color(index : int, pulse : float, progress : float) -> Color:
	var base_color : Color = VEIN_COLOR if index % 2 == 0 else VEIN_PURPLE_COLOR
	var hot_color : Color = INFECTING_COLOR.lightened(0.22) if index % 2 == 0 else VEIN_PURPLE_COLOR.lightened(0.28)
	return base_color.lerp(hot_color, pulse * lerp(0.18, 0.42, progress))


func _get_vein_core_color(index : int) -> Color:
	if index % 2 == 0:
		return VEIN_CORE_COLOR
	return VEIN_PURPLE_CORE_COLOR


func _draw_distress_label() -> void:
	var status_color : Color = DISTRESS_COLOR
	status_color.a = 0.64 + sin(Time.get_ticks_msec() / 130.0) * 0.22
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-DISTRESS_LABEL_WIDTH * 0.5, radius + 32.0),
		_get_distress_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		DISTRESS_LABEL_WIDTH,
		10,
		status_color
	)


func _get_distress_text() -> String:
	if infection_progress >= 0.78:
		return "TRANSMISSION CRITICAL"
	if infection_progress >= 0.52:
		return "CITIES DARKENING"
	if infection_progress >= 0.26:
		return "CONTAINMENT FAILING"
	return "STABLE?"


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
