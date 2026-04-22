class_name MapStage
extends Node2D

signal stage_cleared

const REGION_SCENE : PackedScene = preload("res://infection_spreading/map/map_region.tscn")
const BACKGROUND_COLOR : Color = Color("121212")
const ORBIT_COLOR : Color = Color("bcbcbc", 0.48)
const TITLE_COLOR : Color = Color("f5f5f5")
const CONNECTION_COLOR : Color = Color("d94452", 0.36)
const PULSE_SCENE = preload("res://infection_spreading/effects/viral_pulse.gd")
const LOG_COLOR : Color = Color("ff9aa5", 0.78)
const LOG_HEADER_COLOR : Color = Color("ff315b", 0.9)
const MAX_LOG_ENTRIES : int = 5
const TAKEOVER_COMPLETE_PROGRESS : float = 0.985
const INFECTION_START_MESSAGES : Array = [
	"%s containment failure detected",
	"%s reports abnormal solar fever",
	"%s orbital quarantine breached",
	"%s transmission bloom beginning",
	"%s surface signals destabilizing",
]
const INFECTION_COMPLETE_MESSAGES : Array = [
	"%s consumed by %s",
	"%s signal lost: %s confirmed",
	"%s biosphere rewritten by %s",
	"%s goes dark under %s",
]
const OUTBREAK_NAMES : Array = [
	"Crimson Bloom",
	"Helios Rot",
	"Red Choir",
	"Spore Surge",
	"Solar Fever",
	"Black Vein",
	"Cathedral Strain",
	"Burning Lattice",
]
const TAKEOVER_BANNER_DURATION : float = 2.15
const RANDOM_EVENT_MIN_INTERVAL : float = 15.0
const RANDOM_EVENT_MAX_INTERVAL : float = 28.0
const MEMORY_PULSE_INTERVAL : float = 4.25
const RANDOM_EVENT_MESSAGES : Array = [
	"Solar winds accelerate loose spores",
	"Human satellites detect impossible heat",
	"Radio prayers collapse into static",
	"Quarantine math no longer balances",
	"Deep space telescopes blink red",
	"Heliospheric pressure rising",
]

@export var stage_config : MapStageConfig
@export var clicker : InfectionClicker = null
var region_lookup : Dictionary = {}
var active_infections : Dictionary = {}
var infection_log_entries : Array[String] = []
var connection_pulse_strength : float = 0.0
var takeover_banner_text : String = ""
var takeover_banner_color : Color = Color("ff315b")
var takeover_banner_timer : float = 0.0
var random_event_timer : float = 0.0
var infected_memory_order : Array[String] = []
var memory_pulse_timer : float = MEMORY_PULSE_INTERVAL
var memory_pulse_index : int = 0

@onready var spread_timer : Timer = %SpreadTimer
@onready var auto_clicker_tendrils : AutoClickerTendrils = %AutoClickerTendrils
@onready var regions_root : Node2D = %RegionsRoot
@onready var effects_root : Node2D = %EffectsRoot


func initialize_stage() -> void:
	if stage_config == null:
		push_warning("MapStage is missing a stage_config resource.")
		return

	_clear_regions()
	active_infections.clear()
	infected_memory_order.clear()
	takeover_banner_timer = 0.0
	_reset_random_event_timer()
	memory_pulse_timer = MEMORY_PULSE_INTERVAL
	memory_pulse_index = 0
	auto_clicker_tendrils.position = Vector2.ZERO
	_create_regions()
	_refresh_neighbor_pressure()
	_initialize_infection_log()
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

			var has_infection_connection : bool = source_region.infected or target_region.infected or source_region.infecting or target_region.infecting
			if has_infection_connection:
				var color : Color = CONNECTION_COLOR
				var is_active_infection_connection : bool = source_region.infecting or target_region.infecting
				if is_active_infection_connection:
					var vein_pulse : float = sin(Time.get_ticks_msec() / 150.0) * 0.5 + 0.5
					color = color.lerp(Color("ff0033"), 0.42)
					color.a = clamp(color.a + vein_pulse * 0.28, 0.0, 0.95)
				color.a = clamp(color.a + (connection_pulse_strength * 0.45), 0.0, 0.95)
				var width : float = lerp(2.0, 4.5, connection_pulse_strength)
				if is_active_infection_connection:
					width = max(width, 2.6 + sin(Time.get_ticks_msec() / 150.0) * 1.4 + 1.4)
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
	_draw_infection_log(half_size)
	_draw_corruption_percent(half_size)
	_draw_takeover_banners(half_size)


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
	infection_log_entries.clear()
	for child : Node in regions_root.get_children():
		child.queue_free()


func _initialize_infection_log() -> void:
	infection_log_entries.clear()
	for region_config : MapRegionConfig in _get_region_configs():
		if region_config.starts_infected:
			if not infected_memory_order.has(region_config.region_name):
				infected_memory_order.append(region_config.region_name)
			_add_infection_log("%s: patient zero confirmed" % region_config.region_name.to_upper())


