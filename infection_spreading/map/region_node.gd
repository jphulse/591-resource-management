@tool
class_name RegionNode
extends Area2D

signal infection_state_changed(region : RegionNode, infected : bool)

const REGION_LABEL_WIDTH : float = 118.0
const DISTRESS_LABEL_WIDTH : float = 178.0

@export_group("Identity")
@export var region_id : String = "":
	set(value):
		region_id = value
		queue_redraw()
@export var display_name : String = "":
	set(value):
		display_name = value
		queue_redraw()
@export var visual_profile : RegionVisualProfile = null:
	set(value):
		visual_profile = value
		queue_redraw()

@export_group("Layout")
@export var radius : float = 18.0:
	set(value):
		radius = max(value, 1.0)
		_sync_collision_shape()
		queue_redraw()
@export var base_color : Color = Color.WHITE:
	set(value):
		base_color = value
		queue_redraw()

@export_group("Connections")
@export var neighbors : Array[NodePath] = []

@export_group("Infection Balance")
@export var starts_infected : bool = false:
	set(value):
		starts_infected = value
		if Engine.is_editor_hint():
			infected = starts_infected
			infection_progress = 1.0 if infected else 0.0
		queue_redraw()
@export var infection_cps_threshold : float = 100.0
@export var takeover_duration : float = 24.0
@export var outbreak_click_multiplier : float = 2.0
@export var outbreak_duration : float = 10.0

var infected : bool = false
var infecting : bool = false
var infection_progress : float = 0.0
var infected_neighbor_count : int = 0
var is_hovered : bool = false
var death_flash_amount : float = 0.0
var memory_pulse_strength : float = 0.0
var fallback_visual_profile : RegionVisualProfile = RegionVisualProfile.new()

@onready var collision_shape : CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_sync_collision_shape()
	reset_for_stage()
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	queue_redraw()


func reset_for_stage() -> void:
	infected = starts_infected
	infecting = false
	infection_progress = 1.0 if infected else 0.0
	infected_neighbor_count = 0
	death_flash_amount = 0.0
	memory_pulse_strength = 0.0
	queue_redraw()


func get_region_id() -> String:
	if not region_id.is_empty():
		return region_id
	return name


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return get_region_id()


func get_neighbor_regions() -> Array[RegionNode]:
	var ret_val : Array[RegionNode] = []
	for neighbor_path : NodePath in neighbors:
		if neighbor_path.is_empty():
			continue

		var neighbor : Node = get_node_or_null(neighbor_path)
		if neighbor is RegionNode and neighbor != self:
			ret_val.append(neighbor as RegionNode)
	return ret_val


func set_infected(value : bool) -> void:
	if infected == value:
		return

	infected = value
	infecting = false
	infection_progress = 1.0 if infected else 0.0
	infection_state_changed.emit(self, infected)
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


## Gives a newly infected region a quick gross pop.
func play_infection_burst() -> void:
	if Engine.is_editor_hint():
		return

	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.38, 0.14)
	tween.parallel().tween_property(self, "modulate", _get_profile().infected_color.lightened(0.08), 0.14)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.28)


## Drains the old region color out, then reveals the infected surface.
func play_infection_death_animation() -> void:
	if Engine.is_editor_hint():
		return

	death_flash_amount = 1.0
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.42, 0.16)
	tween.parallel().tween_property(self, "modulate", _get_profile().infected_color.lightened(0.08), 0.16)
	tween.parallel().tween_property(self, "death_flash_amount", 0.0, 0.48)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.28)


## Makes conquered regions pulse in the order they fell.
func play_memory_pulse() -> void:
	if Engine.is_editor_hint() or not infected:
		return

	memory_pulse_strength = 1.0
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "memory_pulse_strength", 0.0, 0.9)


func _draw() -> void:
	var profile : RegionVisualProfile = _get_profile()
	if profile.shape_mode == RegionVisualProfile.ShapeMode.RINGED_ORB:
		_draw_rings(profile)

	if _should_draw_neighbor_pressure():
		_draw_neighbor_pressure(profile)

	if profile.texture != null:
		_draw_texture_body(profile)
	else:
		_draw_procedural_body(profile)

	if infected:
		_draw_infected_surface(profile)
		_draw_death_drain_overlay(profile)
		_draw_memory_pulse(profile)
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 40, profile.infected_color.lightened(0.15), 2.5)
	elif infecting:
		_draw_infection_progress(profile)

	_draw_label(profile)

	if infecting:
		_draw_distress_label(profile)


func _process(_delta : float) -> void:
	if infected or infecting or death_flash_amount > 0.0 or memory_pulse_strength > 0.0 or _should_draw_neighbor_pressure():
		queue_redraw()


