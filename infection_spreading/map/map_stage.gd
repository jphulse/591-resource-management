class_name MapStage
extends Node2D

signal stage_cleared

const PULSE_SCENE = preload("res://infection_spreading/effects/viral_pulse.gd")
const MAX_LOG_ENTRIES : int = 5
const TAKEOVER_COMPLETE_PROGRESS : float = 0.985
const TAKEOVER_BANNER_DURATION : float = 2.15
const RANDOM_EVENT_MIN_INTERVAL : float = 15.0
const RANDOM_EVENT_MAX_INTERVAL : float = 28.0
const MEMORY_PULSE_INTERVAL : float = 4.25

@export var stage_config : MapStageConfig = null
@export var clicker : InfectionClicker = null

var regions : Array[RegionNode] = []
var active_infections : Array[RegionNode] = []
var infection_log_entries : Array[String] = []
var connection_pulse_strength : float = 0.0
var takeover_banner_text : String = ""
var takeover_banner_color : Color = Color("ff315b")
var takeover_banner_timer : float = 0.0
var random_event_timer : float = 0.0
var infected_memory_order : Array[RegionNode] = []
var memory_pulse_timer : float = MEMORY_PULSE_INTERVAL
var memory_pulse_index : int = 0
var fallback_stage_config : MapStageConfig = MapStageConfig.new()
var fallback_flavor_config : MapStageFlavorConfig = MapStageFlavorConfig.new()

@onready var spread_timer : Timer = %SpreadTimer
@onready var auto_clicker_tendrils : AutoClickerTendrils = %AutoClickerTendrils
@onready var regions_root : Node2D = %RegionsRoot
@onready var effects_root : Node2D = %EffectsRoot


func initialize_stage() -> void:
	if stage_config == null:
		push_warning("MapStage is missing a stage_config resource. Using fallback stage defaults.")

	var config : MapStageConfig = _get_stage_config()
	_discover_regions()
	active_infections.clear()
	infected_memory_order.clear()
	takeover_banner_timer = 0.0
	_reset_random_event_timer()
	memory_pulse_timer = MEMORY_PULSE_INTERVAL
	memory_pulse_index = 0
	auto_clicker_tendrils.position = Vector2.ZERO
	_refresh_neighbor_pressure()
	_initialize_infection_log()
	spread_timer.start(config.spread_interval)
	queue_redraw()


func _draw() -> void:
	var flavor : MapStageFlavorConfig = _get_flavor_config()
	var config : MapStageConfig = _get_stage_config()
	var viewport_rect : Rect2 = get_viewport_rect()
	var half_size : Vector2 = viewport_rect.size * 0.5
	draw_rect(Rect2(-half_size, viewport_rect.size), flavor.background_color, true)
	_draw_region_connections(flavor)

	var title_position : Vector2 = Vector2(-half_size.x + 54.0, -half_size.y + 62.0)
	draw_string(
		ThemeDB.fallback_font,
		title_position,
		config.stage_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		30,
		flavor.title_color
	)
	_draw_infection_log(half_size)
	_draw_corruption_percent(half_size)
	_draw_takeover_banners(half_size)


func _draw_region_connections(flavor : MapStageFlavorConfig) -> void:
	for source_region : RegionNode in regions:
		if not is_instance_valid(source_region):
			continue

		for target_region : RegionNode in source_region.get_neighbor_regions():
			if not _is_region_in_stage(target_region):
				continue

			if source_region.get_instance_id() > target_region.get_instance_id():
				continue

			var has_infection_connection : bool = source_region.infected or target_region.infected or source_region.infecting or target_region.infecting
			if not has_infection_connection:
				continue

			var color : Color = flavor.connection_color
			var is_active_infection_connection : bool = source_region.infecting or target_region.infecting
			if is_active_infection_connection:
				var vein_pulse : float = sin(Time.get_ticks_msec() / 150.0) * 0.5 + 0.5
				color = color.lerp(flavor.active_connection_color, 0.42)
				color.a = clamp(color.a + vein_pulse * 0.28, 0.0, 0.95)
			color.a = clamp(color.a + (connection_pulse_strength * 0.45), 0.0, 0.95)
			var width : float = lerp(2.0, 4.5, connection_pulse_strength)
			if is_active_infection_connection:
				width = max(width, 2.6 + sin(Time.get_ticks_msec() / 150.0) * 1.4 + 1.4)
			draw_line(source_region.position, target_region.position, color, width, true)


