class_name InfectionClicker extends Panel

#region Exported vars
## Array of passives, mostly exported for testing
@export var passives : Array[PlaguePassive] = []

@export var clicker_passive : PlaguePassive 

@export var upgrades : ClickerUpgrades = null

@export var test_mode : bool = false
#endregion

#region Local fields
const MANUAL_CPS_WINDOW : float = 1.0
const VISUAL_CPS_FOR_MAX_INFECTION : float = 5500.0
const VISUAL_INFECTION_CURVE : float = 0.55
const VISUAL_RESPONSE_SPEED : float = 4.0
const INFECTION_SEED_THRESHOLD : float = 0.02
const MANUAL_INFECTION_CPS_WEIGHT : float = 1.5
const SUN_BUTTON_COLOR : Color = Color("ea6b10")
const SUN_EDGE_COLOR : Color = Color("7b1d03")
const SUN_STAR_COLOR : Color = Color("fff1b6")
const SUN_INFECTED_COLOR : Color = Color("e01426")
const SUN_INFECTED_SOFT_COLOR : Color = Color("f54254")
const SUN_INFECTED_HOT_COLOR : Color = Color("ff8790")
const SUN_INFECTED_SHADOW_COLOR : Color = Color("47030a")
const SUN_VEIN_COLOR : Color = Color("b51b2a")
const PULSE_SCENE = preload("res://infection_spreading/effects/viral_pulse.gd")
const FLOATING_TEXT_SCENE = preload("res://infection_spreading/effects/floating_text.gd")
const CLICK_TEXT_INTERVAL : float = 0.18
const CLICK_PULSE_INTERVAL : float = 0.05
const CLICK_STREAK_TEXT_INTERVAL : float = 2.2
const CPS_MILESTONE_THRESHOLDS : Array = [100.0, 400.0, 900.0, 2200.0, 5500.0]
const CPS_MILESTONE_MESSAGES : Array = [
	"THE INFECTION LEARNS",
	"SOLAR FEVER DETECTED",
	"THE SUN IS LISTENING",
	"ORBITAL CONTAINMENT FAILING",
	"THE SYSTEM IS RAVENOUS",
]
const UPGRADE_FLAVOR_COOLDOWN : float = 1.2
const IDLE_WHISPER_DELAY : float = 8.0
const IDLE_WHISPER_INTERVAL : float = 9.0
const SOLAR_TAP_FLAVOR_MESSAGES : Array = [
	"solar tap widens",
	"sun plasma rerouted",
	"the star bleeds faster",
]
const SPORE_COLONY_FLAVOR_MESSAGES : Array = [
	"spore colony blooms",
	"new tendrils answer",
	"red roots find orbit",
]
const MUTATION_HIVE_FLAVOR_MESSAGES : Array = [
	"mutation hive awakens",
	"thicker nerves growing",
	"the hive thinks louder",
]
const IDLE_WHISPER_MESSAGES : Array = [
	"it waits",
	"the spores breathe",
	"growth continues",
	"the sun remembers",
]

## The current toal score currently ina  float we may have to find a better way to represent this
var count : float = 0
## Whether or not the click area is active
var active : bool = false
## What the value added to count per click is
var click_value : float = 1.0

