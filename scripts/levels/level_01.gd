extends Node2D

# Level_01 owns the playable loop and nothing else: where the camera is allowed
# to go, where the player respawns, what a fall costs and what the exit does.
# Platform shapes live in the scene file, art lives in FloatIsland / Portal /
# LevelBackground, and the player's movement is left exactly as it is.
#
# Bench convention is kept from MovementTest.tscn: a platform's StaticBody2D sits
# at the centre of a 40 px thick rectangle, so a walking surface at y = T has its
# body at (centre_x, T + 20). The player uses a feet origin, so standing on that
# surface means player.y == T and its box spans x-6 .. x+6.
#
# Grapple geometry uses the same convention, plus the rope. The hook measures from
# the tie point on the body (14 px above the feet origin, see player.gd) to the
# creature's grapple point, so a creature can be caught from a ledge when that
# distance is under grapple_range (160). A swing then throws the player onward:
# with rope length L, release speed v and dy = how far the landing's tie height
# sits below the anchor, the landing is about
#     anchor_x + sqrt(L^2 - dy^2) * (1 + 2 * v^2 * dy / (900 * L^2))
# pixels along. The gaps were sized with that model over the whole patrol and bob
# range of each creature, and every grapple gap is longer than a run and jump can
# clear (a jump taken at max_speed covers about 100 px).
# Layout, take-off edge -> landing edge (landing surface in brackets). Four
# sections, each with its own shape, island palette and creature behaviour.
#   SECTION 1 LEARNING
#   StartHaven 340 wide, 0     -> Meadow    260 gap, level     creature 104 above, easy catch
#   Meadow     340 wide, 0     -> Terrace   280 gap, 22 up     wide stone landing, release timing
#   SECTION 2 SWINGING
#   Terrace    200 wide, -22   -> Aerie     200 gap, 18 down   jump-then-grapple, 16 px patrol
#   Aerie      180 wide, -40   -> Perch     240 gap, 15 up     swing under the RockGateA slab
#   Perch      160 wide, -25   -> RestLedge 285 gap, 40 down   creature moving away, thrown downhill
#   RestLedge 190 wide, 15 -> 3 ruin steps: 60 / 60 / 60 px hops, 15 up then 25 down twice
#   SECTION 3 CHAINING
#   StepThree   90 wide, -50   -> Nook      190 gap, 15 down   anchor that bobs 22 px
#   Nook       110 wide, -35   -> LowRest   210 gap, 75 down   low anchor, deep dive under Creature7
#   LowRest    130 wide, 40    -> Shelf     230 gap, 20 up     chain under the RockCeiling slab
#   SECTION 4 FINAL CHALLENGE
#   Shelf      130 wide, 20    -> NarrowA   320 gap, 30 up     creature patrolling towards the player
#   NarrowA    110 wide, -10   -> NarrowB   305 gap, 25 down   narrow platform, timed catch
#   NarrowB    100 wide, -35   -> ExitIsland 300 gap, 40 up    release near the top of the last arc
# Every grapple gap is out of reach of a run and jump (about 100 px); only the three
# ruin steps are meant to be hopped on foot. Each creature is placed so the hook can
# only be caught a little way past the take-off edge, which is where a swing starts
# properly. RockArch, RockGateA, RockCeiling and RockColumn are solid collision
# bodies: the gate and ceiling slabs cap the swing arcs above them and force the
# route underneath, and the islands themselves block the hook's line of sight, so
# there is no straight-line shortcut down the level. Exit portal at x 5360 on the
# final island. DeathPlane at y 175 spans the whole level. Camera limits are the
# level bounds, so the camera never reveals sky outside the playable strip.

const ACTION_RESTART := &"restart"

const LIMIT_LEFT: float = 0.0
const LIMIT_TOP: float = -300.0
const LIMIT_RIGHT: float = 5560.0
const LIMIT_BOTTOM: float = 200.0
const TUTORIAL_END_X: float = 760.0 ## past the first Sky Skimmer encounter

const HINT_SECONDS: float = 8.0 ## the control hint fades out after this much playing time

enum State { PLAYING, WON }