func _discover_regions() -> void:
	regions.clear()
	_collect_region_nodes(regions_root)

	var seen_region_ids : Dictionary = {}
	for region : RegionNode in regions:
		region.reset_for_stage()
		var region_key : String = region.get_region_id()
		if seen_region_ids.has(region_key):
			push_warning("Duplicate RegionNode id detected: %s. Region ids should be unique within a stage." % region_key)
		seen_region_ids[region_key] = true


func _collect_region_nodes(parent : Node) -> void:
	for child : Node in parent.get_children():
		if child is RegionNode:
			regions.append(child as RegionNode)
		_collect_region_nodes(child)


func _initialize_infection_log() -> void:
	var flavor : MapStageFlavorConfig = _get_flavor_config()
	infection_log_entries.clear()
	for region : RegionNode in regions:
		if region.infected:
			if not infected_memory_order.has(region):
				infected_memory_order.append(region)
			_add_infection_log(flavor.patient_zero_log_format % region.get_display_name().to_upper())


func _draw_infection_log(half_size : Vector2) -> void:
	if infection_log_entries.is_empty():
		return

	var flavor : MapStageFlavorConfig = _get_flavor_config()
	var start_position : Vector2 = Vector2(-half_size.x + 34.0, half_size.y - 132.0)
	draw_string(ThemeDB.fallback_font, start_position, flavor.infection_log_title, HORIZONTAL_ALIGNMENT_LEFT, 280.0, 14, flavor.log_header_color)

	for index : int in range(infection_log_entries.size()):
		var entry_color : Color = flavor.log_color
		entry_color.a *= 1.0 - float(index) * 0.11
		draw_string(
			ThemeDB.fallback_font,
			start_position + Vector2(0.0, 22.0 + float(index) * 18.0),
			infection_log_entries[index],
			HORIZONTAL_ALIGNMENT_LEFT,
			390.0,
			13,
			entry_color
		)


func _draw_corruption_percent(half_size : Vector2) -> void:
	var flavor : MapStageFlavorConfig = _get_flavor_config()
	var corruption_percent : float = _get_corruption_percent()
	var corruption_color : Color = flavor.corruption_start_color.lerp(flavor.corruption_end_color, corruption_percent * 0.34)
	var label_text : String = flavor.corruption_label_format % int(round(corruption_percent * 100.0))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-half_size.x + 54.0, -half_size.y + 92.0),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		360.0,
		14,
		corruption_color
	)


func _draw_takeover_banners(half_size : Vector2) -> void:
	if takeover_banner_timer > 0.0:
		_draw_center_banner(half_size, takeover_banner_text, takeover_banner_color, takeover_banner_timer, TAKEOVER_BANNER_DURATION, -half_size.y + 124.0, 28)


func _draw_center_banner(half_size : Vector2, display_text : String, color : Color, timer : float, duration : float, y_position : float, font_size : int) -> void:
	if display_text.is_empty():
		return

	var flavor : MapStageFlavorConfig = _get_flavor_config()
	var age : float = duration - timer
	var fade_in : float = clamp(age / 0.18, 0.0, 1.0)
	var fade_out : float = clamp(timer / 0.5, 0.0, 1.0)
	var alpha : float = min(fade_in, fade_out)
	var pulse : float = sin(Time.get_ticks_msec() / 95.0) * 0.5 + 0.5
	var banner_color : Color = color.lerp(flavor.banner_highlight_color, pulse * 0.18)
	var shadow_color : Color = flavor.banner_shadow_color
	banner_color.a = alpha
	shadow_color.a *= alpha

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-half_size.x + 3.0, y_position + 3.0),
		display_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		half_size.x * 2.0,
		font_size,
		shadow_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-half_size.x, y_position),
		display_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		half_size.x * 2.0,
		font_size,
		banner_color
	)


func _add_infection_log(message : String) -> void:
	infection_log_entries.push_front(message)
	while infection_log_entries.size() > MAX_LOG_ENTRIES:
		infection_log_entries.pop_back()
	queue_redraw()


func _on_spread_timer_timeout() -> void:
	var newly_started : Array[RegionNode] = []
	var effective_cps : float = _get_effective_infection_cps()

	for region : RegionNode in regions:
		if not is_instance_valid(region) or region.infected or region.infecting:
			continue

		var infected_neighbors : int = _count_infected_neighbors(region)
		if infected_neighbors <= 0:
			continue

		if effective_cps < region.infection_cps_threshold:
			continue

		var spread_chance : float = _get_spread_chance(region, effective_cps, infected_neighbors)
		if randf() <= spread_chance:
			newly_started.append(region)

	for region : RegionNode in newly_started:
		_start_region_infection(region)

	if newly_started.is_empty():
		return

	queue_redraw()


