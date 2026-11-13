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
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const WIND_AMBIENCE: AudioStream = preload("res://assets/audio/sfx/stratos_v1/loops/floating_island_wind_loop.wav")
const SOUND_RESPAWN: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/player_respawn.wav")
const SOUND_COMPLETE: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/level_complete.wav")

const LIMIT_LEFT: float = 0.0
const LIMIT_TOP: float = -300.0
const LIMIT_RIGHT: float = 5560.0
const LIMIT_BOTTOM: float = 200.0
const TUTORIAL_END_X: float = 760.0 ## past the first Sky Skimmer encounter

const HINT_SECONDS: float = 8.0 ## completed control summary stays visible this long

enum State { PLAYING, WON }
enum TutorialStep { MOVE, JUMP, GRAPPLE, RELEASE, COMPLETE }

@export var respawn_position: Vector2 = Vector2(100.0, 0.0) ## inside the entrance portal ring

@onready var _player: Player = get_node("Player") as Player
@onready var _camera: Camera2D = get_node("Player/Camera2D") as Camera2D
@onready var _death_plane: Area2D = get_node("DeathPlane") as Area2D
@onready var _exit_area: Area2D = get_node("Portales/ExitPortal/Area2D") as Area2D
@onready var _victory: CanvasLayer = get_node("VictoryUI") as CanvasLayer
@onready var _time_label: Label = get_node("VictoryUI/Center/Box/TimeLabel") as Label
@onready var _restart_button: Button = get_node("VictoryUI/Center/Box/RestartButton") as Button
@onready var _hint: Label = get_node("HudLayer/Hint") as Label
@onready var _tutorial_ui: GrappleTutorial = get_node("GrappleTutorialSign") as GrappleTutorial
@onready var _coin_count_label: Label = get_node("HudLayer/CollectiblesPanel/Counters/CoinCounter/CoinCount") as Label
@onready var _special_count_label: Label = get_node("HudLayer/CollectiblesPanel/Counters/SpecialCounter/SpecialCoinCount") as Label

var _state: State = State.PLAYING
var _elapsed: float = 0.0
var _tutorial_completed: bool = false
var _tutorial_step: TutorialStep = TutorialStep.MOVE
var _hint_elapsed: float = 0.0
var _controller_prompts: bool = false
var _coin_count: int = 0
var _special_coin_count: int = 0
var _wind_audio: AudioStreamPlayer = null
var _level_audio: AudioStreamPlayer = null
var _wind_fade: Tween = null


func _ready() -> void:
	add_to_group("collectible_tracker")
	_camera.limit_left = LIMIT_LEFT
	_camera.limit_top = LIMIT_TOP
	_camera.limit_right = LIMIT_RIGHT
	_camera.limit_bottom = LIMIT_BOTTOM

	_death_plane.body_entered.connect(_on_death)
	_exit_area.body_entered.connect(_on_exit)
	_player.visual_jump.connect(_on_tutorial_jump)
	_player.grapple_attached.connect(_on_first_grapple_attached)
	_player.grapple_released.connect(_on_first_grapple_released)
	_restart_button.pressed.connect(_restart)
	_setup_level_audio()
	_victory.visible = false
	_update_collectible_hud()
	_configure_control_hint()
	_update_control_prompts()

	_respawn()


func add_coins(amount: int) -> void:
	_coin_count += maxi(0, amount)
	_update_collectible_hud()


func add_special_collectibles(amount: int) -> void:
	_special_coin_count += maxi(0, amount)
	_update_collectible_hud()


func _update_collectible_hud() -> void:
	_coin_count_label.text = "× %03d" % _coin_count
	_special_count_label.text = "× %03d" % _special_coin_count


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.is_pressed():
		_set_controller_prompts(true)
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.35:
		_set_controller_prompts(true)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		_set_controller_prompts(false)

	if _tutorial_step == TutorialStep.MOVE and (
		event.is_action_pressed(ACTION_MOVE_LEFT)
		or event.is_action_pressed(ACTION_MOVE_RIGHT)
	):
		_set_tutorial_step(TutorialStep.JUMP)


func _set_controller_prompts(controller: bool) -> void:
	if _controller_prompts == controller:
		return
	_controller_prompts = controller
	_update_control_prompts()


func _update_control_prompts() -> void:
	if _hint == null or _tutorial_ui == null:
		return
	if _controller_prompts:
		match _tutorial_step:
			TutorialStep.MOVE:
				_hint.text = "1/4  MOVE  •  LEFT STICK OR D-PAD"
			TutorialStep.JUMP:
				_hint.text = "2/4  JUMP  •  A"
			TutorialStep.GRAPPLE:
				_hint.text = "3/4  HOLD RT NEAR A GLOWING SKY SKIMMER"
			TutorialStep.RELEASE:
				_hint.text = "4/4  RELEASE RT TO KEEP YOUR MOMENTUM"
			TutorialStep.COMPLETE:
				_hint.text = "LEFT STICK MOVE   A JUMP   HOLD RT GRAPPLE   RELEASE TO SWING   MENU RESTART"
		_tutorial_ui.set_controller_prompts(true)
	else:
		match _tutorial_step:
			TutorialStep.MOVE:
				_hint.text = "1/4  MOVE  •  A / D OR ARROWS"
			TutorialStep.JUMP:
				_hint.text = "2/4  JUMP  •  SPACE"
			TutorialStep.GRAPPLE:
				_hint.text = "3/4  HOLD E NEAR A GLOWING SKY SKIMMER"
			TutorialStep.RELEASE:
				_hint.text = "4/4  RELEASE E TO KEEP YOUR MOMENTUM"
			TutorialStep.COMPLETE:
				_hint.text = "A / D MOVE   SPACE JUMP   HOLD E GRAPPLE   RELEASE TO SWING   R RESTART"
		_tutorial_ui.set_controller_prompts(false)


