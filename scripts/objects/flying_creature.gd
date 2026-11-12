extends Node2D
class_name FlyingCreature

# A reusable grapple anchor: a Sky Skimmer that drifts through the air on a
# repeating path and offers one point - the golden harness on its body - that
# the hook can catch.
#
# The artwork is the Sky Skimmer sheet set (fly, glide, hooked, turn, release),
# wired up as an AnimatedSprite2D driven by the SpriteFrames asset in
# assets/art/character/sky_skimmer_frames.tres. The polygons this creature used
# to draw itself with are gone; the motion, the patrol paths and the calls the
# player makes are unchanged, so nothing in the hook code or the level had to
# move when the real art went in.
#
# Placement convention: the node's own position is the *centre* of the patrol, so
# a creature can be positioned and then tuned with patrol_amplitude without
# working out offsets. The grapple point is a Marker2D child, which is also where
# its collider sits: what the hook can see is what the hook can catch.
#
# Harness alignment: the sheets draw the harness in a different part of the frame
# for each animation, so each animation carries its own sprite offset, worked out
# from where the harness actually sits in that animation's cell (HARNESS_IN_CELL),
# measured off the sheets. The creature turns around by flipping this node's
# scale.x, which mirrors the sprite and that offset together, so the harness
# stays on the grapple point whichever way the creature is facing. Flipping with
# AnimatedSprite2D.flip_h instead would mirror the artwork only and would pull
# the harness off the anchor the moment the creature changed direction.

const GRAPPLE_GROUP := &"grappleable"
const CREATURE_LAYER := 4 ## the layer the player's line-of-sight ray looks for

## Where the golden harness sits inside one 96x64 frame, measured from the centre
## of that frame, with +x pointing the way the creature faces.
const HARNESS_IN_CELL := {
	&"fly": Vector2(15.0, 6.0),
	&"glide": Vector2(10.0, 3.0),
	&"hooked": Vector2(7.0, 10.0),
	&"turn": Vector2(3.0, -7.0),
	&"release": Vector2(10.0, 7.0),
}

const FLY_FRAMES := 8.0 ## frames in one fly loop
const FLY_BEATS_PER_LOOP := 2.0 ## one fly loop is an up-beat and a down-beat
const FLY_ANIM_FPS := 18.0 ## the fps the fly animation is authored at

const ANCHOR_ANIM := &"anchor" ## the looping sky_skimmer_anchor_fx animation
const GLIDE_DRIFT := 0.35 ## px per physics tick under which the creature glides
const TURN_SECONDS := 0.5 ## how long the turn pose is held: 6 frames at 12 fps
const RELEASE_SECONDS := 0.4 ## how long the release pose is held after a detach
const OFFSET_BLEND := 0.05 ## seconds the artwork takes to settle onto the anchor

@export_group("Motion")

@export_range(0.0, 400.0, 1.0) var patrol_amplitude: float = 60.0 ## how far left and right of its own position the creature travels
@export_range(0.25, 20.0, 0.05) var patrol_period: float = 4.0 ## seconds for one full there-and-back cycle
@export_range(0.0, 60.0, 1.0) var bob_amplitude: float = 8.0 ## vertical drift riding on top of the patrol
@export_range(0.25, 20.0, 0.05) var bob_period: float = 2.2
@export var loops: bool = false ## true: drift around an ellipse instead of back and forth
@export var loop_radius: Vector2 = Vector2(50.0, 16.0) ## size of that ellipse when loops is true
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0 ## 0..1 offset, so creatures in a chain are not in step

@export_group("Look")

@export var range_color: Color = Color(0.62, 0.86, 1.0, 1.0) ## tint of the anchor effect while the hook could reach this creature
@export var hooked_color: Color = Color(1.0, 0.66, 0.24, 1.0) ## tint of the anchor effect while a rope is on it
@export_range(1.0, 12.0, 0.5) var flap_speed: float = 4.5 ## wing beats per second
@export_range(0.1, 1.5, 0.05) var anchor_scale: float = 0.5 ## size of the anchor effect, whose art fills its 48x48 cell

## Beacon state pushed in by the player: this creature is the closest one the
## hook could reach, and whether a rope is actually attached to it.
var _in_range_hint: bool = false
var _hooked: bool = false

var _home: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _facing: float = 1.0
var _last_x: float = 0.0

var _sprite: AnimatedSprite2D = null
var _frames: SpriteFrames = null
var _anchor_fx: AnimatedSprite2D = null
var _anchor_frames: SpriteFrames = null
var _pose: StringName = &"fly"
var _gliding: bool = false
var _turn_timer: float = 0.0
var _release_timer: float = 0.0