var init_click_value : float = 1.0
## The click value before any timed infection boosts are applied
var base_click_value : float = 1.0
## Format string for the total label
var total_label_format : String = "%.02f Viral Mass"
## Format string for the score per second label
var score_per_second_format : String = "%.02f CPS"
## Number of score gained in the previous second by clicking alone
var click_value_per_second : float = 0.0
## Number of score gained every second passively
var passive_clicks_per_second : float = 0.0
## Rolling history of recent clicks used to drive the infection visuals
var recent_click_times : Array[float] = []
var recent_click_amounts : Array[float] = []
## Smoothed shader parameters so the infection responds fluidly
var visual_infection_level : float = 0.0
var visual_pulse_strength : float = 0.0
## Tracks whether the infection is currently active so we can reroll its pattern
var infection_is_active : bool = false
## Random source used to reseed the shader pattern
var infection_rng : RandomNumberGenerator = RandomNumberGenerator.new()
## Timed click value boosts granted when infection spreads to a new region
var active_outbreak_boosts : Array[Dictionary] = []
## The last cps value that was animated in the hud
var last_displayed_cps : float = -1.0
## Used to keep click text readable at high cps
var click_text_cooldown : float = 0.0
## Used to keep click pulses readable at high cps
var click_pulse_cooldown : float = 0.0
## Used to keep click streak flavor from shouting every frame
var click_streak_text_cooldown : float = 0.0
## Running pulse value used to make outbreak hud feel alive
var hud_pulse_time : float = 0.0
## Last auto clicker count pushed to the visual tendril layer
var last_auto_clicker_tendril_key : String = ""
## Highest cps milestone banner already shown
var highest_cps_milestone_index : int = -1
## Draws auto clicker tendrils reaching away from the sun
var auto_clicker_tendrils : AutoClickerTendrils = null
## Keeps upgrade flavor blurbs readable while buying quickly
var upgrade_flavor_cooldown : float = 0.0
## Keeps idle whispers occasional, not chatty
var idle_whisper_cooldown : float = 0.0
## Last time the player manually clicked the sun
var last_click_time : float = 0.0

## Packed scene for the button scene
var upgrade_button_scene : PackedScene = preload("uid://dqt48i3odii7u")

#endregion

#region onready vars
## The total label is used to show the player they're current score
@onready var total_label : Label = %TotalLabel
## The score per second label displays the score per second including clicks over the past second
@onready var score_per_second : Label = %ScorePerSecond
## Visual target for the infection shader
@onready var infection_button : ColorRect = %InfectionButton
## Collision area used for clicking the button
@onready var clicker_area : Area2D = %ClickerArea
@onready var clicker_shape : CollisionShape2D = $ClickerArea/CollisionShape2D
## Container for the upgrade buttons for the clicker game
@onready var upgrade_container : VBoxContainer = %UpgradeContainer
## Holds short lived clicker effects so they render above the sun
@onready var effects_root : Node2D = %EffectsRoot
## Shows the current timed outbreak click multiplier
@onready var outbreak_multiplier_label : Label = %OutbreakMultiplierLabel
## Big temporary text for cps threshold moments
@onready var milestone_banner_label : Label = %MilestoneBannerLabel
## Debug toggle used to make all upgrades cheap while testing pacing
@onready var test_mode_toggle : CheckButton = %TestModeToggle
#endregion

#region Mouse interactions
## Activate when the mouse enters an area
func _on_clicker_area_mouse_entered() -> void:
	active = true
## Deactivate when the mouse leaves the area
func _on_clicker_area_mouse_exited() -> void:
	active = false
## If active and a mouse button is pressed give click, currently allows butterfly clicking (intentional)
## If we were doing a more traditional game we would use _unhandled_input but because this area lives in
## a ui scene and we want it to grab the mouse event we use _input
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and active and event.is_pressed():
		_register_click(click_value)
#endregion

#region Score label updating
## Updates the score label to match the total count, done whenever count changes
func update_score_label() -> void:
	total_label.text = total_label_format % count
	if upgrades and upgrades.is_node_ready():
		upgrades.balance_label.text = total_label.text

## Updates the score per second label done once a second or when passive_clicks_per_second changes
func update_score_per_second_label() -> void:
	var current_cps : float = click_value_per_second + passive_clicks_per_second
	score_per_second.text = score_per_second_format % current_cps
	_update_cps_label_style()
	if not is_equal_approx(current_cps, last_displayed_cps):
		_animate_cps_label(false)
	last_displayed_cps = current_cps
#endregion

#region Timer callbacks
## This is just hooked up to a timer that goes off every second and updates the cps label
func _on_second_timer_timeout() -> void:
	update_score_per_second_label()
	click_value_per_second = 0
#endregion

#region Helper methods

