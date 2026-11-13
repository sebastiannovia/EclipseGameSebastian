extends CharacterBody2D
class_name Player

# Phase 5 player controller: horizontal movement, jumping and the grappling hook.
# The hook attaches to a flying creature, the rope holds the body at a fixed
# distance from that creature's grapple point, and gravity turns the leftover
# velocity into a pendulum swing. Movement and jumping keep their earlier tuning;
# the hook is the only air ability in the moveset.
#
# Design rules kept here:
#  - Only named InputMap actions are read (never key codes).
#  - Every tunable comes from PlayerConfig, never from a literal.
#  - All integration uses the fixed physics `delta`, so the feel is identical
#    at any frame rate.
#  - Collision with the level still runs through move_and_slide(): the rope only
#    trims velocity and nudges the body back onto its arc, so floors and walls
#    keep resolving exactly as they did before.

const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_JUMP := &"jump"
const ACTION_GRAPPLE := &"grapple"

const GRAPPLE_GROUP := &"grappleable" ## every creature that can be hooked joins this group
const LAND_HEAVY_SPEED := 330.0
const STEP_DISTANCE := 32.0

const SOUND_JUMP: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_jump.wav")
const SOUND_STEP_A: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_footstep_01.wav")
const SOUND_STEP_B: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_footstep_02.wav")
const SOUND_LAND_SOFT: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_land_soft.wav")
const SOUND_LAND_HEAVY: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_land_heavy.wav")
const SOUND_LAUNCH: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/grapple_launch.wav")
const SOUND_ATTACH: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/grapple_attach.wav")
const SOUND_MISS: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/grapple_miss.wav")
const SOUND_RELEASE: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/grapple_release.wav")
const SOUND_SWING: AudioStream = preload("res://assets/audio/sfx/stratos_v1/loops/grapple_swing_loop.wav")

## Where the rope is tied to the body and where its length is measured from. The
## body origin is the feet, so the tie sits on the chest.
const ROPE_TIE := Vector2(0.0, -14.0)

## How far past its length the rope may stretch before the body is pulled back
## onto the arc. Anything smaller is ordinary per-step integration error.
const ROPE_SLACK: float = 0.5

## Emitted when the hook lands on a creature and when the rope lets go of it.
## Visuals and the creatures themselves subscribe; nothing here draws anything.
signal grapple_attached(creature: Node2D)
signal grapple_released(creature: Node2D)
signal visual_jump
signal visual_landing(impact: float)

## True while the rope is attached. Public so animation/VFX code can read it.
var is_grappling: bool = false

## Movement parameters. Assigned in Player.tscn from res://resources/PlayerConfig.tres.
@export var config: PlayerConfig = null

# Coyote time: seconds left in which a jump is still allowed after leaving the
# ground. Refreshed to config.coyote_time while grounded, spent on a jump.
var _coyote_remaining: float = 0.0

# Jump buffer: seconds left in which a jump press that could not run yet will
# still be honoured as soon as the player can jump.
var _jump_buffer_remaining: float = 0.0

# True from the moment a jump starts until the player is grounded again, so the
# release cut only ever applies once, to the jump that is currently rising.
var _jump_needs_cut: bool = false

# --- grapple state -----------------------------------------------------------
# Two states only: normal, or attached to one creature.

# The creature the rope is fixed to, and that creature's grapple point in world
# space. Re-read every tick, because the creature moves and the rope follows it.
var _creature: Node2D = null
var _anchor: Vector2 = Vector2.ZERO

# Distance the rope holds the tie point at, fixed the moment the hook lands.
var _rope_length: float = 0.0

# Closest creature the hook would land on if E were pressed now, and its grapple
# point. Null when nothing eligible is in range with a clear line.
var _candidate: Node2D = null
var _candidate_anchor: Vector2 = Vector2.ZERO

# True from an E press until E is released. While it is set the hook keeps
# looking, so a creature that comes into range mid-press is caught without a
# second press. Cleared by releasing E, which is also what detaches.
var _hook_armed: bool = false

# Creature currently showing the "in range" beacon, so it can be turned off again
# instead of every creature redrawing it every frame.
var _hinted: Node2D = null
var _audio_players: Dictionary = {}
var _step_distance: float = 0.0
var _step_alternate: bool = false
var _swing_fade: Tween = null
var _swing_audio_active: bool = false


func _ready() -> void:
	_ensure_gamepad_jump_binding()
	if config == null:
		push_warning("Player has no PlayerConfig assigned; falling back to defaults.")
		config = PlayerConfig.new()
	velocity = Vector2.ZERO
	is_grappling = false
	add_to_group("player")
	_create_audio_players()


