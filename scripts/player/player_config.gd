class_name PlayerConfig
extends Resource

# All movement tunables for the player controller, in one place.
# The controller reads these every physics tick, so editing this resource
# (res://resources/PlayerConfig.tres) in the inspector changes the feel of the
# whole game without touching code.

@export_group("Horizontal")

## Maximum horizontal speed in pixels per second.
@export_range(1.0, 600.0, 1.0) var max_speed: float = 150.0

## How quickly the player reaches max_speed, in pixels per second squared.
@export_range(1.0, 10000.0, 1.0) var acceleration: float = 1200.0

## How quickly the player stops when there is no input, in px/s squared.
## Also used while turning, so a reversal is never slower than a stop.
@export_range(1.0, 10000.0, 1.0) var deceleration: float = 1600.0

@export_group("Vertical")

## Downward acceleration while airborne. Positive value means "downwards".
@export_range(1.0, 4000.0, 1.0) var gravity: float = 900.0

## Vertical velocity applied at the start of a jump. Negative value means "up".
@export_range(-2000.0, -1.0, 1.0) var jump_velocity: float = -300.0

## Terminal falling speed. Positive value means "downwards".
@export_range(1.0, 4000.0, 1.0) var max_fall_speed: float = 420.0

## Fraction of the upward velocity kept when jump is released mid-rise.
## 1.0 = no jump cut (every jump is full height), 0.0 = releasing kills the jump.
@export_range(0.0, 1.0, 0.01) var jump_cut_multiplier: float = 0.45

@export_group("Assists")

## Grace period after leaving the ground in which a jump is still allowed.
## 0.0 disables coyote time.
@export_range(0.0, 1.0, 0.005) var coyote_time: float = 0.10

## Grace period for a jump press that could not run yet (pressed in mid-air).
## 0.0 disables jump buffering.
@export_range(0.0, 1.0, 0.005) var jump_buffer_time: float = 0.10

@export_group("Grapple")

## Maximum distance, in pixels, between the player and a creature's grapple point
## at which the hook can still find and attach to that creature.
@export_range(40.0, 400.0, 1.0) var grapple_range: float = 160.0

## Shortest rope the hook is allowed to fix at attachment. A very close creature
## still leaves room to swing instead of pinning the player to it.
@export_range(20.0, 400.0, 1.0) var min_rope_length: float = 45.0

## Tangential acceleration, in px/s squared, that A / D add to the swing while
## attached. This is what pumps an arc bigger from one swing to the next.
@export_range(100.0, 4000.0, 1.0) var swing_push: float = 900.0

## Speed, in px/s, that the swing keeps below while pumping with A / D. Gravity
## can carry an arc past it; the input simply stops adding once it is reached.
@export_range(50.0, 1000.0, 1.0) var swing_max_speed: float = 420.0