func _process(delta : float) -> void:
	var needs_redraw : bool = _update_active_infections(delta)

	if connection_pulse_strength > 0.0:
		connection_pulse_strength = move_toward(connection_pulse_strength, 0.0, delta * 2.4)
		needs_redraw = true

	if _update_banner_timers(delta):
		needs_redraw = true

	if _update_random_events(delta):
		needs_redraw = true

	if _update_memory_pulses(delta):
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _update_banner_timers(delta : float) -> bool:
	var changed : bool = false

	if takeover_banner_timer > 0.0:
		takeover_banner_timer = max(takeover_banner_timer - delta, 0.0)
		changed = true

	return changed


func _update_random_events(delta : float) -> bool:
	random_event_timer -= delta
	if random_event_timer > 0.0:
		return false

	_add_infection_log(_get_random_flavor_text(_get_flavor_config().random_event_messages, "Deep space static thickens"))
	_reset_random_event_timer()
	return true


func _update_memory_pulses(delta : float) -> bool:
	if infected_memory_order.size() <= 1:
		return false

	memory_pulse_timer -= delta
	if memory_pulse_timer > 0.0:
		return false

	for _attempt : int in range(infected_memory_order.size()):
		var region : RegionNode = infected_memory_order[memory_pulse_index % infected_memory_order.size()]
		memory_pulse_index += 1
		if _is_region_in_stage(region) and region.infected:
			region.play_memory_pulse()
			break

	memory_pulse_timer = MEMORY_PULSE_INTERVAL
	return false


func _refresh_neighbor_pressure() -> void:
	for region : RegionNode in regions:
		region.set_infected_neighbor_count(_count_infected_neighbors(region))


func _get_effective_infection_cps() -> float:
	if clicker == null:
		return 0.0
	return clicker.get_effective_infection_cps()


func _get_spread_chance(region : RegionNode, effective_cps : float, infected_neighbors : int) -> float:
	var config : MapStageConfig = _get_stage_config()
	var threshold : float = max(region.infection_cps_threshold, 1.0)
	var over_threshold_amount : float = (effective_cps / threshold) - 1.0
	var chance_per_neighbor : float = config.minimum_spread_chance + (over_threshold_amount * config.cps_over_threshold_spread_scale)
	var total_chance : float = chance_per_neighbor * infected_neighbors
	return clamp(total_chance, 0.0, config.maximum_spread_chance)


func _start_region_infection(region : RegionNode) -> void:
	var flavor : MapStageFlavorConfig = _get_flavor_config()
	region.start_infection()
	if not active_infections.has(region):
		active_infections.append(region)
	_show_takeover_banner(flavor.infecting_banner_format % region.get_display_name().to_upper(), flavor.infection_start_color)
	_spawn_region_pulse(region, flavor.infection_start_color, region.radius * 3.2, 0.5)
	_add_infection_log(_get_start_log_message(region))
	connection_pulse_strength = max(connection_pulse_strength, 0.7)


func _update_active_infections(delta : float) -> bool:
	if active_infections.is_empty():
		return false

	var changed : bool = false
	var completed_regions : Array[RegionNode] = []
	var effective_cps : float = _get_effective_infection_cps()

	for region : RegionNode in active_infections.duplicate():
		if not _is_region_in_stage(region) or region.infected:
			active_infections.erase(region)
			changed = true
			continue

		if _is_region_takeover_complete(region):
			completed_regions.append(region)
			continue

		var infected_neighbors : int = _count_infected_neighbors(region)
		if infected_neighbors <= 0 or effective_cps < region.infection_cps_threshold:
			continue

		var progress_rate : float = _get_takeover_progress_rate(region, effective_cps, infected_neighbors)
		region.set_infection_progress(region.infection_progress + (progress_rate * delta))
		changed = true

		if _is_region_takeover_complete(region):
			completed_regions.append(region)

	for region : RegionNode in completed_regions:
		_complete_region_infection(region)
		changed = true

	return changed


func _get_takeover_progress_rate(region : RegionNode, effective_cps : float, infected_neighbors : int) -> float:
	var config : MapStageConfig = _get_stage_config()
	var threshold : float = max(region.infection_cps_threshold, 1.0)
	var takeover_duration : float = max(region.takeover_duration, config.minimum_takeover_duration)
	var cps_pressure : float = log(1.0 + (effective_cps / threshold)) / log(2.0)
	var neighbor_pressure : float = 1.0 + max(infected_neighbors - 1, 0) * config.neighbor_takeover_bonus
	var progress_rate : float = (1.0 / takeover_duration) * cps_pressure * neighbor_pressure
	var max_progress_rate : float = 1.0 / max(config.minimum_takeover_duration, 0.1)
	return clamp(progress_rate, 0.0, max_progress_rate)


