extends Node2D

@onready var audio_core : AudioStreamPlayer = $AudioCore
@onready var audio_calm : AudioStreamPlayer = $AudioCalm
@onready var audio_alert : AudioStreamPlayer = $AudioAlert
@onready var audio_combat : AudioStreamPlayer = $AudioCombat
@onready var audio_fortified : AudioStreamPlayer = $AudioFortified
@onready var audio_desperation : AudioStreamPlayer = $AudioDesperation
@onready var audio_SFX : AudioStreamPlayer = $AudioSFX

signal evaluate()

#played when either in lab or combat value is low
const TRACK_CALM = preload("res://tower_defense/music/Final Zenith - Piano.ogg")
const TRACK_CALM_LOOPED = preload("res://tower_defense/music/Final Zenith - Piano - Looped.ogg")

#always played
const TRACK_CORE = preload("res://tower_defense/music/Final Zenith - Core.ogg")
const TRACK_CORE_LOOPED = preload("res://tower_defense/music/Final Zenith - Core - Looped.ogg")

#played when combat value ramps up
const TRACK_COMBAT = preload("res://tower_defense/music/Final Zenith - Combat.ogg")
const TRACK_COMBAT_LOOPED = preload("res://tower_defense/music/Final Zenith - Combat - Looped.ogg")

#played when not in lab
const TRACK_ALERT = preload("res://tower_defense/music/Final Zenith - Alert.ogg")
const TRACK_ALERT_LOOPED = preload("res://tower_defense/music/Final Zenith - Alert - Looped.ogg")

#played when defenses are increasing
const TRACK_FORTIFIED = preload("res://tower_defense/music/Final Zenith - Defenses Up.ogg")
const TRACK_FORTIFIED_LOOPED = preload("res://tower_defense/music/Final Zenith - Defenses Up - Looped.ogg")

#played during the final stand
const TRACK_DESPERATION = preload("res://tower_defense/music/Final Zenith - Desperation.ogg")
const TRACK_DESPERATION_LOOPED = preload("res://tower_defense/music/Final Zenith - Desperation - Looped.ogg")

const TWEEN_SPEED = 0.2

var active_tweens : Dictionary = {}
var lost : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_desperation.volume_linear = 0.0
	audio_calm.volume_linear = 0.5
	audio_alert.volume_linear = 0.5
	audio_fortified.volume_linear = 0.0
	audio_core.volume_linear = 0.5
	audio_combat.volume_linear = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func lab(entering : bool) -> void:
	if entering:
		_tween_volume(audio_core, 0.4)
		_tween_volume(audio_calm, 0.4)
		_tween_volume(audio_alert, 0.0)
		_tween_volume(audio_combat, 0.0)
		_tween_volume(audio_fortified, 0.0)
		_tween_volume(audio_desperation, 0.0)
	else:
		_tween_volume(audio_alert, 0.5)
		evaluate.emit()

func update_combat(combat : int, desperate : bool) -> void:
	var target_combat_vol : float = 0.0
	if desperate:
		target_combat_vol = .5
	elif combat > 500:
		target_combat_vol = clamp(remap(combat, 500, 1000, 0.0, 0.5), 0.0, 0.5)
	_tween_volume(audio_combat, target_combat_vol)

	var target_calm_vol : float = 0.5
	if desperate:
		target_calm_vol = .0
	elif combat > 750:
		target_calm_vol = clamp(remap(combat, 750, 1000, 0.5, 0.0), 0.0, 0.5)
	_tween_volume(audio_calm, target_calm_vol)

func update_defense(defense : int) -> void:
	var target_fortified_vol : float = 0.0
	if defense > 400:
		target_fortified_vol = clamp(remap(defense, 400, 1000, 0.0, 0.5), 0.0, 0.5)
	_tween_volume(audio_fortified, target_fortified_vol)

func set_desperation(desperate : bool) -> void:
	var target_vol : float = 0.5 if desperate else 0.0
	_tween_volume(audio_desperation, target_vol)

func _tween_volume(node: AudioStreamPlayer, target_vol: float) -> void:
	#check for existing tweens, timer is safeguard but has failed before
	if active_tweens.has(node) and active_tweens[node].is_running():
		active_tweens[node].kill()
	
	var diff = abs(target_vol - node.volume_linear)
	var duration = diff / TWEEN_SPEED
	
	if duration > 0:
		var tween = create_tween()
		active_tweens[node] = tween
		tween.tween_property(node, "volume_linear", target_vol, duration)
	else:
		node.volume_linear = target_vol
	
func play_game_audio() -> void:
	playStream(audio_alert, TRACK_ALERT)
	playStream(audio_calm, TRACK_CALM)
	playStream(audio_combat, TRACK_COMBAT)
	playStream(audio_core, TRACK_CORE)
	playStream(audio_fortified, TRACK_FORTIFIED)
	playStream(audio_desperation, TRACK_DESPERATION)

func playStream(audio_node: AudioStreamPlayer, audioStream: AudioStream) -> void:
	audio_node.stop()
	audio_node.stream = audioStream
	audio_node.play()
	
func _on_audio_core_finished() -> void:
	playStream(audio_core, TRACK_CORE_LOOPED)
	playStream(audio_calm, TRACK_CALM_LOOPED)
	playStream(audio_alert, TRACK_ALERT_LOOPED)
	playStream(audio_combat, TRACK_COMBAT_LOOPED)
	playStream(audio_fortified, TRACK_FORTIFIED_LOOPED)
	playStream(audio_desperation, TRACK_DESPERATION_LOOPED)
