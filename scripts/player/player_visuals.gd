extends Node2D
class_name PlayerVisuals

# The cutout rig is visual-only. CharacterBody2D and rope mechanics are untouched.

const SCALE: float = 0.125
const SPEED_TO_TURN: float = 12.0
const IDLE_CYCLE_SECONDS: float = 2.4
const BREATH_LIFT_SOURCE_PX: float = 8.0

@onready var _body: Player = get_parent() as Player
@onready var _torso: Node2D = get_node("RigCanvas/Pelvis/Torso") as Node2D
@onready var _helmet: Node2D = get_node("RigCanvas/Pelvis/Torso/HelmetHead") as Node2D
@onready var _rear_arm: Node2D = get_node("RigCanvas/Pelvis/Torso/RearUpperArm") as Node2D
@onready var _front_arm: Node2D = get_node("RigCanvas/Pelvis/Torso/FrontUpperArm") as Node2D

var _facing: float = 1.0
var _idle_elapsed: float = 0.0


func _ready() -> void:
	_set_facing(1.0)
	_snap_visual_origin()


func _physics_process(_delta: float) -> void:
	if absf(_body.velocity.x) > SPEED_TO_TURN:
		_set_facing(-1.0 if _body.velocity.x < 0.0 else 1.0)


func _process(delta: float) -> void:
	_snap_visual_origin()
	if _body.is_on_floor() and absf(_body.velocity.x) <= SPEED_TO_TURN and not _body.is_grappling:
		_idle_elapsed = fposmod(_idle_elapsed + delta, IDLE_CYCLE_SECONDS)
		_apply_idle_pose()
	else:
		_set_neutral_pose()


func _apply_idle_pose() -> void:
	var phase := _idle_elapsed / IDLE_CYCLE_SECONDS
	var breath := 0.5 - 0.5 * cos(TAU * phase)
	_torso.position.y = -BREATH_LIFT_SOURCE_PX * breath
	_helmet.rotation = 0.012 * sin(TAU * phase + 0.25)
	_rear_arm.rotation = 0.018 * sin(TAU * phase)
	_front_arm.rotation = -0.015 * sin(TAU * phase + 0.2)


func _set_neutral_pose() -> void:
	_torso.position.y = 0.0
	_helmet.rotation = 0.0
	_rear_arm.rotation = 0.0
	_front_arm.rotation = 0.0


func _set_facing(direction: float) -> void:
	_facing = direction
	scale = Vector2(SCALE * _facing, SCALE)


func _snap_visual_origin() -> void:
	global_position = _body.global_position.round()
