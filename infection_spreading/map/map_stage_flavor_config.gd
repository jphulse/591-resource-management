class_name MapStageFlavorConfig
extends Resource

@export_group("Map Colors")
@export var background_color : Color = Color("121212")
@export var orbit_color : Color = Color("bcbcbc", 0.48)
@export var title_color : Color = Color("f5f5f5")
@export var connection_color : Color = Color("d94452", 0.36)
@export var active_connection_color : Color = Color("ff0033")

@export_group("Log Colors")
@export var log_color : Color = Color("ff9aa5", 0.78)
@export var log_header_color : Color = Color("ff315b", 0.9)
@export var corruption_start_color : Color = Color("ff315b")
@export var corruption_end_color : Color = Color("ffb0ba")

@export_group("Event Colors")
@export var infection_start_color : Color = Color("ff6b18")
@export var infection_complete_color : Color = Color("ff0033")
@export var banner_highlight_color : Color = Color("fff1b6")
@export var banner_shadow_color : Color = Color(0.0, 0.0, 0.0, 0.82)

@export_group("Labels")
@export var infection_log_title : String = "INFECTION LOG"
@export var corruption_label_format : String = "SYSTEM CONTAMINATION: %d%%"
@export var patient_zero_log_format : String = "%s: patient zero confirmed"
@export var infecting_banner_format : String = "INFECTING %s..."
@export var consumed_banner_format : String = "%s CONSUMED"

@export_group("Flavor Text")
@export var infection_start_messages : PackedStringArray = PackedStringArray([
	"%s containment failure detected",
	"%s local quarantine breached",
	"%s transmission bloom beginning",
	"%s surface signals destabilizing",
	"%s reports hostile growth",
])
@export var infection_complete_messages : PackedStringArray = PackedStringArray([
	"%s consumed by %s",
	"%s signal lost: %s confirmed",
	"%s biosphere rewritten by %s",
	"%s goes dark under %s",
])
@export var outbreak_names : PackedStringArray = PackedStringArray([
	"Crimson Bloom",
	"Red Choir",
	"Spore Surge",
	"Black Vein",
	"Cathedral Strain",
	"Burning Lattice",
	"Ravenous Bloom",
	"Viral Chorus",
])
@export var random_event_messages : PackedStringArray = PackedStringArray([
	"Transmission pressure rising",
	"Distant sensors blink red",
	"Radio prayers collapse into static",
	"Quarantine math no longer balances",
	"The infection changes shape",
	"Spore density increasing",
])
