class_name RegionVisualProfile
extends Resource

enum ShapeMode {
	ORB,
	RINGED_ORB,
	CORE,
	CLUSTER,
	CLOUD,
	LANE,
	SPIRAL_GALAXY,
}

@export var profile_name : String = "Region"
@export_enum("Orb", "Ringed Orb", "Core", "Cluster", "Cloud", "Lane", "Spiral Galaxy") var shape_mode : int = ShapeMode.ORB
@export var texture : Texture2D = null

@export_group("Base Colors")
@export var base_color : Color = Color.WHITE
@export var border_color : Color = Color("d6d9e0")
@export var label_color : Color = Color("f1f3f8")
@export var hover_tint_strength : float = 0.1

@export_group("Infection Colors")
@export var infected_color : Color = Color("d94452")
@export var infecting_color : Color = Color("ff0033")
@export var vein_color : Color = Color("cf2f47")
@export var vein_alt_color : Color = Color("b43aa8")
@export var vein_core_color : Color = Color("6b0612")
@export var vein_alt_core_color : Color = Color("4c0b42")
@export var vein_highlight_color : Color = Color("ff6f83")
@export var distress_color : Color = Color("ff9aa5")

@export_group("Rings")
@export var inner_ring_color : Color = Color("cabf9d")
@export var outer_ring_color : Color = Color("8e7f62")

@export_group("Galaxy Shape")
@export_range(2, 6, 1) var galaxy_arm_count : int = 4
@export_range(1.0, 2.8, 0.05) var galaxy_arm_curve : float = 1.7
@export_range(0.55, 1.15, 0.01) var galaxy_disc_aspect : float = 1.0
@export_range(-180.0, 180.0, 0.5) var galaxy_rotation_degrees : float = 0.0
@export_range(0.0, 1.0, 0.01) var galaxy_bar_strength : float = 0.0
@export_range(0.0, 1.0, 0.01) var galaxy_ring_strength : float = 0.0
@export_range(6, 24, 1) var galaxy_star_count : int = 11