func _upgrade_click(item : PlaguePassive) -> void:
	print("UPGRADE", item.passive_benefit, " ",item.count, " ",item.upgrade_mult)
	base_click_value = item.get_passive_amount() + init_click_value
	_update_click_value()
	
func _on_upgrade_pressed(button : ClickerPassiveButton, passive : PlaguePassive) -> void:
	var current_cost : float = get_passive_cost(passive)
	if count >= current_cost:
		count -= current_cost
		passive.buy_another()
		_spawn_upgrade_flavor(passive)
		button.cost = get_passive_cost(passive)
		button.count = passive.count
		if passive != clicker_passive:
			_update_passive_clicks()
			_update_auto_clicker_tendrils()
		else:
			_upgrade_click(passive)
func tree_upgrade_pressed( passive : PlaguePassive) -> bool:
	var current_cost : float = get_upgrade_cost(passive)
	if count >= current_cost:
		count -= current_cost
		passive.upgrade()
		_spawn_upgrade_flavor(passive)
		if passive != clicker_passive:
			_update_passive_clicks()
		else:
			init_click_value *= passive.upgrade_mult
			_upgrade_click(passive)
			
		return true
	return false

func _add_button(item: PlaguePassive) -> void:
	var button : ClickerPassiveButton = upgrade_button_scene.instantiate() as ClickerPassiveButton
	button.setup(item)
	button.cost = get_passive_cost(item)
	upgrade_container.add_child(button)
	
	button.pressed.connect(_on_upgrade_pressed.bind(button, item))
	
func _initialize_buttons() -> void:
	if upgrades:
		clicker_passive.bought_first.connect(upgrades._on_passive_bought)
	_add_button(clicker_passive)
	for i : PlaguePassive in passives:
		if upgrades:
			i.bought_first.connect(upgrades._on_passive_bought)
		_add_button(i)

func _sync_test_mode_toggle() -> void:
	test_mode_toggle.button_pressed = test_mode
	test_mode_toggle.toggled.connect(_on_test_mode_toggled)
	_style_test_mode_toggle()
	_refresh_upgrade_costs()

func _on_test_mode_toggled(enabled : bool) -> void:
	test_mode = enabled
	_style_test_mode_toggle()
	_refresh_upgrade_costs()

func _style_test_mode_toggle() -> void:
	if test_mode:
		test_mode_toggle.modulate = Color("ff5a6e")
	else:
		test_mode_toggle.modulate = Color(1.0, 1.0, 1.0, 0.72)

func _refresh_upgrade_costs() -> void:
	for child in upgrade_container.get_children():
		if child is ClickerPassiveButton and child.passive != null:
			child.cost = get_passive_cost(child.passive)

	if upgrades and upgrades.is_node_ready():
		upgrades.refresh_upgrade_cost_labels()
		

## Keeps the click area centered on top of the button visual
func _sync_clicker_area() -> void:
	var viewport_center : Vector2 = get_viewport_rect().size * 0.5
	infection_button.global_position = viewport_center - (infection_button.size * 0.5)
	clicker_area.position = infection_button.position + (infection_button.size * 0.5)
	outbreak_multiplier_label.global_position = _get_sun_center() + Vector2(-54.0, 64.0)
	outbreak_multiplier_label.pivot_offset = outbreak_multiplier_label.size * 0.5
	var circle_shape : CircleShape2D = clicker_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = min(infection_button.size.x, infection_button.size.y) * 0.31

## Records a click for scorekeeping and the rolling infection visual state
func _register_click(amount : float) -> void:
	var now : float = Time.get_ticks_msec() / 1000.0
	last_click_time = now
	idle_whisper_cooldown = 0.0
	count += amount
	click_value_per_second += amount
	recent_click_times.append(now)
	recent_click_amounts.append(amount)
	update_score_label()
	_spawn_click_feedback(amount)


