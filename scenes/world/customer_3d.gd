extends Node3D
## A shopper from the Synty Polygon Shops character set that walks a list of stops in
## straight lines, animated with Synty's own clips (see synty_anims.gd): a walk cycle,
## a standing idle, looking things over at the shelf or tank, checking a watch or tapping
## a foot while they wait at the counter, and a nod of thanks on the way out. Visual
## only: the rules live in Game.state.customer. Clicking them is the same as clicking
## the counter.

const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")
const Synty := preload("res://scenes/world/synty.gd")
const SyntyAnims := preload("res://scenes/world/synty_anims.gd")

const WALK_SPEED := 1.35
## Seconds between fidgets (checking a watch, tapping a foot) while waiting at the counter.
const FIDGET_EVERY := Vector2(5.0, 10.0)
## How long the nod of thanks plays before they turn for the door.
const THANKS_TIME := 1.1
const PEOPLE := [
	"Characters/Characters/SM_Chr_Shopper_Female_01", "Characters/Characters/SM_Chr_Shopper_Male_01",
	"Characters/Characters/SM_Chr_Gym_Female_01", "Characters/Characters/SM_Chr_Gym_Male_01",
	"Characters/Characters/SM_Chr_Musician_Female_01", "Characters/Characters/SM_Chr_Musician_Male_01",
	"Characters/Characters/SM_Chr_Hunter_Male_01", "Characters/Characters/SM_Chr_Worker_Female_01",
	"Characters/Characters/SM_Chr_Worker_Male_01", "Characters/Characters/SM_Chr_Attendant_Female_01",
	"Characters/Characters/SM_Chr_Attendant_Male_01",
]
const ARM_DROP := 0.12  # how far the hanging arms lean out from the body
const SWING := 0.55  # radians of leg swing at full stride

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
var _skeleton: Skeleton3D
var _rest_global := {}  # bone name -> Basis of the bone in the skeleton's rest pose
var _stride := 0.0  # 0 standing, 1 walking
var _anim: AnimationPlayer
var _clip := ""
var _fidget := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_name: String, seed_value: int) -> void:
	customer_name = p_name
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_model = Node3D.new()
	_model.rotation.y = PI  # the models face +Z; people here walk towards -Z
	add_child(_model)
	var who: String = PEOPLE[rng.randi() % PEOPLE.size()]
	var person := Synty.make(who)
	_rng.seed = seed_value + 7
	_model.add_child(person)
	_skeleton = person.find_child("GeneralSkeleton", true, false)
	if _skeleton != null:
		for part in _skeleton.get_children():  # the prefab leaves its skinned meshes unbound
			if part is MeshInstance3D and (part as MeshInstance3D).skin != null:
				(part as MeshInstance3D).skeleton = NodePath("..")
		_anim = SyntyAnims.attach(_skeleton, who.contains("Female"))
		if _anim.has_animation("walk"):
			_play("idle")
		else:  # no animation files: fall back to the hand-made swing
			_anim.queue_free()
			_anim = null
			_cache_rest()
			_pose(0.0)
		_fidget = _rng.randf_range(FIDGET_EVERY.x, FIDGET_EVERY.y)
	BuildUtil.label(self, customer_name, Vector3(0, 2.15, 0), 0.0035)
	var body_click := Interactable.new()
	body_click.setup("customer", "Click: Customer", Vector3(0, 0.95, 0), Vector3(0.6, 1.9, 0.6), "", 2)
	add_child(body_click)


func _cache_rest() -> void:
	for bone in ["LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerArm", "RightLowerArm"]:
		var i := _skeleton.find_bone(bone)
		if i >= 0:
			_rest_global[bone] = _skeleton.get_bone_global_rest(i).basis


