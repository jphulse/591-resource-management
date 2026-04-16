class_name MapStage
extends Node2D

signal stage_cleared

const REGION_SCENE : PackedScene = preload("res://infection_spreading/map/map_region.tscn")
const BACKGROUND_COLOR : Color = Color("121212")
const ORBIT_COLOR : Color = Color("bcbcbc", 0.48)
const TITLE_COLOR : Color = Color("f5f5f5")
const CONNECTION_COLOR : Color = Color("d94452", 0.36)

@export var stage_config : MapStageConfig
var region_lookup : Dictionary = {}

@onready var spread_timer : Timer = %SpreadTimer
@onready var regions_root : Node2D = %RegionsRoot


func initialize_stage() -> void:
	if stage_config == null:
		push_warning("MapStage is missing a stage_config resource.")
		return

	_clear_regions()
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

			if source_region.infected or target_region.infected:
				draw_line(source_region.position, target_region.position, CONNECTION_COLOR, 2.0, true)

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
	for child : Node in regions_root.get_children():
		child.queue_free()


func _on_spread_timer_timeout() -> void:
	var newly_infected : Array[MapRegion] = []

	for region_config : MapRegionConfig in _get_region_configs():
		var region_name : String = region_config.region_name
		var region : MapRegion = region_lookup.get(region_name)
		if region == null or region.infected:
			continue

		var infected_neighbors : int = _count_infected_neighbors(region_config.neighbors)
		if infected_neighbors <= 0:
			continue

		var spread_chance : float = clamp(float(infected_neighbors) * stage_config.base_neighbor_spread_chance, 0.0, 0.9)
		if randf() <= spread_chance:
			newly_infected.append(region)

	for region : MapRegion in newly_infected:
		region.set_infected(true)

	if newly_infected.is_empty():
		return

	_refresh_neighbor_pressure()
	queue_redraw()

	if _all_regions_infected():
		spread_timer.stop()
		stage_cleared.emit()


func _refresh_neighbor_pressure() -> void:
	for region_config : MapRegionConfig in _get_region_configs():
		var region : MapRegion = region_lookup.get(region_config.region_name)
		if region == null:
			continue
		region.set_infected_neighbor_count(_count_infected_neighbors(region_config.neighbors))


func _count_infected_neighbors(neighbors : Array) -> int:
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


func _get_region_configs() -> Array[MapRegionConfig]:
	if stage_config == null:
		return []
	return stage_config.regions