## Adds small mutation blurbs after some purchases
func _spawn_upgrade_flavor(passive : PlaguePassive) -> void:
	if upgrade_flavor_cooldown > 0.0:
		return

	if randf() > 0.62:
		return

	var flavor_text : String = _get_upgrade_flavor_text(passive)
	if flavor_text.is_empty():
		return

	_spawn_floating_text(flavor_text, _get_upgrade_flavor_color(passive), _get_sun_center() + _get_upgrade_flavor_offset(), Vector2(0.0, -46.0), 1.0)
	upgrade_flavor_cooldown = UPGRADE_FLAVOR_COOLDOWN


func _get_upgrade_flavor_text(passive : PlaguePassive) -> String:
	var flavor_messages : Array = SOLAR_TAP_FLAVOR_MESSAGES
	if passive.name == "Mutation Hive":
		flavor_messages = MUTATION_HIVE_FLAVOR_MESSAGES
	elif passive.name == "Spore Colony":
		flavor_messages = SPORE_COLONY_FLAVOR_MESSAGES

	return str(flavor_messages[randi() % flavor_messages.size()])


func _get_upgrade_flavor_color(passive : PlaguePassive) -> Color:
	if passive.name == "Mutation Hive":
		return Color("ff2ca8")
	if passive.name == "Spore Colony":
		return Color("ff315b")
	return Color("ffb35a")


func _get_upgrade_flavor_offset() -> Vector2:
	return Vector2(randf_range(-92.0, 42.0), randf_range(70.0, 104.0))

## Removes clicks that have fallen out of the rolling cps window
func _prune_click_history(now : float) -> void:
	while recent_click_times.size() > 0 and now - recent_click_times[0] > MANUAL_CPS_WINDOW:
		recent_click_times.pop_front()
		recent_click_amounts.pop_front()

## Returns the current manual cps over the rolling window
func _get_recent_manual_cps(now : float) -> float:
	_prune_click_history(now)
	var manual_cps : float = 0.0
	for amount : float in recent_click_amounts:
		manual_cps += amount
	return manual_cps

## Updates the actual click value after timed outbreak boosts
func _update_click_value() -> void:
	click_value = base_click_value * _get_outbreak_click_multiplier()

## Returns the current combined click boost multiplier from active outbreaks
func _get_outbreak_click_multiplier() -> float:
	var multiplier : float = 1.0
	for boost : Dictionary in active_outbreak_boosts:
		multiplier += max(float(boost.get("multiplier", 1.0)) - 1.0, 0.0)
	return multiplier

## Removes expired infection boosts and keeps click value synced
func _update_outbreak_boosts(delta : float) -> void:
	if active_outbreak_boosts.is_empty():
		return

	var boost_changed : bool = false
	for index : int in range(active_outbreak_boosts.size() - 1, -1, -1):
		active_outbreak_boosts[index]["time_left"] = float(active_outbreak_boosts[index]["time_left"]) - delta
		if float(active_outbreak_boosts[index]["time_left"]) <= 0.0:
			active_outbreak_boosts.remove_at(index)
			boost_changed = true

	if boost_changed:
		_update_click_value()
	_update_outbreak_multiplier_label()

## Updates the persistent outbreak multiplier display
func _update_outbreak_multiplier_label() -> void:
	var multiplier : float = _get_outbreak_click_multiplier()
	outbreak_multiplier_label.visible = multiplier > 1.0
	if not outbreak_multiplier_label.visible:
		return

	var pulse : float = sin(hud_pulse_time * 10.0) * 0.5 + 0.5
	outbreak_multiplier_label.text = _get_multiplier_text(multiplier)
	outbreak_multiplier_label.modulate = Color("ff0033").lerp(Color("ffb0ba"), pulse * 0.45)
	outbreak_multiplier_label.scale = Vector2.ONE * (1.0 + pulse * 0.18)

## Counts bought passive auto clickers by type for visual tendrils
func _get_auto_clicker_tendril_counts() -> Dictionary:
	var ret_val : Dictionary = {
		"spores": 0,
		"hives": 0,
	}
	for passive : PlaguePassive in passives:
		if passive.name == "Mutation Hive":
			ret_val["hives"] += passive.count
		else:
			ret_val["spores"] += passive.count
	return ret_val