@export var respawn_position: Vector2 = Vector2(100.0, 0.0) ## inside the entrance portal ring

@onready var _player: Player = get_node("Player") as Player
@onready var _camera: Camera2D = get_node("Player/Camera2D") as Camera2D
@onready var _death_plane: Area2D = get_node("DeathPlane") as Area2D
@onready var _exit_area: Area2D = get_node("ExitPortal/Area2D") as Area2D
@onready var _victory: CanvasLayer = get_node("VictoryUI") as CanvasLayer
@onready var _time_label: Label = get_node("VictoryUI/Center/Box/TimeLabel") as Label
@onready var _restart_button: Button = get_node("VictoryUI/Center/Box/RestartButton") as Button
@onready var _hint: Label = get_node("HudLayer/Hint") as Label
@onready var _tutorial_ui: GrappleTutorial = get_node("GrappleTutorialSign") as GrappleTutorial

var _state: State = State.PLAYING
var _elapsed: float = 0.0
var _tutorial_completed: bool = false
var _controller_prompts: bool = false


func _ready() -> void:
	_camera.limit_left = LIMIT_LEFT
	_camera.limit_top = LIMIT_TOP
	_camera.limit_right = LIMIT_RIGHT
	_camera.limit_bottom = LIMIT_BOTTOM

	_death_plane.body_entered.connect(_on_death)
	_exit_area.body_entered.connect(_on_exit)
	_player.grapple_attached.connect(_on_first_grapple_attached)
	_restart_button.pressed.connect(_restart)
	_victory.visible = false
	_update_control_prompts()

	_respawn()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.is_pressed():
		_set_controller_prompts(true)
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.35:
		_set_controller_prompts(true)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		_set_controller_prompts(false)


func _set_controller_prompts(controller: bool) -> void:
	if _controller_prompts == controller:
		return
	_controller_prompts = controller
	_update_control_prompts()


func _update_control_prompts() -> void:
	if _hint == null or _tutorial_ui == null:
		return
	if _controller_prompts:
		_hint.text = "LEFT STICK — MOVE     A — JUMP     RT — HOLD TO GRAPPLE     MENU — RESTART"
		_tutorial_ui.set_controller_prompts(true)
	else:
		_hint.text = "A / D  move     SPACE  jump     E  grapple (hold)     R  restart"
		_tutorial_ui.set_controller_prompts(false)


func _process(delta: float) -> void:
	if _state == State.PLAYING:
		_elapsed += delta
		if not _tutorial_completed and _player.global_position.x >= TUTORIAL_END_X:
			_complete_tutorial_sign()
	if _hint.visible:
		if _elapsed > HINT_SECONDS:
			_hint.modulate.a = maxf(0.0, _hint.modulate.a - delta * 1.5)
			if _hint.modulate.a <= 0.0:
				_hint.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_RESTART):
		_restart()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()


func _restart() -> void:
	get_tree().call_deferred("reload_current_scene")


func _respawn() -> void:
	_state = State.PLAYING
	_elapsed = 0.0
	_victory.visible = false
	_hint.visible = true
	_hint.modulate.a = 1.0

	_player.set_physics_process(true)
	_player.velocity = Vector2.ZERO
	# A fall can end a swing mid-air. Dropping the rope here is all that is needed:
	# the controller rebuilds its hook search from scratch on the next tick, and the
	# coyote / jump-buffer windows are refilled by the grounded ticks after the respawn.
	_player.clear_grapple_state()
	_player.global_position = respawn_position


func _on_death(body: Node2D) -> void:
	if _state != State.PLAYING or body != _player:
		return
	_respawn()


func _on_exit(body: Node2D) -> void:
	if _state != State.PLAYING or body != _player:
		return
	_state = State.WON
	_player.velocity = Vector2.ZERO
	_player.clear_grapple_state()
	_player.set_physics_process(false)
	_time_label.text = "Time  %.1f s" % _elapsed
	_victory.visible = true


func _on_first_grapple_attached(_creature: Node2D) -> void:
	_complete_tutorial_sign()


func _complete_tutorial_sign() -> void:
	if _tutorial_completed:
		return
	_tutorial_completed = true
	_tutorial_ui.fade_out()