func _sync_collision_shape() -> void:
	if not is_node_ready() or collision_shape == null:
		return

	var circle_shape : CircleShape2D = collision_shape.shape as CircleShape2D
	if circle_shape == null:
		circle_shape = CircleShape2D.new()
	else:
		circle_shape = circle_shape.duplicate() as CircleShape2D
	collision_shape.shape = circle_shape
	circle_shape.radius = radius + 8.0


func _get_profile() -> RegionVisualProfile:
	if visual_profile != null:
		return visual_profile
	return fallback_visual_profile


func _get_body_color(profile : RegionVisualProfile) -> Color:
	if base_color != Color.WHITE:
		return base_color
	return profile.base_color


func _draw_procedural_body(profile : RegionVisualProfile) -> void:
	match profile.shape_mode:
		RegionVisualProfile.ShapeMode.CORE:
			_draw_core_body(profile)
		RegionVisualProfile.ShapeMode.CLUSTER:
			_draw_cluster_body(profile)
		RegionVisualProfile.ShapeMode.CLOUD:
			_draw_cloud_body(profile)
		RegionVisualProfile.ShapeMode.LANE:
			_draw_lane_body(profile)
		RegionVisualProfile.ShapeMode.SPIRAL_GALAXY:
			_draw_spiral_galaxy_body(profile)
		_:
			_draw_orb_body(profile)


func _draw_orb_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	if is_hovered:
		display_color = display_color.lightened(profile.hover_tint_strength)

	draw_circle(Vector2.ZERO, radius + 4.0 + infected_neighbor_count, display_color.darkened(0.65))
	draw_circle(Vector2.ZERO, radius, display_color)
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 40, profile.border_color, 1.6)

	var highlight_offset : Vector2 = Vector2(-radius * 0.32, -radius * 0.34)
	draw_circle(highlight_offset, radius * 0.26, Color(1, 1, 1, 0.22))


func _draw_core_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	draw_circle(Vector2.ZERO, radius + 9.0, display_color.darkened(0.82))
	draw_circle(Vector2.ZERO, radius, display_color.darkened(0.22))
	draw_circle(Vector2.ZERO, radius * 0.46, display_color.lightened(0.28))
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 56, profile.border_color, 2.0)


func _draw_cluster_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	draw_circle(Vector2.ZERO, radius + 6.0, display_color.darkened(0.78))
	for index : int in range(9):
		var angle : float = float(index) * 2.399
		var distance : float = radius * (0.18 + float((index * 7) % 10) / 15.0)
		var dot_radius : float = radius * (0.14 + float((index * 5) % 7) / 38.0)
		draw_circle(Vector2.RIGHT.rotated(angle) * distance, dot_radius, display_color.lightened(float(index % 3) * 0.12))
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 48, profile.border_color, 1.4)


func _draw_cloud_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	for index : int in range(7):
		var angle : float = float(index) * 1.74
		var blob_offset : Vector2 = Vector2.RIGHT.rotated(angle) * radius * (0.15 + float(index % 3) * 0.12)
		var blob_color : Color = display_color.lightened(float(index % 2) * 0.08)
		blob_color.a *= 0.84
		draw_circle(blob_offset, radius * (0.45 + float((index * 3) % 5) * 0.06), blob_color)
	draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 50, profile.border_color, 1.3)


