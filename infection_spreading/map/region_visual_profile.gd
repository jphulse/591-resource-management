class_name RegionVisualProfile
extends Resource

enum ShapeMode {
	ORB,
	RINGED_ORB,
	CORE,
	CLUSTER,
	CLOUD,
	LANE,
}

@export var profile_name : String = "Region"
@export_enum("Orb", "Ringed Orb", "Core", "Cluster", "Cloud", "Lane") var shape_mode : int = ShapeMode.ORB
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
