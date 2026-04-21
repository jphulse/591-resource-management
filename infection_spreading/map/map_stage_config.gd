class_name MapStageConfig
extends Resource

@export var stage_title : String = "Stage"
@export var spread_interval : float = 1.0
@export var minimum_spread_chance : float = 0.03
@export var cps_over_threshold_spread_scale : float = 0.08
@export var maximum_spread_chance : float = 0.35
@export var show_orbits : bool = true
@export var regions : Array[MapRegionConfig] = []