func _draw_lane_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	draw_set_transform(Vector2.ZERO, deg_to_rad(-14.0), Vector2(1.85, 0.48))
	draw_circle(Vector2.ZERO, radius, display_color.darkened(0.24))
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 48, profile.border_color, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_spiral_galaxy_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	if is_hovered:
		display_color = display_color.lightened(profile.hover_tint_strength)

	draw_set_transform(Vector2.ZERO, deg_to_rad(profile.galaxy_rotation_degrees), Vector2(1.0, profile.galaxy_disc_aspect))

	var halo_color : Color = display_color.darkened(0.55)
	halo_color.a = 0.24
	draw_circle(Vector2.ZERO, radius * 1.24 + infected_neighbor_count * 1.5, halo_color)

	var outer_haze : Color = display_color
	outer_haze.a = 0.11
	draw_circle(Vector2.ZERO, radius * 1.05, outer_haze)

	var inner_haze : Color = display_color.lightened(0.12)
	inner_haze.a = 0.22
	draw_circle(Vector2.ZERO, radius * 0.78, inner_haze)

	var core_color : Color = display_color.lightened(0.42)
	core_color.a = 0.95
	draw_circle(Vector2.ZERO, radius * 0.28, core_color)
	draw_circle(Vector2.ZERO, radius * 0.12, Color(1.0, 0.98, 0.92, 0.88))

	if profile.galaxy_bar_strength > 0.0:
		_draw_galaxy_bar(profile, display_color)

	if profile.galaxy_ring_strength > 0.0:
		_draw_galaxy_ring(profile, display_color)

	var time : float = Time.get_ticks_msec() / 1400.0
	var arm_count : int = max(profile.galaxy_arm_count, 2)
	for arm_index : int in range(arm_count):
		var arm_points : PackedVector2Array = PackedVector2Array()
		for step : int in range(17):
			var arm_progress : float = float(step) / 16.0
			var curve_angle : float = float(arm_index) * (TAU / float(arm_count))
			curve_angle += arm_progress * PI * profile.galaxy_arm_curve
			curve_angle += sin(time + float(arm_index) * 0.7) * 0.08
			var arm_distance : float = lerp(radius * 0.12, radius * 1.04, pow(arm_progress, 0.86))
			var side_wave : float = sin((arm_progress * PI * 3.4) + time * 1.2 + float(arm_index)) * radius * 0.035
			var point_direction : Vector2 = Vector2.RIGHT.rotated(curve_angle)
			var point_normal : Vector2 = point_direction.orthogonal()
			arm_points.append((point_direction * arm_distance) + (point_normal * side_wave))

		var arm_shadow : Color = Color(0.0, 0.0, 0.0, 0.32)
		var arm_color : Color = display_color.lightened(0.12 + float(arm_index % 2) * 0.08)
		var arm_glow : Color = profile.border_color.lightened(0.08)
		arm_color.a = 0.52
		arm_glow.a = 0.34
		draw_polyline(arm_points, arm_shadow, radius * 0.16, true)
		draw_polyline(arm_points, arm_color, radius * 0.11, true)
		draw_polyline(arm_points, arm_glow, max(radius * 0.04, 1.2), true)

	_draw_galaxy_starfield(profile, display_color)
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 48, profile.border_color, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_galaxy_bar(profile : RegionVisualProfile, display_color : Color) -> void:
	var bar_shadow : Color = Color(0.0, 0.0, 0.0, 0.36)
	var bar_color : Color = display_color.lightened(0.18)
	var bar_highlight : Color = profile.border_color
	var bar_length : float = radius * lerp(0.72, 1.12, profile.galaxy_bar_strength)
	var bar_width : float = radius * lerp(0.12, 0.22, profile.galaxy_bar_strength)
	bar_color.a = 0.48 + profile.galaxy_bar_strength * 0.2
	bar_highlight.a = 0.26 + profile.galaxy_bar_strength * 0.18
	draw_line(Vector2(-bar_length, 0.0), Vector2(bar_length, 0.0), bar_shadow, bar_width + 5.0, true)
	draw_line(Vector2(-bar_length, 0.0), Vector2(bar_length, 0.0), bar_color, bar_width + 1.8, true)
	draw_line(Vector2(-bar_length * 0.82, 0.0), Vector2(bar_length * 0.82, 0.0), bar_highlight, max(bar_width * 0.34, 1.2), true)


func _draw_galaxy_ring(profile : RegionVisualProfile, display_color : Color) -> void:
	var ring_radius : float = radius * lerp(0.62, 0.82, profile.galaxy_ring_strength)
	var ring_width : float = radius * lerp(0.08, 0.18, profile.galaxy_ring_strength)
	var ring_color : Color = display_color.lightened(0.22)
	var ring_glow : Color = profile.border_color
	ring_color.a = 0.22 + profile.galaxy_ring_strength * 0.18
	ring_glow.a = 0.12 + profile.galaxy_ring_strength * 0.14
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, ring_glow, ring_width + 2.0)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, ring_color, ring_width)


func _draw_galaxy_starfield(profile : RegionVisualProfile, display_color : Color) -> void:
	for star_index : int in range(profile.galaxy_star_count):
		var star_angle : float = float(star_index) * 2.171 + float(get_region_id().length()) * 0.13
		var star_distance : float = radius * (0.28 + float((star_index * 7) % 9) / 10.5)
		var star_radius : float = radius * (0.028 + float((star_index * 3) % 4) / 110.0)
		var star_color : Color = display_color.lightened(0.4 + float(star_index % 3) * 0.08)
		star_color.a = 0.24 + float(star_index % 4) * 0.08
		draw_circle(Vector2.RIGHT.rotated(star_angle) * star_distance, star_radius, star_color)


