extends Node2D

@onready var player_body: CharacterBody2D = %PlayerBody
@onready var dash_timer: Timer = %DashTimer

enum PlayerState {NORMAL, DASH}
var curr_state := PlayerState.NORMAL

var velocity := Vector2.ZERO

const acceleration := 0.9
const max_velocity := 400.0

# Lower movement friction gives a longer glide.
@export_range(0.1, 20.0, 0.1) var movement_acceleration: float = 10.0
@export_range(0.1, 20.0, 0.1) var movement_friction: float = 10.0

var dash_dir := Vector2.ZERO
var last_move_dir := Vector2.RIGHT

var dash_time_left := 0.0

@export var dash_speed: float = 1500.0
@export_range(0.01, 1.0, 0.01) var dash_duration: float = 0.1

# Lower values keep extra dash speed longer.
@export_range(0.1, 30.0, 0.1) var dash_glide_friction: float = 6.0
const dash_scale := 100.0


func _ready() -> void:
	player_body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	dash_timer.one_shot = true
	dash_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("player_dash"):
		return
	if curr_state == PlayerState.DASH or not dash_timer.is_stopped():
		return

	var input_dir := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	# Follow actual momentum; opposing input can reverse the dash.
	if velocity.length_squared() >= 1.0:
		dash_dir = velocity.normalized()
		if not input_dir.is_zero_approx() and input_dir.dot(dash_dir) < 0.0:
			dash_dir = input_dir.normalized()
	elif not input_dir.is_zero_approx():
		dash_dir = input_dir.normalized()
	else:
		dash_dir = last_move_dir
	last_move_dir = dash_dir
	velocity = dash_dir * velocity.length()

	curr_state = PlayerState.DASH
	dash_time_left = dash_duration


func _process_normal(delta: float) -> void:
	var input_dir := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var target_velocity := input_dir * max_velocity
	var response: float = movement_friction if input_dir.is_zero_approx() else movement_acceleration

	# Fade extra dash speed separately from normal steering.
	var normal_velocity: Vector2 = velocity.limit_length(max_velocity)
	var extra_velocity: Vector2 = velocity - normal_velocity
	velocity = normal_velocity.lerp(target_velocity, 1.0 - exp(-response * delta)) \
		+ extra_velocity * exp(-dash_glide_friction * delta)
	if input_dir.is_zero_approx() and velocity.length_squared() < 1.0:
		velocity = Vector2.ZERO

	player_body.velocity = velocity
	player_body.move_and_slide()
	velocity = player_body.velocity
	if velocity.length_squared() >= 1.0:
		last_move_dir = velocity.normalized()


func _process_dash(delta: float) -> void:
	var step := minf(delta, dash_time_left)
	velocity = velocity.lerp(dash_dir * dash_speed,
		1.0 - exp(-acceleration * step * dash_scale))
	var collision := player_body.move_and_collide(velocity * step)

	dash_time_left = maxf(0.0, dash_time_left - step)
	# Stop dash momentum on a wall impact.
	if collision != null:
		velocity = Vector2.ZERO
	if collision != null or dash_time_left <= 0.000001:
		_finish_dash()


func _finish_dash() -> void:
	curr_state = PlayerState.NORMAL
	dash_time_left = 0.0
	# Preserve speed here so normal movement can ease it down.
	player_body.velocity = velocity

	dash_timer.start()


func _physics_process(delta: float) -> void:
	if curr_state == PlayerState.DASH:
		_process_dash(delta)
	else:
		_process_normal(delta)