## Keeps the sun tendril layer synced to bought auto clickers
func _update_auto_clicker_tendrils() -> void:
	if auto_clicker_tendrils == null:
		return

	var counts : Dictionary = _get_auto_clicker_tendril_counts()
	var auto_clicker_key : String = "%s:%s" % [counts["spores"], counts["hives"]]
	if auto_clicker_key == last_auto_clicker_tendril_key:
		return

	last_auto_clicker_tendril_key = auto_clicker_key
	auto_clicker_tendrils.set_tendril_counts(int(counts["spores"]), int(counts["hives"]))

## Gives the persistent outbreak multiplier label a more arcade infected style
func _style_outbreak_multiplier_label() -> void:
	outbreak_multiplier_label.add_theme_font_size_override("font_size", 30)
	outbreak_multiplier_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	outbreak_multiplier_label.add_theme_constant_override("shadow_offset_x", 3)
	outbreak_multiplier_label.add_theme_constant_override("shadow_offset_y", 3)
	outbreak_multiplier_label.pivot_offset = outbreak_multiplier_label.size * 0.5

## Formats multiplier text without noisy decimals when possible
func _get_multiplier_text(multiplier : float) -> String:
	if is_equal_approx(multiplier, round(multiplier)):
		return "x%d" % int(round(multiplier))
	return "x%.1f" % multiplier

## Adds a pulse and occasional floating text when the sun is clicked
func _spawn_click_feedback(amount : float) -> void:
	var now : float = Time.get_ticks_msec() / 1000.0
	var manual_cps : float = _get_recent_manual_cps(now)

	if click_pulse_cooldown <= 0.0:
		var pulse : ViralPulse = PULSE_SCENE.new() as ViralPulse
		effects_root.add_child(pulse)
		pulse.global_position = infection_button.global_position + (infection_button.size * 0.5)
		var pulse_radius : float = lerp(58.0, 118.0, clamp(manual_cps / 600.0, 0.0, 1.0))
		var pulse_color : Color = Color("ff6b18").lerp(Color("d70424"), clamp(manual_cps / 600.0, 0.0, 1.0))
		pulse.setup(pulse_color, pulse_radius, 0.42, 4.0)
		click_pulse_cooldown = CLICK_PULSE_INTERVAL

	if click_text_cooldown <= 0.0:
		_spawn_floating_text("+%.0f" % amount, Color("ffb35a"), _get_sun_center() + _get_click_text_offset(), Vector2(0.0, -42.0), 0.65)
		click_text_cooldown = CLICK_TEXT_INTERVAL

	_spawn_click_streak_text(manual_cps)


## Adds a little Cookie Clicker style title when the player is hammering the sun
func _spawn_click_streak_text(manual_cps : float) -> void:
	if click_streak_text_cooldown > 0.0:
		return

	var streak_text : String = _get_click_streak_text(manual_cps)
	if streak_text.is_empty():
		return

	_spawn_floating_text(streak_text, Color("ff315b"), _get_sun_center() + Vector2(-74.0, -102.0), Vector2(0.0, -36.0), 0.9)
	click_streak_text_cooldown = CLICK_STREAK_TEXT_INTERVAL


func _get_click_streak_text(manual_cps : float) -> String:
	if manual_cps >= 850.0:
		return "SOLAR PARASITE"
	if manual_cps >= 450.0:
		return "RAVENOUS"
	if manual_cps >= 180.0:
		return "UNSTABLE"
	if manual_cps >= 60.0:
		return "FEVERISH"
	return ""


## Returns the visual center of the sun button
func _get_sun_center() -> Vector2:
	return infection_button.global_position + (infection_button.size * 0.5)


## Keeps floating click numbers from stacking exactly on top of each other
func _get_click_text_offset() -> Vector2:
	return Vector2(randf_range(-34.0, 34.0), randf_range(-18.0, 14.0))


