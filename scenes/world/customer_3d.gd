extends Node3D
## A simple low-poly shopper (capsule body, sphere head) that walks a list of
## stops in straight lines. Visual only: the rules live in Game.state.customer.
## Clicking them is the same as clicking the counter.

const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")

const WALK_SPEED := 2.0
const SKIN_TONES := ["#f1c9a5", "#e0ac84", "#c68863", "#8d5a3b", "#fbdcc0"]
const SHIRTS := ["#d98a6a", "#74a99a", "#e0b84f", "#8fa3d6", "#b977b0", "#d96a6a", "#6fae6a", "#f0e6d2"]

## Arrived at a stop (its name); the route is finished (also fires after leaving).
signal arrived(stop: String)
signal route_done

var customer_name := ""
## True once they've been sent away (walking to the door, then they vanish).
var leaving := false

var _route: Array = []  # {"pos": Vector3, "stop": String, "pause": float, "face": Vector3 or null}
var _pause := 0.0
var _bob := 0.0
var _model: Node3D


func setup(p_name: String, seed_value: int) -> void:
	customer_name = p_name
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_model = Node3D.new()
	add_child(_model)
	# Legs, shirt, head.
	BuildUtil.box(_model, Vector3(0, 0.4, 0), Vector3(0.3, 0.8, 0.2), Color("#4a5568"))
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.24
	capsule.height = 0.78
	body.mesh = capsule
	body.material_override = BuildUtil.material(Color(SHIRTS[rng.randi() % SHIRTS.size()]))
	body.position = Vector3(0, 1.1, 0)
	_model.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	head.mesh = sphere
	head.material_override = BuildUtil.material(Color(SKIN_TONES[rng.randi() % SKIN_TONES.size()]))
	head.position = Vector3(0, 1.62, 0)
	_model.add_child(head)
	# A little nose so you can tell which way they face (towards -Z locally).
	BuildUtil.box(_model, Vector3(0, 1.62, -0.16), Vector3(0.05, 0.05, 0.06), Color(SKIN_TONES[0]).darkened(0.15))
	BuildUtil.label(self, customer_name, Vector3(0, 2.0, 0), 0.0035)
	var body_click := Interactable.new()
	body_click.setup("customer", "Click: Customer", Vector3(0, 0.95, 0), Vector3(0.6, 1.9, 0.6), "", 2)
	add_child(body_click)


## Replaces the route with these stops: [{"pos": Vector3, "stop": String, "pause": float}].
func go(stops: Array) -> void:
	_route = stops.duplicate()
	_pause = 0.0


## Walk to `door` and then disappear.
func leave(door: Vector3) -> void:
	leaving = true
	go([{"pos": door, "stop": "door", "pause": 0.0}])


## True while they have somewhere to go.
func is_walking() -> bool:
	return not _route.is_empty()


func _process(delta: float) -> void:
	if _route.is_empty():
		_model.position.y = 0.0
		return
	if _pause > 0.0:
		_pause -= delta
		return
	var step: Dictionary = _route[0]
	var to: Vector3 = step["pos"] - global_position
	to.y = 0.0
	var dist := to.length()
	var move := WALK_SPEED * delta
	if dist <= move:
		global_position = Vector3(step["pos"].x, global_position.y, step["pos"].z)
		_route.pop_front()
		_pause = float(step["pause"])
		if step.has("face"):
			_face(step["face"], true)
		_model.position.y = 0.0
		arrived.emit(step["stop"])
		if _route.is_empty():
			route_done.emit()
		return
	var dir := to / dist
	global_position += dir * move
	_face(dir)
	_bob += delta * 9.0
	_model.position.y = absf(sin(_bob)) * 0.04


## Turn (or snap) to look along a horizontal direction.
func _face(dir: Vector3, snap: bool = false) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target := atan2(-dir.x, -dir.z)  # -Z is "forward" for the model
	rotation.y = target if snap else lerp_angle(rotation.y, target, 0.25)