func _configure_control_hint() -> void:
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.offset_top = -24.0
	_hint.offset_bottom = -8.0
	_hint.clip_text = true
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.add_theme_font_size_override("font_size", 10)


func _set_tutorial_step(step: TutorialStep) -> void:
	if _tutorial_step == step:
		return
	_tutorial_step = step
	_hint_elapsed = 0.0
	_hint.visible = true
	_hint.modulate.a = 1.0
	_update_control_prompts()


func _process(delta: float) -> void:
	if _state == State.PLAYING:
		_elapsed += delta
		if not _tutorial_completed and not _player.is_grappling and _player.global_position.x >= TUTORIAL_END_X:
			_complete_tutorial_sign()
	if _tutorial_step == TutorialStep.COMPLETE and _hint.visible:
		_hint_elapsed += delta
		if _hint_elapsed > HINT_SECONDS:
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
	if _tutorial_step == TutorialStep.RELEASE:
		_set_tutorial_step(TutorialStep.GRAPPLE)
	_victory.visible = false
	_hint.visible = _tutorial_step != TutorialStep.COMPLETE or _hint_elapsed < HINT_SECONDS
	_hint.modulate.a = 1.0

	_player.set_physics_process(true)
	_player.velocity = Vector2.ZERO
	# A fall can end a swing mid-air. Dropping the rope here is all that is needed:
	# the controller rebuilds its hook search from scratch on the next tick, and the
	# coyote / jump-buffer windows are refilled by the grounded ticks after the respawn.
	_player.clear_grapple_state()
	_player.global_position = respawn_position
	if _level_audio != null:
		_level_audio.stream = SOUND_RESPAWN
		_level_audio.play()


func _on_death(body: Node2D) -> void:
	if _state != State.PLAYING or body != _player:
		return
	_respawn()


func _on_exit(body: Node2D) -> void:
	if _state != State.PLAYING or body != _player:
		return
	_state = State.WON
	if _level_audio != null:
		_level_audio.stream = SOUND_COMPLETE
		_level_audio.play()
	if _wind_audio != null:
		if _wind_fade != null and _wind_fade.is_running():
			_wind_fade.kill()
		_wind_fade = create_tween()
		_wind_fade.tween_property(_wind_audio, "volume_db", -40.0, 0.2)
		_wind_fade.tween_callback(_wind_audio.stop)
	_player.velocity = Vector2.ZERO
	_player.clear_grapple_state()
	_player.set_physics_process(false)
	_time_label.text = "Time  %.1f s" % _elapsed
	_victory.visible = true


func _on_tutorial_jump() -> void:
	if _tutorial_step == TutorialStep.MOVE or _tutorial_step == TutorialStep.JUMP:
		_set_tutorial_step(TutorialStep.GRAPPLE)


func _on_first_grapple_attached(_creature: Node2D) -> void:
	if _tutorial_step != TutorialStep.COMPLETE:
		_set_tutorial_step(TutorialStep.RELEASE)


func _on_first_grapple_released(_creature: Node2D) -> void:
	if _tutorial_step == TutorialStep.COMPLETE:
		return
	_complete_tutorial_sign()
	_set_tutorial_step(TutorialStep.COMPLETE)


func _complete_tutorial_sign() -> void:
	if _tutorial_completed:
		return
	_tutorial_completed = true
	_tutorial_ui.fade_out()


func _setup_level_audio() -> void:
	_level_audio = AudioStreamPlayer.new()
	_level_audio.name = "LevelOneShotAudio"
	_level_audio.bus = "SFX"
	_level_audio.volume_db = -2.0
	add_child(_level_audio)
	_wind_audio = AudioStreamPlayer.new()
	_wind_audio.name = "FloatingIslandWind"
	_wind_audio.bus = "Ambience"
	var wind_stream: AudioStreamWAV = WIND_AMBIENCE.duplicate() as AudioStreamWAV
	wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind_stream.loop_end = int(wind_stream.get_length() * wind_stream.mix_rate)
	_wind_audio.stream = wind_stream
	_wind_audio.volume_db = -12.0
	add_child(_wind_audio)
	_wind_audio.play()
	_wind_fade = create_tween()
	_wind_fade.tween_property(_wind_audio, "volume_db", 0.0, 0.3)