## Spawns temporary text above the clicker layer
func _spawn_floating_text(display_text : String, color : Color, pos : Vector2, drift : Vector2, duration : float) -> void:
	var floating_text : FloatingText = FLOATING_TEXT_SCENE.new() as FloatingText
	floating_text.position = effects_root.to_local(pos)
	floating_text.setup(display_text, color, drift, duration)
	effects_root.add_child(floating_text)


## Animates the cps label like an infected Cookie Clicker counter
func _animate_cps_label(is_outbreak : bool) -> void:
	if not is_node_ready():
		return

	score_per_second.pivot_offset = score_per_second.size * 0.5
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	var target_scale : Vector2 = Vector2.ONE * (1.45 if is_outbreak else 1.18)
	var target_rotation : float = deg_to_rad(randf_range(-5.5, 5.5))
	tween.tween_property(score_per_second, "scale", target_scale, 0.12)
	tween.parallel().tween_property(score_per_second, "rotation", target_rotation, 0.12)
	tween.tween_property(score_per_second, "scale", Vector2.ONE, 0.22)
	tween.parallel().tween_property(score_per_second, "rotation", 0.0, 0.22)


## Keeps the cps label color tied to infection power tiers
func _update_cps_label_style() -> void:
	var effective_cps : float = get_effective_infection_cps()
	var tier_color : Color = Color("f2f2f2")

	if effective_cps >= 5500.0:
		tier_color = Color("ff1f4f")
	elif effective_cps >= 2200.0:
		tier_color = Color("ff315b")
	elif effective_cps >= 900.0:
		tier_color = Color("d70424")
	elif effective_cps >= 400.0:
		tier_color = Color("ff4a2f")
	elif effective_cps >= 100.0:
		tier_color = Color("ff8a72")

	if not active_outbreak_boosts.is_empty():
		var pulse : float = sin(hud_pulse_time * 10.0) * 0.5 + 0.5
		tier_color = tier_color.lerp(Color("ff0033"), 0.35 + (pulse * 0.35))

	score_per_second.modulate = tier_color


## Checks for cps milestone moments and shows one big banner per threshold
func _update_cps_milestone_banner() -> void:
	var effective_cps : float = get_effective_infection_cps()
	var milestone_index : int = _get_cps_milestone_index(effective_cps)
	if milestone_index <= highest_cps_milestone_index:
		return

	highest_cps_milestone_index = milestone_index
	_show_milestone_banner(str(CPS_MILESTONE_MESSAGES[milestone_index]))


func _get_cps_milestone_index(effective_cps : float) -> int:
	var ret_val : int = -1
	for index : int in range(CPS_MILESTONE_THRESHOLDS.size()):
		if effective_cps >= float(CPS_MILESTONE_THRESHOLDS[index]):
			ret_val = index
	return ret_val


func _show_milestone_banner(display_text : String) -> void:
	milestone_banner_label.visible = true
	milestone_banner_label.text = display_text
	milestone_banner_label.pivot_offset = milestone_banner_label.size * 0.5
	milestone_banner_label.scale = Vector2.ONE * 0.84
	milestone_banner_label.modulate = Color("ff315b")
	_spawn_mutation_flare()

	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(milestone_banner_label, "scale", Vector2.ONE * 1.12, 0.18)
	tween.tween_property(milestone_banner_label, "scale", Vector2.ONE, 0.26)
	tween.tween_interval(1.05)
	tween.tween_property(milestone_banner_label, "modulate", Color(1.0, 0.12, 0.22, 0.0), 0.5)


## Gives the big milestone banner a heavy infected arcade style
func _style_milestone_banner_label() -> void:
	milestone_banner_label.add_theme_font_size_override("font_size", 34)
	milestone_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	milestone_banner_label.add_theme_constant_override("shadow_offset_x", 4)
	milestone_banner_label.add_theme_constant_override("shadow_offset_y", 4)
	milestone_banner_label.modulate = Color(1.0, 0.12, 0.22, 0.0)


