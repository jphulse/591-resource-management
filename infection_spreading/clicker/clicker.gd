extends Panel

#region Exported vars
## Array of passives, mostly exported for testing
@export var passives : Array[PlaguePassive] = []
#endregion

#region Local fields
const MANUAL_CPS_WINDOW : float = 1.0
const VISUAL_CPS_FOR_MAX_INFECTION : float = 10.0
const VISUAL_RESPONSE_SPEED : float = 4.0
const INFECTION_SEED_THRESHOLD : float = 0.02

## The current toal score currently ina  float we may have to find a better way to represent this
var count : float = 0
## Whether or not the click area is active
var active : bool = false
## What the value added to count per click is
var click_value : float = 1.0
## Format string for the total label
var total_label_format : String = "%.02f"
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

## Updates the score per second label done once a second or when passive_clicks_per_second changes
func update_score_per_second_label() -> void:
	score_per_second.text = score_per_second_format % (click_value_per_second + passive_clicks_per_second)
#endregion

#region Timer callbacks
## This is just hooked up to a timer that goes off every second and updates the cps label
func _on_second_timer_timeout() -> void:
	update_score_per_second_label()
	click_value_per_second = 0
#endregion

#region Helper methods
## Keeps the click area centered on top of the button visual
func _sync_clicker_area() -> void:
	clicker_area.position = infection_button.position + (infection_button.size * 0.5)

## Records a click for scorekeeping and the rolling infection visual state
func _register_click(amount : float) -> void:
	var now : float = Time.get_ticks_msec() / 1000.0
	count += amount
	click_value_per_second += amount
	recent_click_times.append(now)
	recent_click_amounts.append(amount)
	update_score_label()

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

## Drives the button shader based on recent clicking and passive spread
func _update_infection_visuals(delta : float) -> void:
	var material : ShaderMaterial = infection_button.material as ShaderMaterial
	if material == null:
		return

	var now : float = Time.get_ticks_msec() / 1000.0
	var recent_manual_cps : float = _get_recent_manual_cps(now)
	var total_visual_cps : float = recent_manual_cps + (passive_clicks_per_second * 0.4)
	var target_infection_level : float = clamp(total_visual_cps / VISUAL_CPS_FOR_MAX_INFECTION, 0.0, 1.0)
	var target_pulse_strength : float = clamp(recent_manual_cps / (VISUAL_CPS_FOR_MAX_INFECTION * 0.65), 0.0, 1.0)
	var should_activate_infection : bool = target_infection_level > INFECTION_SEED_THRESHOLD

	if should_activate_infection and not infection_is_active:
		_randomize_infection_seed(material)

	infection_is_active = should_activate_infection

	visual_infection_level = move_toward(visual_infection_level, target_infection_level, VISUAL_RESPONSE_SPEED * delta)
	visual_pulse_strength = move_toward(visual_pulse_strength, target_pulse_strength, (VISUAL_RESPONSE_SPEED + 1.5) * delta)

	material.set_shader_parameter("infection_level", visual_infection_level)
	material.set_shader_parameter("pulse_strength", visual_pulse_strength)

## Gives the shader a fresh seed so tentacles can originate from different regions each activation
func _randomize_infection_seed(material : ShaderMaterial) -> void:
	material.set_shader_parameter(
		"tentacle_seed",
		Vector2(
			infection_rng.randf_range(-1000.0, 1000.0),
			infection_rng.randf_range(-1000.0, 1000.0)
		)
	)

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

#region Processing
func _ready() -> void:
	_update_passive_clicks()
	update_score_label()
	update_score_per_second_label()
	infection_rng.randomize()
	infection_button.material = infection_button.material.duplicate()
	_randomize_infection_seed(infection_button.material as ShaderMaterial)
	_sync_clicker_area()
	_update_infection_visuals(0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_sync_clicker_area()

func _process(delta: float) -> void:
	count += _get_passive_frame_contribution(delta)
	update_score_label()
	_update_infection_visuals(delta)
	
#endregion
