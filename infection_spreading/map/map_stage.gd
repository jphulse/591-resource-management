class_name MapStage
extends Node2D

signal stage_cleared

const REGION_SCENE : PackedScene = preload("res://infection_spreading/map/map_region.tscn")
const BACKGROUND_COLOR : Color = Color("121212")
const ORBIT_COLOR : Color = Color("bcbcbc", 0.48)
const TITLE_COLOR : Color = Color("f5f5f5")
const CONNECTION_COLOR : Color = Color("d94452", 0.36)
const PULSE_SCENE = preload("res://infection_spreading/effects/viral_pulse.gd")

@export var stage_config : MapStageConfig
@export var clicker : InfectionClicker = null
var region_lookup : Dictionary = {}
var active_infections : Dictionary = {}
var connection_pulse_strength : float = 0.0

@onready var spread_timer : Timer = %SpreadTimer
@onready var regions_root : Node2D = %RegionsRoot
@onready var effects_root : Node2D = %EffectsRoot


func initialize_stage() -> void:
	if stage_config == null:
		push_warning("MapStage is missing a stage_config resource.")
		return

	_clear_regions()
	active_infections.clear()
	_create_regions()
	_refresh_neighbor_pressure()
	spread_timer.start(stage_config.spread_interval)
	queue_redraw()


func _draw() -> void:
	var viewport_rect : Rect2 = get_viewport_rect()
	var half_size : Vector2 = viewport_rect.size * 0.5
	draw_rect(Rect2(-half_size, viewport_rect.size), BACKGROUND_COLOR, true)

	if stage_config != null and stage_config.show_orbits:
		for region_config : MapRegionConfig in stage_config.regions:
			draw_arc(Vector2.ZERO, region_config.orbit, 0.0, TAU, 100, ORBIT_COLOR, 1.4, true)

	for region_config : MapRegionConfig in _get_region_configs():
		var source_name : String = region_config.region_name
		var source_region : MapRegion = region_lookup.get(source_name)
		if source_region == null:
			continue

		for neighbor_name : String in region_config.neighbors:
			if source_name > neighbor_name:
				continue

			var target_region : MapRegion = region_lookup.get(neighbor_name)
			if target_region == null:
				continue

			if source_region.infected or target_region.infected or source_region.infecting or target_region.infecting:
				var color : Color = CONNECTION_COLOR
				if source_region.infecting or target_region.infecting:
					color = color.lerp(Color("ff0033"), 0.42)
				color.a = clamp(color.a + (connection_pulse_strength * 0.45), 0.0, 0.95)
				var width : float = lerp(2.0, 4.5, connection_pulse_strength)
				draw_line(source_region.position, target_region.position, color, width, true)

	var title_position : Vector2 = Vector2(-half_size.x + 54.0, -half_size.y + 62.0)
	draw_string(
		ThemeDB.fallback_font,
		title_position,
		stage_config.stage_title if stage_config != null else "Stage",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		30,
		TITLE_COLOR
	)


func _create_regions() -> void:
	for region_config : MapRegionConfig in _get_region_configs():
		var region : MapRegion = REGION_SCENE.instantiate() as MapRegion
		var region_position : Vector2 = _get_region_position(region_config)

		regions_root.add_child(region)
		region.configure(
			region_config.region_name,
			region_position,
			region_config.radius,
			region_config.color,
			region_config.starts_infected,
			region_config.visual_type
		)
		region_lookup[region_config.region_name] = region


func _get_region_position(region_config : MapRegionConfig) -> Vector2:
	if region_config.use_explicit_position:
		return region_config.position

	var orbit_radius : float = region_config.orbit
	var angle_radians : float = deg_to_rad(region_config.angle)
	return Vector2.RIGHT.rotated(angle_radians) * orbit_radius


func _clear_regions() -> void:
	region_lookup.clear()
	active_infections.clear()
	for child : Node in regions_root.get_children():
		child.queue_free()


func _on_spread_timer_timeout() -> void:
	var newly_started : Array[MapRegion] = []
	var effective_cps : float = _get_effective_infection_cps()

	for region_config : MapRegionConfig in _get_region_configs():
		var region_name : String = region_config.region_name
		var region : MapRegion = region_lookup.get(region_name)
		if region == null or region.infected or region.infecting:
			continue

		var infected_neighbors : int = _count_infected_neighbors(region_config.neighbors)
		if infected_neighbors <= 0:
			continue

		if effective_cps < region_config.infection_cps_threshold:
			continue

		var spread_chance : float = _get_spread_chance(region_config, effective_cps, infected_neighbors)
		if randf() <= spread_chance:
			newly_started.append(region)

	for region : MapRegion in newly_started:
		_start_region_infection(region)

	if newly_started.is_empty():
		return

	queue_redraw()