## The project stores InputMap events by numeric enum value; keep this guard in
## terms of Godot's logical button constant and avoid adding a duplicate event.
func _ensure_gamepad_jump_binding() -> void:
	var jump_events: Array[InputEvent] = InputMap.action_get_events(ACTION_JUMP)
	for input_event in jump_events:
		var button_event: InputEventJoypadButton = input_event as InputEventJoypadButton
		if button_event != null and button_event.button_index == JOY_BUTTON_A and button_event.device == -1:
			return
	var new_button_event := InputEventJoypadButton.new()
	new_button_event.device = -1
	new_button_event.button_index = JOY_BUTTON_A
	InputMap.action_add_event(ACTION_JUMP, new_button_event)


func _physics_process(delta: float) -> void:
	# is_on_floor() reports the result of the previous move_and_slide(), so the
	# assist timers are refreshed before anything can consume them.
	_refresh_coyote_time(delta)
	_refresh_jump_buffer(delta)
	var was_on_floor: bool = is_on_floor()
	var landing_speed: float = velocity.y
	var old_x: float = global_position.x
	_update_hook()
	if is_grappling:
		# While attached the rope owns the horizontal motion: gravity still pulls,
		# but only the sideways part of the resulting velocity survives.
		_apply_swing_motion(delta)
	else:
		_apply_gravity(delta)
		_apply_horizontal_motion(delta)
	_start_pending_jump()
	_cut_jump_on_release()
	move_and_slide()
	if is_grappling:
		_reel_onto_arc()
	_update_swing_audio()
	_update_movement_audio(was_on_floor, landing_speed, old_x)


# --- movement ---------------------------------------------------------------

func _apply_horizontal_motion(delta: float) -> void:
	var direction: float = Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)
	if is_zero_approx(direction):
		if not is_on_floor() and absf(velocity.x) > config.max_speed:
			# Speed above the walking top speed can only come from a released
			# swing, and a released swing is supposed to keep it: coast instead of
			# braking the player back to a standstill in mid air.
			return
		velocity.x = move_toward(velocity.x, 0.0, config.deceleration * delta)
		return

	var target_speed: float = direction * config.max_speed
	if not is_on_floor() and signf(velocity.x) == signf(direction) and absf(velocity.x) > config.max_speed:
		# Same reasoning while a key is held: steering still works, but the swing's
		# speed is not bled away by the ordinary walk cap.
		return

	var rate: float = config.acceleration
	if not is_zero_approx(velocity.x) and signf(direction) != signf(velocity.x):
		# Turning around uses the stronger of the two rates so a reversal feels
		# immediate instead of coasting through a full stop first.
		rate = maxf(config.acceleration, config.deceleration)
	# move_toward never overshoots the target, which is what caps the speed.
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)


# --- jumping ----------------------------------------------------------------

func _start_pending_jump() -> void:
	# Normal jumping is switched off for the whole time the rope is attached.
	if is_grappling:
		return
	# A jump runs when a press is still buffered *and* the player is allowed to
	# leave the ground (still grounded, or inside coyote time).
	if _jump_buffer_remaining <= 0.0 or _coyote_remaining <= 0.0:
		return
	velocity.y = config.jump_velocity
	_play_audio("jump", SOUND_JUMP)
	visual_jump.emit()
	_step_distance = 0.0
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	_jump_needs_cut = true


func _cut_jump_on_release() -> void:
	if not _jump_needs_cut:
		return
	if is_on_floor() and velocity.y >= 0.0:
		_jump_needs_cut = false
		return
	if velocity.y < 0.0 and not Input.is_action_pressed(ACTION_JUMP):
		# Releasing early shortens the rise without touching gravity, so the
		# fall arc stays identical: short hop or full jump, same descent.
		velocity.y *= config.jump_cut_multiplier
		_jump_needs_cut = false


# --- grappling hook ----------------------------------------------------------

## Reads E, decides what the hook is tied to, and tries to land it. Runs before
## motion so the swing always uses this tick's anchor position.
func _update_hook() -> void:
	var grapple_pressed: bool = Input.is_action_just_pressed(ACTION_GRAPPLE)
	if grapple_pressed:
		_hook_armed = true
	if is_grappling and not Input.is_action_pressed(ACTION_GRAPPLE):
		_detach()

	if is_grappling:
		_anchor = _anchor_of(_creature)
		_candidate = _creature
		_candidate_anchor = _anchor
	else:
		_candidate = _find_candidate()

	if grapple_pressed and not is_grappling:
		if _candidate != null:
			_play_audio("launch", SOUND_LAUNCH)
		else:
			_play_audio("miss", SOUND_MISS)
	if _hook_armed and not is_grappling and _candidate != null:
		_attach(_candidate)

	_publish_beacons()