func _draw_texture_body(profile : RegionVisualProfile) -> void:
	var display_color : Color = _get_body_color(profile)
	if is_hovered:
		display_color = display_color.lightened(profile.hover_tint_strength)

	var texture_rect : Rect2 = Rect2(Vector2.ONE * -radius, Vector2.ONE * radius * 2.0)
	draw_circle(Vector2.ZERO, radius + 4.0 + infected_neighbor_count, display_color.darkened(0.65))
	draw_texture_rect(profile.texture, texture_rect, false, Color.WHITE)
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 48, profile.border_color, 1.6)


func _draw_label(profile : RegionVisualProfile) -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-REGION_LABEL_WIDTH * 0.5, radius + 17.0),
		get_display_name(),
		HORIZONTAL_ALIGNMENT_CENTER,
		REGION_LABEL_WIDTH,
		14,
		profile.label_color
	)


func _draw_infection_progress(profile : RegionVisualProfile) -> void:
	var progress : float = clamp(infection_progress, 0.0, 1.0)
	var glow_color : Color = profile.infecting_color
	glow_color.a = 0.16 + progress * 0.34
	var fill_color : Color = profile.infected_color
	fill_color.a = 0.10 + progress * 0.24

	draw_circle(Vector2.ZERO, radius + 5.0 + sin(Time.get_ticks_msec() / 180.0) * 1.5, glow_color)
	draw_circle(Vector2.ZERO, radius * lerp(0.25, 0.72, progress), fill_color)
	_draw_infection_veins(profile, progress)

	if progress > 0.0:
		var start_angle : float = -PI * 0.5
		var end_angle : float = start_angle + TAU * progress
		draw_arc(Vector2.ZERO, radius + 6.0, start_angle, end_angle, 48, profile.infecting_color, 4.0, true)


func _draw_infected_surface(profile : RegionVisualProfile) -> void:
	var wash_color : Color = profile.infected_color.darkened(0.32)
	wash_color.a = 0.78
	draw_circle(Vector2.ZERO, radius, wash_color)
	draw_circle(Vector2.ZERO, radius * 0.58, profile.infected_color.darkened(0.08))
	_draw_infection_veins(profile, 1.0)


func _draw_death_drain_overlay(profile : RegionVisualProfile) -> void:
	if death_flash_amount <= 0.0:
		return

	var drain_color : Color = _get_body_color(profile).lerp(Color("f1f3f8"), 0.68)
	drain_color.a = death_flash_amount * 0.72
	draw_circle(Vector2.ZERO, radius * (0.92 + death_flash_amount * 0.08), drain_color)

	var snap_color : Color = profile.infecting_color
	snap_color.a = death_flash_amount * 0.35
	draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 48, snap_color, 4.0, true)


func _draw_memory_pulse(profile : RegionVisualProfile) -> void:
	if memory_pulse_strength <= 0.0:
		return

	var pulse_color : Color = profile.infecting_color.lightened(0.18)
	pulse_color.a = memory_pulse_strength * 0.42
	draw_arc(Vector2.ZERO, radius + 8.0 + (1.0 - memory_pulse_strength) * 16.0, 0.0, TAU, 54, pulse_color, 2.2, true)


func _should_draw_neighbor_pressure() -> bool:
	return infected_neighbor_count > 0 and not infected and not infecting


func _draw_neighbor_pressure(profile : RegionVisualProfile) -> void:
	var pulse : float = sin(Time.get_ticks_msec() / 160.0) * 0.5 + 0.5
	var pressure_color : Color = profile.infecting_color
	pressure_color.a = 0.12 + pulse * 0.18
	draw_circle(Vector2.ZERO, radius + 8.0 + infected_neighbor_count * 2.0 + pulse * 3.0, pressure_color)

	for index : int in range(min(infected_neighbor_count + 1, 3)):
		var ring_color : Color = profile.vein_color
		ring_color.a = 0.22 - float(index) * 0.045 + pulse * 0.16
		draw_arc(Vector2.ZERO, radius + 9.0 + float(index) * 5.0 + pulse * 4.0, 0.0, TAU, 48, ring_color, 1.8, true)


func _draw_infection_veins(profile : RegionVisualProfile, progress : float) -> void:
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
		var vein_color : Color = _get_vein_color(profile, index, pulse, progress)
		var core_color : Color = _get_vein_core_color(profile, index)
		var line_width : float = (2.25 + progress * 2.0) * lerp(0.78, 1.18, length_scale)
		var shadow_color : Color = Color(0.0, 0.0, 0.0, 0.34)
		vein_color.a = 0.48 + progress * 0.38
		core_color.a = 0.72
		draw_polyline(points, shadow_color, line_width + 4.8, true)
		draw_polyline(points, core_color, line_width + 2.2, true)
		draw_polyline(points, vein_color, line_width, true)
		_draw_tendril_highlight(profile, points, line_width, pulse, progress)
		_draw_tendril_branch(profile, points, direction, normal, wave_amount, line_width, index, pulse, progress)


