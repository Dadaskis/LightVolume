extends CharacterBody3D

const SENSITIVITY = 0.3
const X_CLAMP_ANGLE = 90.0
const NORMAL_VELOCITY = 2.0
const FAST_VELOCITY = 5.0

@onready var x_rot = $x_rot
@onready var y_rot = $x_rot/y_rot
@onready var camera = $x_rot/y_rot/camera

var fly_velocity: = Vector3.ZERO
var mouse_cursor_moved: = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	LightVolume3DCamera.set_camera(camera)

func process_movement(delta: float):
	var velocity_target: = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		velocity_target += Vector3(0.0, 0.0, 1.0)
	if Input.is_action_pressed("move_back"):
		velocity_target += Vector3(0.0, 0.0, -1.0)
	if Input.is_action_pressed("move_left"):
		velocity_target += Vector3(-1.0, 0.0, 0.0)
	if Input.is_action_pressed("move_right"):
		velocity_target += Vector3(1.0, 0.0, 0.0)
	if Input.is_action_pressed("move_up"):
		velocity_target += Vector3(0.0, 1.0, 0.0)
	if Input.is_action_pressed("move_down"):
		velocity_target += Vector3(0.0, -1.0, 0.0)
	velocity_target = velocity_target.normalized()
	
	var aim_dir = y_rot.global_transform.basis
	
	var forward = -aim_dir.z
	var right = aim_dir.x
	var up = Vector3.UP
	
	var move_dir_rel = forward * velocity_target.z
	move_dir_rel += right * velocity_target.x
	move_dir_rel += up * velocity_target.y
	move_dir_rel = move_dir_rel.normalized()
	
	if Input.is_action_pressed("move_fast"):
		move_dir_rel *= FAST_VELOCITY
	else:
		move_dir_rel *= NORMAL_VELOCITY
	
	fly_velocity = lerp(fly_velocity, move_dir_rel, 5.0 * delta)
	
	set_velocity(fly_velocity)
	move_and_slide()

func process_mouse_move(delta: float) -> void:
	mouse_cursor_moved *= SENSITIVITY
	mouse_cursor_moved *= delta
	
	x_rot.rotate_y(-mouse_cursor_moved.x)
	y_rot.rotate_x(-mouse_cursor_moved.y)
	y_rot.rotation_degrees.x = clamp(
		y_rot.rotation_degrees.x,
		 -X_CLAMP_ANGLE, 
		X_CLAMP_ANGLE
	)
	
	mouse_cursor_moved = Vector2.ZERO

func _physics_process(delta: float) -> void:
	process_movement(delta)
	process_mouse_move(delta)

func add_mouse_rotation(mouse_relative: Vector2) -> void:
	mouse_cursor_moved += mouse_relative

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		add_mouse_rotation(event.relative)