func _process(delta : float) -> void:
	var needs_redraw : bool = _update_active_infections(delta)

	if connection_pulse_strength > 0.0:
		connection_pulse_strength = move_toward(connection_pulse_strength, 0.0, delta * 2.4)
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _refresh_neighbor_pressure() -> void:
	for region_config : MapRegionConfig in _get_region_configs():
		var region : MapRegion = region_lookup.get(region_config.region_name)
		if region == null:
			continue
		region.set_infected_neighbor_count(_count_infected_neighbors(region_config.neighbors))


func _get_effective_infection_cps() -> float:
	if clicker == null:
		return 0.0
	return clicker.get_effective_infection_cps()


func _get_spread_chance(region_config : MapRegionConfig, effective_cps : float, infected_neighbors : int) -> float:
	var threshold : float = max(region_config.infection_cps_threshold, 1.0)
	var over_threshold_amount : float = (effective_cps / threshold) - 1.0
	var chance_per_neighbor : float = stage_config.minimum_spread_chance + (over_threshold_amount * stage_config.cps_over_threshold_spread_scale)
	var total_chance : float = chance_per_neighbor * infected_neighbors
	return clamp(total_chance, 0.0, stage_config.maximum_spread_chance)


func _start_region_infection(region : MapRegion) -> void:
	region.start_infection()
	active_infections[region.region_name] = true
	_spawn_region_pulse(region, Color("ff6b18"), region.radius * 3.2, 0.5)
	connection_pulse_strength = max(connection_pulse_strength, 0.7)


func _update_active_infections(delta : float) -> bool:
	if active_infections.is_empty():
		return false

	var changed : bool = false
	var completed_regions : Array[MapRegion] = []
	var effective_cps : float = _get_effective_infection_cps()

	for region_name : String in active_infections.keys():
		var region_config : MapRegionConfig = _get_region_config(region_name)
		var region : MapRegion = region_lookup.get(region_name)
		if region_config == null or region == null or region.infected:
			active_infections.erase(region_name)
			changed = true
			continue

		var infected_neighbors : int = _count_infected_neighbors(region_config.neighbors)
		if infected_neighbors <= 0 or effective_cps < region_config.infection_cps_threshold:
			continue

		var progress_rate : float = _get_takeover_progress_rate(region_config, effective_cps, infected_neighbors)
		region.set_infection_progress(region.infection_progress + (progress_rate * delta))
		changed = true

		if region.infection_progress >= 1.0:
			completed_regions.append(region)

	for region : MapRegion in completed_regions:
		_complete_region_infection(region)
		changed = true

	return changed


func _get_takeover_progress_rate(region_config : MapRegionConfig, effective_cps : float, infected_neighbors : int) -> float:
	var threshold : float = max(region_config.infection_cps_threshold, 1.0)
	var takeover_duration : float = max(region_config.takeover_duration, stage_config.minimum_takeover_duration)
	var cps_pressure : float = log(1.0 + (effective_cps / threshold)) / log(2.0)
	var neighbor_pressure : float = 1.0 + max(infected_neighbors - 1, 0) * stage_config.neighbor_takeover_bonus
	var progress_rate : float = (1.0 / takeover_duration) * cps_pressure * neighbor_pressure
	var max_progress_rate : float = 1.0 / max(stage_config.minimum_takeover_duration, 0.1)
	return clamp(progress_rate, 0.0, max_progress_rate)


func _complete_region_infection(region : MapRegion) -> void:
	active_infections.erase(region.region_name)
	region.set_infected(true)
	region.play_infection_burst()
	_spawn_region_pulse(region, Color("ff0033"), region.radius * 5.5, 0.72)
	_add_outbreak_boost_for_region(region.region_name)
	_refresh_neighbor_pressure()
	queue_redraw()

	if _all_regions_infected():
		spread_timer.stop()
		stage_cleared.emit()


func _add_outbreak_boost_for_region(region_name : String) -> void:
	if clicker == null:
		return

	for region_config : MapRegionConfig in _get_region_configs():
		if region_config.region_name == region_name:
			clicker.add_outbreak_click_boost(region_config.outbreak_click_multiplier, region_config.outbreak_duration)
			return


func _spawn_region_pulse(region : MapRegion, color : Color, target_radius : float, duration : float) -> void:
	var pulse : ViralPulse = PULSE_SCENE.new() as ViralPulse
	effects_root.add_child(pulse)
	pulse.position = region.position
	pulse.setup(color, target_radius, duration, 5.0)
	connection_pulse_strength = 1.0


func _count_infected_neighbors(neighbors : PackedStringArray) -> int:
	var count : int = 0
	for neighbor_name : String in neighbors:
		var region : MapRegion = region_lookup.get(neighbor_name)
		if region != null and region.infected:
			count += 1
	return count


func _all_regions_infected() -> bool:
	for region : MapRegion in region_lookup.values():
		if not region.infected:
			return false
	return true


func _get_region_config(region_name : String) -> MapRegionConfig:
	for region_config : MapRegionConfig in _get_region_configs():
		if region_config.region_name == region_name:
			return region_config
	return null


func _get_region_configs() -> Array[MapRegionConfig]:
	if stage_config == null:
		return []
	return stage_config.regions