## Gives cps milestones a bigger rare mutation flare around the sun
func _spawn_mutation_flare() -> void:
	if not is_node_ready():
		return

	var pulse : ViralPulse = PULSE_SCENE.new() as ViralPulse
	effects_root.add_child(pulse)
	pulse.global_position = _get_sun_center()
	pulse.setup(Color("ff0033"), 190.0, 0.72, 8.0)
	visual_pulse_strength = 1.0

	var material_var : ShaderMaterial = infection_button.material as ShaderMaterial
	if material_var != null:
		_randomize_infection_seed(material_var)


## Adds subtle idle flavor when the player lets the infection breathe
func _update_idle_whispers(delta : float) -> void:
	var now : float = Time.get_ticks_msec() / 1000.0
	if now - last_click_time < IDLE_WHISPER_DELAY:
		return

	idle_whisper_cooldown -= delta
	if idle_whisper_cooldown > 0.0:
		return

	var whisper_text : String = str(IDLE_WHISPER_MESSAGES[randi() % IDLE_WHISPER_MESSAGES.size()])
	_spawn_floating_text(whisper_text, Color("ff9aa5"), _get_sun_center() + Vector2(randf_range(-84.0, 50.0), -92.0), Vector2(0.0, -28.0), 1.4)
	idle_whisper_cooldown = IDLE_WHISPER_INTERVAL

## Drives the button shader based on recent clicking and passive spread
func _update_infection_visuals(delta : float) -> void:
	var material_var : ShaderMaterial = infection_button.material as ShaderMaterial
	if material_var == null:
		return

	var now : float = Time.get_ticks_msec() / 1000.0
	var recent_manual_cps : float = _get_recent_manual_cps(now)
	var total_visual_cps : float = get_effective_infection_cps()
	var target_infection_level : float = pow(clamp(total_visual_cps / VISUAL_CPS_FOR_MAX_INFECTION, 0.0, 1.0), VISUAL_INFECTION_CURVE)
	var target_pulse_strength : float = clamp(recent_manual_cps / 600.0, 0.0, 1.0)
	var should_activate_infection : bool = target_infection_level > INFECTION_SEED_THRESHOLD

	if should_activate_infection and not infection_is_active:
		_randomize_infection_seed(material_var)

	infection_is_active = should_activate_infection

	visual_infection_level = move_toward(visual_infection_level, target_infection_level, VISUAL_RESPONSE_SPEED * delta)
	visual_pulse_strength = move_toward(visual_pulse_strength, target_pulse_strength, (VISUAL_RESPONSE_SPEED + 1.5) * delta)

	material_var.set_shader_parameter("infection_level", visual_infection_level)
	material_var.set_shader_parameter("pulse_strength", visual_pulse_strength)

## Gives the shader a fresh seed so tentacles can originate from different regions each activation
func _randomize_infection_seed(material_param : ShaderMaterial) -> void:
	material_param.set_shader_parameter(
		"tentacle_seed",
		Vector2(
			infection_rng.randf_range(-1000.0, 1000.0),
			infection_rng.randf_range(-1000.0, 1000.0)
		)
	)

## Tunes the center shader so the clickable button visually reads as the system's sun
func _style_button_as_sun(material_var : ShaderMaterial) -> void:
	material_var.set_shader_parameter("button_color", SUN_BUTTON_COLOR)
	material_var.set_shader_parameter("button_edge_color", SUN_EDGE_COLOR)
	material_var.set_shader_parameter("star_color", SUN_STAR_COLOR)
	material_var.set_shader_parameter("infected_color", SUN_INFECTED_COLOR)
	material_var.set_shader_parameter("infected_soft_color", SUN_INFECTED_SOFT_COLOR)
	material_var.set_shader_parameter("infected_hot_color", SUN_INFECTED_HOT_COLOR)
	material_var.set_shader_parameter("infected_shadow_color", SUN_INFECTED_SHADOW_COLOR)
	material_var.set_shader_parameter("vein_color", SUN_VEIN_COLOR)

## Updates the passive clicks as needed
func _update_passive_clicks() -> void:
	passive_clicks_per_second = 0.0
	for passive : PlaguePassive in passives:
		passive_clicks_per_second += passive.get_passive_amount()
