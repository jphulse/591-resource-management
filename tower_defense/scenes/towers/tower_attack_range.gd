class_name TowerAttackRange extends Area2D

var parent: Node2D
var damage: float

func setup(node_parent: Node2D, node_damage: float) -> void:
	parent = node_parent
	damage = node_damage
