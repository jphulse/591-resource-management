class_name EnemyAttackArea extends Area2D

var parent: Node2D
var damage: float

@onready var collider : CollisionShape2D = $CollisionShape2D

func setup(node_parent: Node2D, node_damage: float) -> void:
	parent = node_parent
	damage = node_damage
