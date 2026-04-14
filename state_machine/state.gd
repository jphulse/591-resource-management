@abstract class_name State extends Node

@export_category("Abstract state info")
@export var state_id : StringName

# Used to hook transitions between states in state machine
@warning_ignore("unused_signal") signal Transition(caller : State, next_state_id : StringName)

@warning_ignore("unused_signal") signal EmergencyTransition(caller : State, next_state_id : StringName)

## The node that this scene is ultimately owned by (i.e. player, boss, door, etc.)
var owner_node : Node

## Sets the owner node of this state, typically done by the state machine
func set_owner_node(n : Node) -> void:
	owner_node = n

## Executed when this state is entered, think of this as a repeated ready function
func enter() -> void:
	pass

## Executes when this state is left think of this like a cleanup/ exit_tree function
func exit() -> void:
	pass

## '_process's frame iteration is passed to the state's update to run every frame
func update(_delta : float) -> void:
	pass

## '_physics_process' frame iteration is passed to the state's update to run every fixed physics frame
func physics_update(_delta : float) -> void:
	pass
