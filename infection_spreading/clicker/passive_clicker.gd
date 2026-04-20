class_name PlaguePassive extends Resource

signal bought_first(passive : PlaguePassive)

## The number of this passive item
@export var count : int = 0
## The cost to buy one of these passive items
@export var cost : float = 1.0
## The passive benefit in cps of this item
@export var passive_benefit :float =1.0
## The name of this passive item
@export var name : String = ""
## The texture associated with this item
@export var sprite_texture : Texture2D
## The multiplier given to cost after buying one increase for superlinear scaling
@export var cost_mult : float = 1.0
## The amount added to cost after buying one increase for linear scaling
@export var cost_add : float = 1.0

## How much the first upgrade costs
@export var upgrade_cost : float = 30.0

## How much the upgrade multiplies passive benefit by
@export var upgrade_mult : float = 2.0

## How much the upgrades cost should increase by multiplies
@export var upgrade_cost_mult : float = 2.0

## How much the upgrade cost should increase adds
@export var upgrade_cost_add : float = 0.0


@export var button_shader : Shader = preload("res://addons/jeremy_components/shaders/canvas_item/chromatic_glitch.gdshader")

## Gets the passive amount (per second) gained by this item for all copies
func get_passive_amount() -> float:
	return count * passive_benefit

## Gets the passive amount for this second for this item
func get_process_amount(delta : float) -> float:
	return get_passive_amount() * delta

## Multiplies value fo each object by val
func mult_value(val : float) -> void:
	passive_benefit *= val

## Adds val to the value of each object
func add_value(val : float) -> void:
	passive_benefit += val


func buy_another() -> void:
	count += 1
	cost += cost_add
	cost *= cost_mult
	if count == 1:
		bought_first.emit(self)

func upgrade() -> void:
	passive_benefit *= upgrade_mult
	upgrade_cost += upgrade_cost_add
	upgrade_cost *= upgrade_cost_mult
