class_name AutoClickerTendrils
extends Node2D

const MAX_VISIBLE_SPORE_TENDRILS : int = 18
const MAX_VISIBLE_HIVE_TENDRILS : int = 8
const SPORE_SLOT_STEP : int = 7
const HIVE_SLOT_STEP : int = 3
const SUN_RADIUS : float = 60.0
const MIN_SPORE_LENGTH : float = 42.0
const MAX_SPORE_LENGTH : float = 92.0
const MIN_HIVE_LENGTH : float = 92.0
const MAX_HIVE_LENGTH : float = 190.0
const SPORE_COLOR : Color = Color("d94452", 0.62)
const SPORE_CORE_COLOR : Color = Color("ff0033", 0.85)
const HIVE_COLOR : Color = Color("a4146e", 0.72)
const HIVE_CORE_COLOR : Color = Color("ff2ca8", 0.92)
const HIVE_BRANCH_COLOR : Color = Color("ff385e", 0.58)

var spore_tendril_count : int = 0
var hive_tendril_count : int = 0
var pulse_time : float = 0.0


## Updates how many auto clicker tendrils should reach out from the sun
func set_tendril_count(value : int) -> void:
	set_tendril_counts(value, 0)


## Updates the visual tendril counts for each auto clicker type
func set_tendril_counts(spore_count : int, hive_count : int) -> void:
	if spore_tendril_count == spore_count and hive_tendril_count == hive_count:
		return

	spore_tendril_count = spore_count
	hive_tendril_count = hive_count
	queue_redraw()


func _process(delta : float) -> void:
	pulse_time += delta
	if _get_total_tendril_count() > 0:
		queue_redraw()


func _draw() -> void:
	var total_tendril_count : int = _get_total_tendril_count()
	if total_tendril_count <= 0:
		return

	var pulse : float = sin(pulse_time * 4.1) * 0.5 + 0.5
	var visible_spores : int = min(spore_tendril_count, MAX_VISIBLE_SPORE_TENDRILS)
	var visible_hives : int = min(hive_tendril_count, MAX_VISIBLE_HIVE_TENDRILS)
	var spore_strength : float = _get_growth_strength(spore_tendril_count, MAX_VISIBLE_SPORE_TENDRILS)
	var hive_strength : float = _get_growth_strength(hive_tendril_count, MAX_VISIBLE_HIVE_TENDRILS)
	var total_strength : float = _get_growth_strength(total_tendril_count, MAX_VISIBLE_SPORE_TENDRILS + MAX_VISIBLE_HIVE_TENDRILS)

	for index : int in range(visible_hives):
		_draw_tendril(index, MAX_VISIBLE_HIVE_TENDRILS, HIVE_SLOT_STEP, 0.26, hive_strength, total_strength, pulse, true)

	for index : int in range(visible_spores):
		_draw_tendril(index, MAX_VISIBLE_SPORE_TENDRILS, SPORE_SLOT_STEP, 0.0, spore_strength, total_strength, pulse, false)


