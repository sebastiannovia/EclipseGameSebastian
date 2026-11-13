extends Node2D
class_name PlayerVisuals

# Idle uses the original rig; locomotion uses complete, aligned PNG frames.

const SCALE: float = 0.125
const SPEED_TO_TURN: float = 3.0
const IDLE_CYCLE_SECONDS: float = 2.4
const BREATH_LIFT_SOURCE_PX: float = 8.0

@onready var _body: Player = get_parent() as Player
@onready var _torso: Node2D = get_node("RigCanvas/Pelvis/Torso") as Node2D
@onready var _helmet: Node2D = get_node("RigCanvas/Pelvis/Torso/HelmetHead") as Node2D
@onready var _rear_arm: Node2D = get_node("RigCanvas/Pelvis/Torso/RearUpperArm") as Node2D
@onready var _front_arm: Node2D = get_node("RigCanvas/Pelvis/Torso/FrontUpperArm") as Node2D

@onready var _rig: Node2D = get_node("RigCanvas") as Node2D
@onready var _walk: Sprite2D = get_node("WalkFrames") as Sprite2D
@onready var _jump: Sprite2D = get_node("JumpFrames") as Sprite2D

const STRIDE_DISTANCE := 64.0
const WALK_FRAME_COUNT := 8
var _walk_phase := 0.0
var _takeoff_timer := 0.0
var _landing_timer := 0.0
var _airborne_visual := false

var _facing: float = 1.0
var _idle_elapsed: float = 0.0


func _ready() -> void:
	_set_facing(1.0)
	_body.visual_jump.connect(_on_jump_started)
	_body.visual_landing.connect(_on_landed)
	_body.grapple_attached.connect(_on_jump_started)
	_body.grapple_released.connect(_on_grapple_released)
	_snap_visual_origin()


func _physics_process(_delta: float) -> void:
	if absf(_body.velocity.x) > SPEED_TO_TURN:
		_set_facing(-1.0 if _body.velocity.x < 0.0 else 1.0)


func _process(delta: float) -> void:
	_snap_visual_origin()
	_takeoff_timer = maxf(0.0, _takeoff_timer - delta)
	_landing_timer = maxf(0.0, _landing_timer - delta)
	var speed: float = absf(_body.velocity.x)
	var grounded: bool = _body.is_on_floor() and not _body.is_grappling and _body.is_physics_processing()
	var moving: bool = grounded and speed > SPEED_TO_TURN
	var jumping: bool = (_airborne_visual and not _body.is_grappling and _body.is_physics_processing()) or (_landing_timer > 0.0 and grounded and speed <= SPEED_TO_TURN)
	_rig.visible = not moving and not jumping
	_walk.visible = moving
	_jump.visible = jumping
	_set_neutral_pose()
	if moving:
		_walk_phase = fposmod(_walk_phase + speed * delta / STRIDE_DISTANCE, 1.0)
		_walk.frame = int(_walk_phase * WALK_FRAME_COUNT) % WALK_FRAME_COUNT
	else:
		_walk_phase = 0.0
		if grounded and not jumping:
			_idle_elapsed = fposmod(_idle_elapsed + delta, IDLE_CYCLE_SECONDS)
			_apply_idle_pose()
	if jumping:
		_update_jump_frame()


func _update_jump_frame() -> void:
	var frame := 1
	if _takeoff_timer > 0.0:
		frame = 0
	elif _landing_timer > 0.08:
		frame = 6
	elif _landing_timer > 0.0:
		frame = 7
	elif _body.velocity.y < -150.0:
		frame = 1 if _body.velocity.y < -235.0 else 2
	elif _body.velocity.y < -35.0:
		frame = 3
	elif _body.velocity.y < 180.0:
		frame = 4
	else:
		frame = 5
	_jump.frame = frame
	# Align the landing soles to the unchanged feet origin.
	var sole_rows: Array[float] = [492.0, 467.0, 404.0, 386.0, 448.0, 470.0, 474.0, 475.0]
	_jump.position.y = -191.25 + (466.0 - sole_rows[frame]) * 0.9107143


func _on_jump_started(_unused: Variant = null) -> void:
	_airborne_visual = true
	_takeoff_timer = 0.075
	_landing_timer = 0.0


func _on_landed(_impact: float = 0.0) -> void:
	_airborne_visual = false
	_takeoff_timer = 0.0
	_landing_timer = 0.15


func _on_grapple_released(_creature: Node2D) -> void:
	_airborne_visual = true


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