func _draw_tendril_branch(
	profile : RegionVisualProfile,
	points : PackedVector2Array,
	direction : Vector2,
	normal : Vector2,
	wave_amount : float,
	line_width : float,
	index : int,
	pulse : float,
	progress : float
) -> void:
	if progress <= 0.42 or index % 2 != 0:
		if progress > 0.62:
			_draw_tendril_bulb(profile, points, line_width, index, pulse, progress)
		return

	var branch_side : float = -1.0 if index % 4 == 0 else 1.0
	var branch_start : Vector2 = points[points.size() - 2]
	var branch_direction : Vector2 = direction.rotated(branch_side * (0.62 + pulse * 0.18))
	var branch_end_length : float = radius * progress * 0.58
	var branch_points : PackedVector2Array = PackedVector2Array([
		branch_start,
		branch_start + branch_direction * branch_end_length * 0.46 + normal * branch_side * wave_amount * 0.28,
		branch_start + branch_direction * branch_end_length,
	])
	var shadow_color : Color = Color(0.0, 0.0, 0.0, 0.34)
	var core_color : Color = _get_vein_core_color(profile, index)
	var vein_color : Color = _get_vein_color(profile, index, pulse, progress)
	core_color.a = 0.72
	vein_color.a = 0.48 + progress * 0.38
	draw_polyline(branch_points, shadow_color, line_width * 0.72 + 2.8, true)
	draw_polyline(branch_points, core_color, line_width * 0.72 + 1.2, true)
	draw_polyline(branch_points, vein_color, line_width * 0.52, true)

	if progress > 0.62:
		_draw_tendril_bulb(profile, points, line_width, index, pulse, progress)


func _draw_tendril_bulb(
	profile : RegionVisualProfile,
	points : PackedVector2Array,
	line_width : float,
	index : int,
	pulse : float,
	progress : float
) -> void:
	var vein_color : Color = _get_vein_color(profile, index, pulse, progress)
	var core_color : Color = _get_vein_core_color(profile, index)
	vein_color.a *= 0.82
	draw_circle(points[points.size() - 1], line_width * 0.62, core_color)
	draw_circle(points[points.size() - 1], line_width * 0.42, vein_color)


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


func _draw_tendril_highlight(profile : RegionVisualProfile, points : PackedVector2Array, line_width : float, pulse : float, progress : float) -> void:
	if points.size() < 3:
		return

	var highlight_points : PackedVector2Array = PackedVector2Array()
	for point : Vector2 in points:
		highlight_points.append(point * 0.94)

	var highlight_color : Color = profile.vein_highlight_color
	highlight_color.a = (0.16 + pulse * 0.16) * progress
	draw_polyline(highlight_points, highlight_color, max(line_width * 0.32, 1.0), true)


func _get_vein_angle(index : int) -> float:
	var name_offset : float = float(get_region_id().length() % 11) * 0.17
	return index * 2.399 + name_offset


func _get_vein_color(profile : RegionVisualProfile, index : int, pulse : float, progress : float) -> Color:
	var vein_color : Color = profile.vein_color if index % 2 == 0 else profile.vein_alt_color
	var hot_color : Color = profile.infecting_color.lightened(0.22) if index % 2 == 0 else profile.vein_alt_color.lightened(0.28)
	return vein_color.lerp(hot_color, pulse * lerp(0.18, 0.42, progress))


func _get_vein_core_color(profile : RegionVisualProfile, index : int) -> Color:
	if index % 2 == 0:
		return profile.vein_core_color
	return profile.vein_alt_core_color


func _draw_distress_label(profile : RegionVisualProfile) -> void:
	var status_color : Color = profile.distress_color
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
		return "SIGNAL DECAYING"
	if infection_progress >= 0.26:
		return "CONTAINMENT FAILING"
	return "STABLE?"


func _draw_rings(profile : RegionVisualProfile) -> void:
	draw_set_transform(Vector2.ZERO, deg_to_rad(-18.0), Vector2(1.0, 0.42))
	draw_arc(Vector2.ZERO, radius + 12.0, 0.0, TAU, 48, profile.inner_ring_color, 7.0)
	draw_arc(Vector2.ZERO, radius + 18.0, 0.0, TAU, 48, profile.outer_ring_color, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()
