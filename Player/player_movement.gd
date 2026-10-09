extends Node2D

@onready var player_body := %PlayerBody
@onready var dash_timer := %DashTimer

enum player_states {NORMAL, DASH}
var NORMAL := player_states.NORMAL
var DASH := player_states.DASH 

var curr_state := NORMAL

# Parameters for NORMAL state
var velocity := Vector2.ZERO
const acceleration := 0.7
const acceleration_scale := 40.0
const max_velocity := 300

# Parameters for DASH state
var mouse_dir := Vector2.ZERO
var dash_speed := 1500
const dash_scale := 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player_dash"):
		if dash_timer.is_stopped():
			# Get mouse direction vector on input press so it locks into that direction
			mouse_dir = player_body.global_position.direction_to(get_global_mouse_position())
			curr_state = DASH
			await get_tree().create_timer(0.25).timeout
			dash_timer.start()
			curr_state = NORMAL
		else:
			print("On cooldown. ", snappedf(dash_timer.time_left, 0.1), " seconds left.")


func _process_normal(delta: float) -> void:
	# Get movement direction vector
	var input_dir := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	if input_dir != Vector2.ZERO:
		# Project max velocity in that direction
		var target_velocity := input_dir * max_velocity
		velocity = lerp(velocity, target_velocity, 
		1.0 - exp(-acceleration * delta * acceleration_scale))
	else:
		velocity = lerp(velocity, Vector2.ZERO, 
		1.0 - exp(-acceleration * delta * acceleration_scale))
	player_body.position += velocity * delta


func _process_dash(delta: float) -> void:
	var target_velocity := mouse_dir * dash_speed
	velocity = lerp(velocity, target_velocity, 
	1.0 - exp(-acceleration * delta * dash_scale))
	player_body.position += velocity * delta


func _physics_process(delta: float) -> void:
	if curr_state == NORMAL:
		_process_normal(delta)
	elif  curr_state == DASH:
		_process_dash(delta)
		
	
	
	
