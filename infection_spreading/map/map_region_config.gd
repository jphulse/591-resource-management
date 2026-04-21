class_name MapRegionConfig
extends Resource

@export var region_name : String = ""
@export var orbit : float = 0.0
@export var angle : float = 0.0
@export var position : Vector2 = Vector2.ZERO
@export var use_explicit_position : bool = false
@export var radius : float = 18.0
@export var color : Color = Color.WHITE
@export var neighbors : PackedStringArray = PackedStringArray()
@export var visual_type : String = "planet"
@export var starts_infected : bool = false
@export var infection_cps_threshold : float = 100.0
@export var takeover_duration : float = 24.0
@export var outbreak_click_multiplier : float = 2.0
@export var outbreak_duration : float = 10.0