func _ready() -> void:
	add_to_group(GRAPPLE_GROUP)
	_home = position
	_last_x = position.x

	_sprite = get_node_or_null("Sprite") as AnimatedSprite2D
	_anchor_fx = get_node_or_null("AnchorFx") as AnimatedSprite2D

	if _sprite != null:
		_frames = _sprite.sprite_frames
		_sprite.offset = _pose_offset(_pose)
		_sprite.speed_scale = _fly_speed_scale()
		if _frames != null and _frames.has_animation(_pose):
			_sprite.play(_pose)
	if _anchor_fx != null:
		_anchor_frames = _anchor_fx.sprite_frames
		# The effect marks the point the hook ties to, so it sits on the marker
		# rather than on a fixed number: move GrapplePoint and it follows.
		_anchor_fx.position = _grapple_point_local()
		_anchor_fx.visible = false


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var period: float = maxf(0.05, patrol_period)
	var t: float = _elapsed + phase * period
	if loops:
		var angle: float = TAU * t / period
		position = _home + Vector2(cos(angle) * loop_radius.x, sin(angle) * loop_radius.y)
	else:
		position = _home + Vector2(
			sin(TAU * t / period) * patrol_amplitude,
			sin(TAU * t / maxf(0.05, bob_period)) * bob_amplitude
		)

	var drift: float = position.x - _last_x
	if absf(drift) > 0.01:
		var facing: float = signf(drift)
		if facing != _facing:
			_facing = facing
			_turn_timer = TURN_SECONDS
		_last_x = position.x
		scale = Vector2(_facing, 1.0)

	# Close to a turnaround the creature barely moves sideways: that is the glide.
	_gliding = absf(drift) < GLIDE_DRIFT

	_turn_timer = maxf(0.0, _turn_timer - delta)
	_release_timer = maxf(0.0, _release_timer - delta)
	_update_pose(delta)
	_update_anchor_fx()


## World-space grapple point of this creature: the child Marker2D if there is one.
func get_grapple_point() -> Vector2:
	var marker: Marker2D = get_node_or_null("GrapplePoint") as Marker2D
	return marker.global_position if marker != null else global_position


## Called by the player every physics tick on whichever creature the hook would
## land on, and on the one it was lit on before, to switch the beacon off again.
func set_grapple_hint(in_range: bool, hooked: bool) -> void:
	if _in_range_hint == in_range and _hooked == hooked:
		return
	_in_range_hint = in_range
	_hooked = hooked
	_update_pose(0.0)


func on_hooked() -> void:
	_hooked = true
	_in_range_hint = true
	_update_pose(0.0)


func on_released() -> void:
	_hooked = false
	_release_timer = RELEASE_SECONDS
	_update_pose(0.0)


## The pose the sheets should be showing right now, and the animation that plays
## it. A hooked creature keeps flying around on its patrol: only the artwork
## reacts, so a reacting creature never pulls the rope out from under the player.
func _update_pose(delta: float) -> void:
	var pose: StringName = &"fly"
	if _hooked:
		pose = &"hooked"
	elif _release_timer > 0.0:
		pose = &"release"
	elif _turn_timer > 0.0:
		pose = &"turn"
	elif _gliding:
		pose = &"glide"

	if _sprite == null:
		return
	if pose != _pose:
		_pose = pose
		_sprite.speed_scale = _fly_speed_scale() if pose == &"fly" else 1.0
		if _frames != null and _frames.has_animation(_pose):
			_sprite.play(_pose)

	# Slide the artwork so the harness lands on the grapple point for the pose.
	var target: Vector2 = _pose_offset(_pose)
	var blend: float = clampf(delta / OFFSET_BLEND, 0.0, 1.0)
	_sprite.offset = _sprite.offset.lerp(target, blend)


## flap_speed is wing beats per second: convert that into a speed multiplier for
## the authored fly loop, so tuning the creature changes its flap, not the asset.
func _fly_speed_scale() -> float:
	var loops_per_second: float = flap_speed / FLY_BEATS_PER_LOOP
	var authored_loops_per_second: float = FLY_ANIM_FPS / FLY_FRAMES
	return clampf(loops_per_second / authored_loops_per_second, 0.1, 4.0)


## Sprite offset that puts this pose's harness on the grapple point.
func _pose_offset(pose: StringName) -> Vector2:
	var harness: Variant = HARNESS_IN_CELL.get(pose, Vector2.ZERO)
	return _grapple_point_local() - (harness as Vector2)


## The anchor effect: the pulsing ring from the pack, sitting on the grapple
## point. Cool and pulsing while the hook could reach, warm and fuller while a
## rope is on it.
func _update_anchor_fx() -> void:
	if _anchor_fx == null:
		return
	var lit: bool = _in_range_hint or _hooked
	if _anchor_fx.visible != lit:
		_anchor_fx.visible = lit
	if not lit:
		return

	if _hooked:
		_anchor_fx.modulate = Color(hooked_color, 1.0)
		_anchor_fx.scale = Vector2(anchor_scale * 1.1, anchor_scale * 1.1)
		_anchor_fx.speed_scale = 1.0
	else:
		var pulse: float = 0.5 + 0.5 * sin(_elapsed * 2.5)
		_anchor_fx.modulate = Color(range_color, 0.38 + 0.2 * pulse)
		_anchor_fx.scale = Vector2(anchor_scale, anchor_scale)
		_anchor_fx.speed_scale = 1.0

	if _anchor_frames != null and _anchor_frames.has_animation(ANCHOR_ANIM) \
			and _anchor_fx.animation != ANCHOR_ANIM:
		_anchor_fx.play(ANCHOR_ANIM)


func _grapple_point_local() -> Vector2:
	var marker: Marker2D = get_node_or_null("GrapplePoint") as Marker2D
	return marker.position if marker != null else Vector2.ZERO
