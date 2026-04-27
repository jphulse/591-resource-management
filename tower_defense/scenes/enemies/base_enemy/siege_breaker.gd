extends Enemy

signal ultimate_death()
signal summon_minion(minion : PackedScene, path : Path2D)

@export var minion : PackedScene
@export var MINION_SQUAD = 5
@onready var summon_timer : Timer = $Summon_Timer
@onready var delay_summon_timer : Timer = $Summon_Delay

var remaining_summons = 0
var parent_path : Path2D

func _process(delta: float) -> void:
	if path_follow:
		if not towers_in_range:
			path_follow.progress += movement_speed * delta
		else:
			if can_attack:
				attack()
		
		if path_follow.progress_ratio >= 0.99:
			enemy_death.emit(-enemy_value)
			ultimate_death.emit()
			path_follow.queue_free()
			queue_free()

func take_damage(incoming_damage: float) -> void:
	var total_incoming_damage = incoming_damage - 5
	if total_incoming_damage < .5 :
		total_incoming_damage = .2
	health = health - total_incoming_damage
	health_bar.value = health

	if health <= 0.0:
		death_sequence()
		ultimate_death.emit()
		enemy_death.emit(-enemy_value)
		path_follow.queue_free()
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Bullet:
		take_damage(area.damage)
		
	# Check to see if this is the end target to attack
	#if area is Area2D:
		#queue_free()

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area is TowerHitbox or area is ObjectiveArea:
		if area not in towers_in_range:
			towers_in_range.append(area)

func _on_attack_area_area_exited(area: Area2D) -> void:
	if area in towers_in_range:
		towers_in_range.erase(area)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func _on_summon_timer_timeout() -> void:
	summon_timer.start(randf_range(4.5, 7.5))
	delay_summon_timer.start(.3)
	remaining_summons = MINION_SQUAD
	
func _on_summon_delay_timeout() -> void:
	if(remaining_summons == 0):
		return
	delay_summon_timer.start(.3)
	remaining_summons -= 1
	summon_minion.emit(minion, parent_path)
