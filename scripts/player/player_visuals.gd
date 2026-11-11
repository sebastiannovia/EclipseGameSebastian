extends Node2D
class_name PlayerVisuals

# Temporary placeholder look for the runner: a white body with orange accents,
# drawn by the Polygon2D children declared in res://scenes/player/Player.tscn.
#
# This node deliberately knows nothing about physics. It only *reads* the body:
# velocity for the facing direction and `is_grappling` for the hooked tint. The
# rope itself is drawn by PlayerRope, which hangs off the body instead of off
# this node so the mirroring here cannot flip it. The 12 x 20 collision box
# stays exactly as it is, so swapping these polygons for real pixel-art sprites
# later means deleting this node and nothing else.

const SPEED_TO_TURN: float = 12.0 ## px/s: below this the facing is held, so the character does not twitch while decelerating.

const REST_TINT := Color(1.0, 1.0, 1.0)
const HOOK_TINT := Color(1.0, 0.78, 0.44)
const VISOR_TINT := Color(1.0, 1.0, 1.0)

const TINT_RATE: float = 9.0 ## how fast the hooked tint fades in and out

@onready var _body: Player = get_parent() as Player
@onready var _body_poly: Polygon2D = get_node("Body") as Polygon2D
@onready var _visor_poly: Polygon2D = get_node("Visor") as Polygon2D
@onready var _core_poly: Polygon2D = get_node("Core") as Polygon2D

## +1 / -1. Mirrored onto this node's scale, so every child polygon turns with
## the character instead of being redrawn.
var _facing: float = 1.0

## 0 = resting, 1 = rope attached. Eased, so hooking on reads as a glow.
var _hook_tint: float = 0.0


func _ready() -> void:
	scale = Vector2(_facing, 1.0)


func _physics_process(_delta: float) -> void:
	# While swinging the body's velocity is the arc velocity, so this also turns
	# the character to face the direction it is actually travelling in.
	var wanted: float = _facing
	if absf(_body.velocity.x) > SPEED_TO_TURN:
		wanted = signf(_body.velocity.x)
	if wanted != _facing:
		_facing = wanted


func _process(delta: float) -> void:
	_hook_tint = move_tint(delta)

	var body_tint: Color = REST_TINT.lerp(HOOK_TINT, _hook_tint)
	_body_poly.modulate = body_tint
	_core_poly.modulate = body_tint
	_visor_poly.modulate = VISOR_TINT.lerp(HOOK_TINT, _hook_tint)

	scale = Vector2(_facing, 1.0)


func move_tint(delta: float) -> float:
	var target: float = 1.0 if _body.is_grappling else 0.0
	return move_toward(_hook_tint, target, TINT_RATE * delta)
