extends Resource
class_name Wave

@export var number_of_waves : int = 1
@export var enemies_per_wave : int = 10
#@export var enemy_types : Array[Enemy] = []

# Enemy stat multipliers
@export var damage_multiplier : float = 1.0
@export var health_multiplier : float = 1.0
@export var speed_multiplier : float = 1.0
