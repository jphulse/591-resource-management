class_name rail_projectile extends Area2D

var damage: float

@onready var collider_bar : CollisionShape2D = $CollisionShape2D
@onready var sprite_rail : AnimatedSprite2D = $AnimatedSprite2D