## Nearest eligible creature inside config.grapple_range with an unobstructed
## line from the tie point to its grapple point. Null when there is none.
func _find_candidate() -> Node2D:
	var from: Vector2 = global_position + ROPE_TIE
	var best: Node2D = null
	var best_anchor: Vector2 = Vector2.ZERO
	var best_distance: float = config.grapple_range
	for node in get_tree().get_nodes_in_group(GRAPPLE_GROUP):
		var creature: Node2D = node as Node2D
		if creature == null:
			continue
		var anchor: Vector2 = _anchor_of(creature)
		var distance: float = from.distance_to(anchor)
		if distance > best_distance:
			continue
		if not _has_clear_line(from, anchor, creature):
			continue
		best_distance = distance
		best = creature
		best_anchor = anchor
	_candidate_anchor = best_anchor
	return best


## True unless level geometry lies between the tie point and the creature. The
## creature's own collider counts as a clear line, not as a wall.
func _has_clear_line(from: Vector2, to: Vector2, creature: Node2D) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return true
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		from, to, collision_mask, [get_rid()])
	var hit: Variant = space.intersect_ray(query)
	if not (hit is Dictionary):
		return true
	var result: Dictionary = hit
	if result.is_empty():
		return true
	var node: Node = result["collider"] as Node
	while node != null:
		if node == creature or node.is_in_group(GRAPPLE_GROUP):
			return true
		node = node.get_parent()
	return false


func _attach(creature: Node2D) -> void:
	_creature = creature
	_anchor = _anchor_of(creature)
	var distance: float = (global_position + ROPE_TIE - _anchor).length()
	_rope_length = clampf(distance, config.min_rope_length, config.grapple_range)
	is_grappling = true
	# Whatever jump was in the air is over; its release cut must not be applied to
	# the vertical motion a swing produces afterwards.
	_jump_needs_cut = false
	if creature.has_method("on_hooked"):
		creature.call("on_hooked")
	_play_audio("attach", SOUND_ATTACH)
	grapple_attached.emit(creature)


## Lets go of the creature. Velocity is deliberately untouched: the speed the
## swing had at the moment of release carries straight on into free flight.
func _detach() -> void:
	if _creature == null:
		return
	var released: Node2D = _creature
	_creature = null
	_anchor = Vector2.ZERO
	_rope_length = 0.0
	is_grappling = false
	# Still holding E arms the hook again, so chaining a second creature off the
	# same press works; letting go of E returns control to normal movement.
	_hook_armed = Input.is_action_pressed(ACTION_GRAPPLE)
	if released.has_method("on_released"):
		released.call("on_released")
	_play_audio("release", SOUND_RELEASE)
	grapple_released.emit(released)


## World-space grapple point of a creature: its own answer if it has one,
## otherwise the node itself.
func _anchor_of(creature: Node2D) -> Vector2:
	if creature != null and creature.has_method("get_grapple_point"):
		return creature.call("get_grapple_point") as Vector2
	return creature.global_position if creature != null else Vector2.ZERO


## Unit vector from the anchor out to the tie point. Zero when the body sits
## exactly on the anchor, where there is no arc to swing on.
func _rope_direction(tie: Vector2) -> Vector2:
	var offset: Vector2 = tie - _anchor
	var distance: float = offset.length()
	if distance <= 0.001:
		return Vector2.ZERO
	return offset / distance


## Pendulum step: gravity first, then the arc push from A / D, then the rope.
func _apply_swing_motion(delta: float) -> void:
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)

	var radial: Vector2 = _rope_direction(global_position + ROPE_TIE)
	if radial == Vector2.ZERO:
		return
	var tangent: Vector2 = Vector2(-radial.y, radial.x)

	# A / D pump along the arc. The tangent is taken in whichever direction points
	# the way the key is pressed, so holding D always drives the swing rightwards
	# and holding A always drives it leftwards, at every point of the arc.
	var axis: float = Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)
	if not is_zero_approx(axis):
		if tangent.x * axis < 0.0:
			tangent = -tangent
		if absf(velocity.dot(tangent)) < config.swing_max_speed:
			velocity += tangent * (absf(axis) * config.swing_push * delta)

	# The rope is rigid: any velocity that would stretch it is taken back out,
	# and only the sideways remainder keeps the swing going. This trim is the
	# pendulum; the fixed length below is what holds the player to the arc.
	var outward: float = velocity.dot(radial)
	if outward > 0.0:
		velocity -= radial * outward


## After move_and_slide(): put the body back on its arc if the step overshot it.
## The correction only ever moves inwards, towards the creature, and the next
## move_and_slide() still resolves whatever solid geometry it meets.
func _reel_onto_arc() -> void:
	var offset: Vector2 = global_position + ROPE_TIE - _anchor
	var distance: float = offset.length()
	if distance <= _rope_length + ROPE_SLACK:
		return
	global_position -= offset.normalized() * (distance - _rope_length)


