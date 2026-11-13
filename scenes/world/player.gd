extends CharacterBody3D
## First-person walker: WASD / arrow keys, Space to jump, mouse look, gravity, and a ray that
## finds what you're pointing at. The world switches `active` off while a menu
## is open or the mouse is free.

const Interactable := preload("res://scenes/world/interactable.gd")

const SPEED := 3.4
const GRAVITY := 18.0
const JUMP_SPEED := 5.2  # about 0.75 m high
const MOUSE_SENSITIVITY := 0.0025
const REACH := 3.0
const EYE_HEIGHT := 1.6
const MAX_PITCH := 1.48  # about 85 degrees

## Movement and mouse look only work while this is true.
var active := false

var camera: Camera3D
var _ray: RayCast3D
var _pitch := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)
	camera = Camera3D.new()
	camera.position = Vector3(0, EYE_HEIGHT, 0)
	camera.fov = 75.0
	camera.near = 0.05
	add_child(camera)
	# Layer 1 = furniture and walls, layer 2 = people: the ray sees both.
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = 3
	camera.add_child(_ray)


## Put the player somewhere, looking along `yaw` (0 = towards -Z) and `pitch` (radians).
func place(pos: Vector3, yaw: float, pitch: float = 0.0) -> void:
	global_position = pos
	rotation.y = yaw
	_pitch = clampf(pitch, -MAX_PITCH, MAX_PITCH)
	camera.rotation.x = _pitch


func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH)
		camera.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if active:
		input.x = _axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT)
		input.y = _axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP)
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		velocity.y = JUMP_SPEED if active and Input.is_key_pressed(KEY_SPACE) else 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()


func _axis(key: Key, alt: Key) -> float:
	return 1.0 if Input.is_key_pressed(key) or Input.is_key_pressed(alt) else 0.0


## What the crosshair is on (an Interactable within reach), or null.
func look_target() -> Interactable:
	_ray.force_raycast_update()
	if _ray.is_colliding():
		var hit := _ray.get_collider()
		if hit is Interactable:
			return hit
	return null