## Hang the arms and swing arms and legs by `swing` (radians, opposite sides opposite ways).
func _pose(swing: float) -> void:
	for side in [-1.0, 1.0]:
		var prefix := "Left" if side > 0.0 else "Right"
		_turn(prefix + "UpperLeg", Basis(Vector3.RIGHT, swing * side))
		var down := Basis(Quaternion(_arm_direction(prefix), Vector3(side * ARM_DROP, -1.0, 0.0).normalized()))
		_turn(prefix + "UpperArm", Basis(Vector3.RIGHT, -swing * 0.8 * side) * down)


## Which way a rest-pose arm points (from shoulder joint to elbow).
func _arm_direction(prefix: String) -> Vector3:
	var upper := _skeleton.find_bone(prefix + "UpperArm")
	var lower := _skeleton.find_bone(prefix + "LowerArm")
	return (_skeleton.get_bone_global_rest(lower).origin - _skeleton.get_bone_global_rest(upper).origin).normalized()


## Turn a bone by `rot` in skeleton space, starting from its rest orientation.
func _turn(bone: String, rot: Basis) -> void:
	var i := _skeleton.find_bone(bone)
	if i < 0 or not _rest_global.has(bone):
		return
	var parent := _skeleton.get_bone_parent(i)
	var parent_basis := _skeleton.get_bone_global_rest(parent).basis
	var local := parent_basis.inverse() * (rot * (_rest_global[bone] as Basis))
	_skeleton.set_bone_pose_rotation(i, local.get_rotation_quaternion())


## Replaces the route with these stops: [{"pos": Vector3, "stop": String, "pause": float}].
func go(stops: Array) -> void:
	_route = stops.duplicate()
	_pause = 0.0


## Walk to `door` and then disappear.
func leave(door: Vector3) -> void:
	leaving = true
	go([{"pos": door, "stop": "door", "pause": 0.0}])
	if _anim != null:  # a nod of thanks first
		_play("thanks")
		_pause = THANKS_TIME


## True while they have somewhere to go.
func is_walking() -> bool:
	return not _route.is_empty()


func _process(delta: float) -> void:
	if _route.is_empty() or _pause > 0.0:
		_pause = maxf(_pause - delta, 0.0)
		_stride = move_toward(_stride, 0.0, delta * 4.0)
		_animate()
		_idle(delta)
		if _route.is_empty():
			return
		if _pause > 0.0:
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
		_stride = 0.0
		if _anim != null:
			# Look things over at the shelf or the tank; otherwise just stand.
			_play("inspect" if _pause > 0.0 and step["stop"] in ["shelf", "display", "goldfish"] else "idle")
		arrived.emit(step["stop"])
		if _route.is_empty():
			route_done.emit()
		return
	var dir := to / dist
	global_position += dir * move
	_face(dir)
	_bob += delta * 7.0
	_stride = move_toward(_stride, 1.0, delta * 5.0)
	_animate()


## Turn (or snap) to look along a horizontal direction.
func _face(dir: Vector3, snap: bool = false) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target := atan2(-dir.x, -dir.z)  # -Z is "forward" for the model
	rotation.y = target if snap else lerp_angle(rotation.y, target, 0.25)


## Standing still: back to the idle once a one-off clip ends, and now and then a fidget
## while waiting at the end of the route (the counter).
func _idle(delta: float) -> void:
	if _anim == null:
		return
	if _clip != "idle" and _clip != "walk" and not _anim.is_playing():
		_play("idle")
	if _route.is_empty() and not leaving:
		_fidget -= delta
		if _fidget <= 0.0:
			_fidget = _rng.randf_range(FIDGET_EVERY.x, FIDGET_EVERY.y)
			if _clip == "idle":
				_play("check_watch" if _rng.randf() < 0.5 else "foot_tap")


func _play(clip: String) -> void:
	if _anim == null or clip == _clip or not _anim.has_animation(clip):
		return
	_clip = clip
	_anim.play(clip, 0.25)


func _animate() -> void:
	if _skeleton == null:
		return
	if _anim != null:
		if _stride > 0.5:
			_play("walk")
		return
	_pose(sin(_bob) * SWING * _stride)
	_model.position.y = absf(sin(_bob)) * 0.02 * _stride
