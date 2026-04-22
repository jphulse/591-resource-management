class_name ClickerFlavorConfig
extends Resource

@export_group("HUD Labels")
@export var total_label_format : String = "%.02f Viral Mass"
@export var score_per_second_format : String = "%.02f CPS"
@export var ecosystem_dormant_text : String = "Viral ecosystem dormant"
@export var ecosystem_active_format : String = "Ecosystem: spores +%d%% | hives -%d%% | taps +%d%%"
@export var outbreak_text_format : String = "OUTBREAK %s"
@export var outbreak_named_text_format : String = "%s: %s"

@export_group("Timing")
@export var upgrade_flavor_cooldown : float = 1.2
@export var idle_whisper_delay : float = 8.0
@export var idle_whisper_interval : float = 9.0

@export_group("CPS Milestones")
@export var cps_milestone_thresholds : Array[float] = [100.0, 400.0, 900.0, 2200.0, 5500.0]
@export var cps_milestone_messages : PackedStringArray = PackedStringArray([
	"THE INFECTION LEARNS",
	"SOLAR FEVER DETECTED",
	"THE SUN IS LISTENING",
	"ORBITAL CONTAINMENT FAILING",
	"THE SYSTEM IS RAVENOUS",
])

@export_group("Click Streaks")
@export var click_streak_thresholds : Array[float] = [60.0, 180.0, 450.0, 850.0]
@export var click_streak_messages : PackedStringArray = PackedStringArray([
	"FEVERISH",
	"UNSTABLE",
	"RAVENOUS",
	"SOLAR PARASITE",
])

@export_group("Idle Whispers")
@export var idle_whisper_messages : PackedStringArray = PackedStringArray([
	"it waits",
	"the spores breathe",
	"growth continues",
	"the sun remembers",
])

@export_group("CPS Colors")
@export var default_cps_color : Color = Color("f2f2f2")
@export var outbreak_cps_color : Color = Color("ff0033")
@export var cps_tier_thresholds : Array[float] = [100.0, 400.0, 900.0, 2200.0, 5500.0]
@export var cps_tier_colors : Array[Color] = [
	Color("ff8a72"),
	Color("ff4a2f"),
	Color("d70424"),
	Color("ff315b"),
	Color("ff1f4f"),
]

@export_group("Effect Colors")
@export var click_number_color : Color = Color("ffb35a")
@export var click_streak_color : Color = Color("ff315b")
@export var click_pulse_start_color : Color = Color("ff6b18")
@export var click_pulse_end_color : Color = Color("d70424")
@export var idle_whisper_color : Color = Color("ff9aa5")
@export var outbreak_text_color : Color = Color("ff0033")
@export var outbreak_label_hot_color : Color = Color("ff0033")
@export var outbreak_label_soft_color : Color = Color("ffb0ba")
@export var milestone_banner_color : Color = Color("ff315b")
@export var milestone_banner_fade_color : Color = Color(1.0, 0.12, 0.22, 0.0)
@export var mutation_flare_color : Color = Color("ff0033")
@export var ecosystem_active_color : Color = Color("ff9aa5", 0.82)
@export var ecosystem_dormant_color : Color = Color(1.0, 1.0, 1.0, 0.42)

@export_group("Upgrade Flavor")
@export var solar_tap_passive_name : String = "Solar Tap"
@export var spore_colony_passive_name : String = "Spore Colony"
@export var mutation_hive_passive_name : String = "Mutation Hive"
@export var default_upgrade_flavor_messages : PackedStringArray = PackedStringArray([
	"the infection adapts",
	"new tissue answers",
	"growth finds a path",
])
@export var solar_tap_flavor_messages : PackedStringArray = PackedStringArray([
	"solar tap widens",
	"sun plasma rerouted",
	"the star bleeds faster",
])
@export var spore_colony_flavor_messages : PackedStringArray = PackedStringArray([
	"spore colony blooms",
	"new tendrils answer",
	"red roots find orbit",
])
@export var mutation_hive_flavor_messages : PackedStringArray = PackedStringArray([
	"mutation hive awakens",
	"thicker nerves growing",
	"the hive thinks louder",
])
@export var default_upgrade_flavor_color : Color = Color("ffb35a")
@export var solar_tap_flavor_color : Color = Color("ffb35a")
@export var spore_colony_flavor_color : Color = Color("ff315b")
@export var mutation_hive_flavor_color : Color = Color("ff2ca8")


func get_upgrade_flavor_messages(passive_name : String) -> PackedStringArray:
	if passive_name == mutation_hive_passive_name:
		return mutation_hive_flavor_messages
	if passive_name == spore_colony_passive_name:
		return spore_colony_flavor_messages
	if passive_name == solar_tap_passive_name:
		return solar_tap_flavor_messages
	return default_upgrade_flavor_messages


func get_upgrade_flavor_color(passive_name : String) -> Color:
	if passive_name == mutation_hive_passive_name:
		return mutation_hive_flavor_color
	if passive_name == spore_colony_passive_name:
		return spore_colony_flavor_color
	if passive_name == solar_tap_passive_name:
		return solar_tap_flavor_color
	return default_upgrade_flavor_color
