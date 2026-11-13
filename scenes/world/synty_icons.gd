extends RefCounted
## Pictures of Synty models for the 2D menus, so no menu shows drawn art. Each picture is a
## one-off render of the model in its own little 3D world (a SubViewport kept under the
## scene root); the result is an ordinary texture that can go in a TextureRect.
## Pictures are cached by what they show, so a menu full of guppies renders one per colour.

const Synty := preload("res://scenes/world/synty.gd")
const Customer3D := preload("res://scenes/world/customer_3d.gd")

static var _holder: Node
static var _cache := {}


## The side view of a fish in `color`, facing right.
static func fish(color: Color) -> Texture2D:
	var key := "fish:" + color.to_html()
	if _cache.has(key):
		return _cache[key]
	return _render(key, Vector2i(192, 96), func(): return Synty.fish(color), Vector3(1, 0, 0), 0.0, 1.12)


## A Synty model (path as in Synty.make, optionally tinted) seen from a little above and to the side.
static func model(rel: String, size: Vector2i = Vector2i(128, 128)) -> Texture2D:
	var key := "model:" + rel
	if _cache.has(key):
		return _cache[key]
	return _render(key, size, func(): return Synty.make(rel), Vector3(0.55, 0, 0.83), 0.35, 1.2)


## A head-and-shoulders portrait of one of the shop's people, picked by `seed_value`.
static func person(person_name: String, seed_value: int) -> Texture2D:
	var key := "person:%s:%d" % [person_name, seed_value]
	if _cache.has(key):
		return _cache[key]
	var maker := func():
		var who := Customer3D.new()
		who.setup(person_name, seed_value)
		return who
	return _render(key, Vector2i(128, 128), maker, Vector3(0, 0, -1), 0.0, 1.0, Vector3(0, 1.5, 0), 0.62)


static func _render(key: String, size: Vector2i, make: Callable, view_dir: Vector3, pitch: float, margin: float,
		focus: Variant = null, fixed_height: float = 0.0) -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1d8")
	env.ambient_light_energy = 0.85
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_energy = 0.8
	viewport.add_child(sun)
	var model_node: Node3D = make.call()
	viewport.add_child(model_node)
	var b := Synty.bounds(model_node)
	var centre: Vector3 = focus if focus != null else b.get_center()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var aspect := float(size.x) / float(size.y)
	# `size` of an orthogonal camera is its height (keep-height); widen it if the model is wider.
	var wanted := maxf(b.size.y, maxf(b.size.x, b.size.z) / aspect) * margin
	camera.size = fixed_height if fixed_height > 0.0 else maxf(wanted, 0.05)
	var flat := view_dir.normalized()
	var dir := Vector3(flat.x, tan(pitch), flat.z).normalized()
	camera.transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), centre + dir * 6.0)
	viewport.add_child(camera)
	_root().add_child(viewport)
	_cache[key] = viewport.get_texture()
	return _cache[key]


static func _root() -> Node:
	if _holder == null or not is_instance_valid(_holder):
		_holder = Node.new()
		_holder.name = "SyntyIcons"
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_holder)
	return _holder