func _draw_infection_log(half_size : Vector2) -> void:
	if infection_log_entries.is_empty():
		return

	var start_position : Vector2 = Vector2(-half_size.x + 34.0, half_size.y - 132.0)
	draw_string(ThemeDB.fallback_font, start_position, "INFECTION LOG", HORIZONTAL_ALIGNMENT_LEFT, 280.0, 14, LOG_HEADER_COLOR)

	for index : int in range(infection_log_entries.size()):
		var entry_color : Color = LOG_COLOR
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
	var corruption_percent : float = _get_corruption_percent()
	var corruption_color : Color = Color("ff315b").lerp(Color("ffb0ba"), corruption_percent * 0.34)
	var label_text : String = "SYSTEM CONTAMINATION: %d%%" % int(round(corruption_percent * 100.0))
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

	var age : float = duration - timer
	var fade_in : float = clamp(age / 0.18, 0.0, 1.0)
	var fade_out : float = clamp(timer / 0.5, 0.0, 1.0)
	var alpha : float = min(fade_in, fade_out)
	var pulse : float = sin(Time.get_ticks_msec() / 95.0) * 0.5 + 0.5
	var banner_color : Color = color.lerp(Color("fff1b6"), pulse * 0.18)
	var shadow_color : Color = Color(0, 0, 0, 0.82)
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

	_add_infection_log(str(RANDOM_EVENT_MESSAGES[randi() % RANDOM_EVENT_MESSAGES.size()]))
	_reset_random_event_timer()
	return true


func _update_memory_pulses(delta : float) -> bool:
	if infected_memory_order.size() <= 1:
		return false

	memory_pulse_timer -= delta
	if memory_pulse_timer > 0.0:
		return false

	for _attempt : int in range(infected_memory_order.size()):
		var region_name : String = infected_memory_order[memory_pulse_index % infected_memory_order.size()]
		memory_pulse_index += 1
		var region : MapRegion = region_lookup.get(region_name)
		if region != null and region.infected:
			region.play_memory_pulse()
			break

	memory_pulse_timer = MEMORY_PULSE_INTERVAL
	return false


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
	_show_takeover_banner("INFECTING %s..." % region.region_name.to_upper(), Color("ff6b18"))
	_spawn_region_pulse(region, Color("ff6b18"), region.radius * 3.2, 0.5)
	_add_infection_log(_get_start_log_message(region.region_name))
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

		if _is_region_takeover_complete(region):
			completed_regions.append(region)
			continue

		var infected_neighbors : int = _count_infected_neighbors(region_config.neighbors)
		if infected_neighbors <= 0 or effective_cps < region_config.infection_cps_threshold:
			continue

		var progress_rate : float = _get_takeover_progress_rate(region_config, effective_cps, infected_neighbors)
		region.set_infection_progress(region.infection_progress + (progress_rate * delta))
		changed = true

		if _is_region_takeover_complete(region):
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


func _is_region_takeover_complete(region : MapRegion) -> bool:
	return region.infection_progress >= TAKEOVER_COMPLETE_PROGRESS


func _complete_region_infection(region : MapRegion) -> void:
	var outbreak_name : String = _get_outbreak_name()
	active_infections.erase(region.region_name)
	region.set_infected(true)
	if not infected_memory_order.has(region.region_name):
		infected_memory_order.append(region.region_name)
	region.play_infection_death_animation()
	_show_takeover_banner("%s CONSUMED" % region.region_name.to_upper(), Color("ff0033"))
	_spawn_region_pulse(region, Color("ff0033"), region.radius * 5.5, 0.72)
	_add_infection_log(_get_complete_log_message(region.region_name, outbreak_name))
	_add_outbreak_boost_for_region(region.region_name, outbreak_name)
	_refresh_neighbor_pressure()
	queue_redraw()

	if _all_regions_infected():
		spread_timer.stop()
		stage_cleared.emit()


func _add_outbreak_boost_for_region(region_name : String, outbreak_name : String) -> void:
	if clicker == null:
		return

	for region_config : MapRegionConfig in _get_region_configs():
		if region_config.region_name == region_name:
			clicker.add_outbreak_click_boost(region_config.outbreak_click_multiplier, region_config.outbreak_duration, outbreak_name)
			return


func _get_start_log_message(region_name : String) -> String:
	var message_format : String = str(INFECTION_START_MESSAGES[randi() % INFECTION_START_MESSAGES.size()])
	return message_format % region_name.to_upper()


func _get_complete_log_message(region_name : String, outbreak_name : String) -> String:
	var message_format : String = str(INFECTION_COMPLETE_MESSAGES[randi() % INFECTION_COMPLETE_MESSAGES.size()])
	return message_format % [region_name.to_upper(), outbreak_name]


func _get_outbreak_name() -> String:
	return str(OUTBREAK_NAMES[randi() % OUTBREAK_NAMES.size()])


func _show_takeover_banner(display_text : String, color : Color) -> void:
	takeover_banner_text = display_text
	takeover_banner_color = color
	takeover_banner_timer = TAKEOVER_BANNER_DURATION
	queue_redraw()


func _reset_random_event_timer() -> void:
	random_event_timer = randf_range(RANDOM_EVENT_MIN_INTERVAL, RANDOM_EVENT_MAX_INTERVAL)


func _get_corruption_percent() -> float:
	if region_lookup.is_empty():
		return 0.0

	var corruption_amount : float = 0.0
	for region : MapRegion in region_lookup.values():
		if region.infected:
			corruption_amount += 1.0
		elif region.infecting:
			corruption_amount += region.infection_progress

	return clamp(corruption_amount / float(region_lookup.size()), 0.0, 1.0)


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