func _is_region_takeover_complete(region : RegionNode) -> bool:
	return region.infection_progress >= TAKEOVER_COMPLETE_PROGRESS


func _complete_region_infection(region : RegionNode) -> void:
	var flavor : MapStageFlavorConfig = _get_flavor_config()
	var outbreak_name : String = _get_outbreak_name()
	active_infections.erase(region)
	region.set_infected(true)
	if not infected_memory_order.has(region):
		infected_memory_order.append(region)
	region.play_infection_death_animation()
	_show_takeover_banner(flavor.consumed_banner_format % region.get_display_name().to_upper(), flavor.infection_complete_color)
	_spawn_region_pulse(region, flavor.infection_complete_color, region.radius * 5.5, 0.72)
	_add_infection_log(_get_complete_log_message(region, outbreak_name))
	_add_outbreak_boost_for_region(region, outbreak_name)
	_refresh_neighbor_pressure()
	queue_redraw()

	if _all_regions_infected():
		spread_timer.stop()
		stage_cleared.emit()


func _add_outbreak_boost_for_region(region : RegionNode, outbreak_name : String) -> void:
	if clicker == null:
		return

	clicker.add_outbreak_click_boost(region.outbreak_click_multiplier, region.outbreak_duration, outbreak_name)


func _get_start_log_message(region : RegionNode) -> String:
	var message_format : String = _get_random_flavor_text(_get_flavor_config().infection_start_messages, "%s containment failure detected")
	return message_format % region.get_display_name().to_upper()


func _get_complete_log_message(region : RegionNode, outbreak_name : String) -> String:
	var message_format : String = _get_random_flavor_text(_get_flavor_config().infection_complete_messages, "%s consumed by %s")
	return message_format % [region.get_display_name().to_upper(), outbreak_name]


func _get_outbreak_name() -> String:
	return _get_random_flavor_text(_get_flavor_config().outbreak_names, "Crimson Bloom")


func _show_takeover_banner(display_text : String, color : Color) -> void:
	takeover_banner_text = display_text
	takeover_banner_color = color
	takeover_banner_timer = TAKEOVER_BANNER_DURATION
	queue_redraw()


func _reset_random_event_timer() -> void:
	random_event_timer = randf_range(RANDOM_EVENT_MIN_INTERVAL, RANDOM_EVENT_MAX_INTERVAL)


func _get_corruption_percent() -> float:
	if regions.is_empty():
		return 0.0

	var corruption_amount : float = 0.0
	for region : RegionNode in regions:
		if not is_instance_valid(region):
			continue
		if region.infected:
			corruption_amount += 1.0
		elif region.infecting:
			corruption_amount += region.infection_progress

	return clamp(corruption_amount / float(regions.size()), 0.0, 1.0)


func _spawn_region_pulse(region : RegionNode, color : Color, target_radius : float, duration : float) -> void:
	var pulse : ViralPulse = PULSE_SCENE.new() as ViralPulse
	effects_root.add_child(pulse)
	pulse.position = region.position
	pulse.setup(color, target_radius, duration, 5.0)
	connection_pulse_strength = 1.0


func _count_infected_neighbors(region : RegionNode) -> int:
	var count : int = 0
	for neighbor : RegionNode in region.get_neighbor_regions():
		if _is_region_in_stage(neighbor) and neighbor.infected:
			count += 1
	return count


func _all_regions_infected() -> bool:
	if regions.is_empty():
		return false

	for region : RegionNode in regions:
		if is_instance_valid(region) and not region.infected:
			return false
	return true


func _is_region_in_stage(region : RegionNode) -> bool:
	return region != null and is_instance_valid(region) and regions.has(region)


func _get_stage_config() -> MapStageConfig:
	if stage_config != null:
		return stage_config
	return fallback_stage_config


func _get_flavor_config() -> MapStageFlavorConfig:
	var config : MapStageConfig = _get_stage_config()
	if config.flavor_config != null:
		return config.flavor_config
	return fallback_flavor_config


func _get_random_flavor_text(messages : PackedStringArray, fallback : String) -> String:
	if messages.is_empty():
		return fallback
	return str(messages[randi() % messages.size()])