## Turns the "a creature is in grapple range" beacon on for one creature and off
## for the one it was lit on before.
func _publish_beacons() -> void:
	var hooked: Node2D = _creature if is_grappling else null
	if _hinted != _candidate:
		if _hinted != null and _hinted.has_method("set_grapple_hint"):
			_hinted.call("set_grapple_hint", false, false)
		_hinted = _candidate
	if _hinted != null and _hinted.has_method("set_grapple_hint"):
		_hinted.call("set_grapple_hint", true, _hinted == hooked)


## Drop the rope and the hook without emitting signals: used by the level on
## respawn and on victory, where the level handles the velocity itself.
func clear_grapple_state() -> void:
	_stop_swing_audio(true)
	if _creature != null and _creature.has_method("on_released"):
		_creature.call("on_released")
	_creature = null
	_candidate = null
	_anchor = Vector2.ZERO
	_rope_length = 0.0
	_hook_armed = false
	is_grappling = false
	_publish_beacons()


# --- assist timers ----------------------------------------------------------

func _refresh_coyote_time(delta: float) -> void:
	if is_on_floor():
		_coyote_remaining = config.coyote_time
		return
	_coyote_remaining = maxf(0.0, _coyote_remaining - delta)


func _refresh_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed(ACTION_JUMP):
		_jump_buffer_remaining = config.jump_buffer_time
		return
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)


# --- read-only diagnostics (used by the automated grapple tests) ------------

func is_coyote_available() -> bool:
	return _coyote_remaining > 0.0


func get_jump_buffer_remaining() -> float:
	return _jump_buffer_remaining


func is_hook_armed() -> bool:
	return _hook_armed


func get_grapple_creature() -> Node2D:
	return _creature


func get_grapple_candidate() -> Node2D:
	return _candidate


func get_anchor_position() -> Vector2:
	return _anchor


func get_rope_length() -> float:
	return _rope_length


func _create_audio_players() -> void:
	for key in ["jump", "steps", "landing", "launch", "attach", "miss", "release"]:
		var player := AudioStreamPlayer.new()
		player.name = "Audio_" + str(key)
		player.bus = "SFX"
		player.volume_db = -2.0
		add_child(player)
		_audio_players[key] = player
	var swing := AudioStreamPlayer.new()
	swing.name = "Audio_GrappleSwing"
	swing.bus = "Ambience"
	var swing_stream: AudioStreamWAV = SOUND_SWING.duplicate() as AudioStreamWAV
	swing_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	swing_stream.loop_end = int(swing_stream.get_length() * swing_stream.mix_rate)
	swing.stream = swing_stream
	swing.volume_db = -12.0
	add_child(swing)
	_audio_players["swing"] = swing


func _play_audio(key: String, stream: AudioStream) -> void:
	var player: AudioStreamPlayer = _audio_players.get(key) as AudioStreamPlayer
	if player == null:
		return
	player.stream = stream
	player.play()


func _update_movement_audio(was_on_floor: bool, landing_speed: float, old_x: float) -> void:
	if not was_on_floor and is_on_floor():
		visual_landing.emit(landing_speed)
		_play_audio("landing", SOUND_LAND_HEAVY if landing_speed >= LAND_HEAVY_SPEED else SOUND_LAND_SOFT)
		_step_distance = 0.0
	if is_on_floor() and not is_grappling and absf(Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)) > 0.1:
		_step_distance += absf(global_position.x - old_x)
		if _step_distance >= STEP_DISTANCE:
			_step_distance = fmod(_step_distance, STEP_DISTANCE)
			_step_alternate = not _step_alternate
			_play_audio("steps", SOUND_STEP_A if _step_alternate else SOUND_STEP_B)
	elif not is_on_floor():
		_step_distance = 0.0


func _update_swing_audio() -> void:
	var player: AudioStreamPlayer = _audio_players.get("swing") as AudioStreamPlayer
	if player == null:
		return
	if is_grappling and not _swing_audio_active:
		_swing_audio_active = true
		if _swing_fade != null and _swing_fade.is_running():
			_swing_fade.kill()
		if not player.playing:
			player.volume_db = -12.0
			player.play()
		_swing_fade = create_tween()
		_swing_fade.tween_property(player, "volume_db", 0.0, 0.18)
	elif not is_grappling and _swing_audio_active:
		_stop_swing_audio(false)


func _stop_swing_audio(immediate: bool) -> void:
	_swing_audio_active = false
	var player: AudioStreamPlayer = _audio_players.get("swing") as AudioStreamPlayer
	if player == null or not player.playing:
		return
	if _swing_fade != null and _swing_fade.is_running():
		_swing_fade.kill()
	if immediate:
		player.stop()
		return
	_swing_fade = create_tween()
	_swing_fade.tween_property(player, "volume_db", -40.0, 0.12)
	_swing_fade.tween_callback(player.stop)


func _exit_tree() -> void:
	_stop_swing_audio(true)