func _draw_tendril(index : int, slot_count : int, slot_step : int, angle_offset : float, strength : float, total_strength : float, pulse : float, is_hive : bool) -> void:
	var slot : int = (index * slot_step) % slot_count
	var angle : float = (TAU / slot_count) * slot + angle_offset
	angle += sin(pulse_time * (0.24 if is_hive else 0.34) + index * 1.7) * (0.12 if is_hive else 0.16)
	var length_scale : float = 0.42 + (float((index * 5) % slot_count) / float(max(slot_count - 1, 1))) * 0.58
	var tendril_length : float = 0.0
	var color : Color
	var core_color : Color
	var width : float = 0.0

	if is_hive:
		tendril_length = lerp(MIN_HIVE_LENGTH, MAX_HIVE_LENGTH, length_scale) * (1.0 + strength * 0.5)
		color = HIVE_COLOR.lerp(HIVE_CORE_COLOR, pulse * 0.35)
		core_color = HIVE_CORE_COLOR
		width = 4.4 + pulse * 1.8 + strength * 4.2
	else:
		tendril_length = lerp(MIN_SPORE_LENGTH, MAX_SPORE_LENGTH, length_scale) * (1.0 + strength * 0.34)
		color = SPORE_COLOR.lerp(SPORE_CORE_COLOR, pulse * 0.35)
		core_color = SPORE_CORE_COLOR
		width = 1.5 + pulse * 0.9 + strength * 1.9

	tendril_length += total_strength * (34.0 if is_hive else 18.0)
	tendril_length += sin(pulse_time * 2.0 + index * 1.7) * (14.0 if is_hive else 6.0)

	var direction : Vector2 = Vector2.RIGHT.rotated(angle)
	var normal : Vector2 = direction.orthogonal()
	var start_point : Vector2 = direction * SUN_RADIUS
	var end_point : Vector2 = direction * (SUN_RADIUS + tendril_length)
	var mid_point : Vector2 = direction * (SUN_RADIUS + tendril_length * 0.55)
	mid_point += normal * sin(pulse_time * 2.4 + index * 1.3) * ((24.0 if is_hive else 11.0) + pulse * (11.0 if is_hive else 5.0))

	var points : PackedVector2Array = PackedVector2Array([
		start_point,
		(start_point + mid_point) * 0.5 + normal * sin(pulse_time + index) * (12.0 if is_hive else 5.0),
		mid_point,
		(mid_point + end_point) * 0.5 - normal * cos(pulse_time * 1.6 + index) * (14.0 if is_hive else 6.0),
		end_point,
	])

	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.24), width + (4.0 if is_hive else 2.0), true)
	draw_polyline(points, color, width, true)
	_draw_branches(points, direction, normal, index, strength, total_strength, pulse, width, is_hive)

	if is_hive or index % 3 == 0:
		core_color.a *= 0.62 if is_hive else 0.48
		draw_polyline(points, core_color, max(width * (0.45 if is_hive else 0.34), 1.0), true)

	draw_circle(end_point, width * (1.45 if is_hive else 1.1), color)


func _draw_branches(points : PackedVector2Array, direction : Vector2, normal : Vector2, index : int, strength : float, total_strength : float, pulse : float, width : float, is_hive : bool) -> void:
	var branch_strength : float = clamp((strength - 0.2) / 0.8, 0.0, 1.0)
	var max_branches : int = 4 if is_hive else 3
	var branch_count : int = int(floor(lerp(0.0, float(max_branches), branch_strength)))
	if branch_count <= 0:
		return

	for branch_index : int in range(branch_count):
		var side : float = -1.0 if (index + branch_index) % 2 == 0 else 1.0
		var anchor : Vector2 = _get_point_on_path(points, 0.38 + float(branch_index) * 0.16)
		var branch_direction : Vector2 = direction.rotated(side * (0.46 + float(branch_index) * 0.14 + sin(pulse_time * 1.4 + index) * 0.08))
		var branch_length : float = (36.0 if is_hive else 20.0) + total_strength * (30.0 if is_hive else 16.0) + pulse * (8.0 if is_hive else 4.0)
		var branch_end : Vector2 = anchor + branch_direction * branch_length
		var branch_mid : Vector2 = anchor.lerp(branch_end, 0.58)
		branch_mid += normal * side * sin(pulse_time * 2.1 + index + branch_index) * (9.0 if is_hive else 5.0)
		var branch_points : PackedVector2Array = PackedVector2Array([anchor, branch_mid, branch_end])
		var branch_color : Color = HIVE_BRANCH_COLOR if is_hive else SPORE_CORE_COLOR
		branch_color.a *= 0.48 + pulse * 0.22
		draw_polyline(branch_points, branch_color, max(width * (0.48 if is_hive else 0.38), 1.0), true)
		draw_circle(branch_end, max(width * 0.38, 1.0), branch_color)


func _get_point_on_path(points : PackedVector2Array, t : float) -> Vector2:
	if points.size() <= 0:
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]

	var scaled_index : float = clamp(t, 0.0, 1.0) * float(points.size() - 1)
	var point_index : int = min(int(floor(scaled_index)), points.size() - 2)
	var point_t : float = scaled_index - float(point_index)
	return points[point_index].lerp(points[point_index + 1], point_t)


func _get_growth_strength(count : int, visible_cap : int) -> float:
	if count <= 0:
		return 0.0

	var base_count : float = max(float(visible_cap), 1.0)
	var scaled_count : float = float(count) / base_count
	return clamp(log(scaled_count + 1.0) / log(4.0), 0.0, 1.0)


func _get_total_tendril_count() -> int:
	return spore_tendril_count + hive_tendril_count