## Gets the total frame contribution for the passive
func _get_passive_frame_contribution(delta : float) -> float:
	var ret_val : float = 0
	for passive : PlaguePassive in passives:
		ret_val += passive.get_process_amount(delta)
	return ret_val
#endregion

#region public methods
## Lets the map own the tendril layer so it can render behind planets
func set_auto_clicker_tendrils(tendril_layer : AutoClickerTendrils) -> void:
	auto_clicker_tendrils = tendril_layer
	last_auto_clicker_tendril_key = ""
	if is_node_ready():
		_update_auto_clicker_tendrils()

func get_passive_cost(passive : PlaguePassive) -> float:
	if test_mode:
		return 1.0
	return passive.cost

func get_upgrade_cost(passive : PlaguePassive) -> float:
	if test_mode:
		return 1.0
	return passive.upgrade_cost

func add_new_passive(passive : PlaguePassive) -> void:
	if not passives.has(passive):
		passives.append(passive)

## Gets manual cps over the recent rolling click window
func get_manual_cps() -> float:
	var now : float = Time.get_ticks_msec() / 1000.0
	return _get_recent_manual_cps(now)

## Gets passive cps from bought passive items
func get_passive_cps() -> float:
	return passive_clicks_per_second

## Gets total cps without extra infection weighting
func get_total_cps() -> float:
	return get_manual_cps() + get_passive_cps()

## Gets the cps value used by infection spreading
func get_effective_infection_cps() -> float:
	return get_passive_cps() + (get_manual_cps() * MANUAL_INFECTION_CPS_WEIGHT)

## Adds a temporary click value boost when a new region becomes infected
func add_outbreak_click_boost(multiplier : float, duration : float, outbreak_name : String = "") -> void:
	active_outbreak_boosts.append({
		"multiplier": multiplier,
		"time_left": duration,
	})
	_update_click_value()
	_update_outbreak_multiplier_label()
	_animate_cps_label(true)
	var outbreak_text : String = "OUTBREAK %s" % _get_multiplier_text(multiplier)
	if not outbreak_name.is_empty():
		outbreak_text = "%s: %s" % [outbreak_text, outbreak_name]
	_spawn_floating_text(outbreak_text, Color("ff0033"), _get_sun_center() + Vector2(-92.0, -76.0), Vector2(0.0, -64.0), 1.15)
#endregion

#region Processing
func _ready() -> void:
	init_click_value = click_value
	base_click_value = click_value
	last_click_time = Time.get_ticks_msec() / 1000.0
	idle_whisper_cooldown = 0.0
	_initialize_buttons()
	_sync_test_mode_toggle()
	_update_passive_clicks()
	_update_auto_clicker_tendrils()
	_style_outbreak_multiplier_label()
	_style_milestone_banner_label()
	update_score_label()
	update_score_per_second_label()
	infection_rng.randomize()
	infection_button.material = infection_button.material.duplicate()
	_style_button_as_sun(infection_button.material as ShaderMaterial)
	_randomize_infection_seed(infection_button.material as ShaderMaterial)
	_sync_clicker_area()
	_update_infection_visuals(0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_sync_clicker_area()

func _process(delta: float) -> void:
	hud_pulse_time += delta
	click_text_cooldown = max(click_text_cooldown - delta, 0.0)
	click_pulse_cooldown = max(click_pulse_cooldown - delta, 0.0)
	click_streak_text_cooldown = max(click_streak_text_cooldown - delta, 0.0)
	upgrade_flavor_cooldown = max(upgrade_flavor_cooldown - delta, 0.0)
	_update_outbreak_boosts(delta)
	count += _get_passive_frame_contribution(delta)
	update_score_label()
	_update_cps_label_style()
	_update_cps_milestone_banner()
	_update_outbreak_multiplier_label()
	_update_auto_clicker_tendrils()
	_update_idle_whispers(delta)
	_update_infection_visuals(delta)
	
#endregion
