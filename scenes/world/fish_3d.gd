extends Node3D
## One fish swimming slowly back and forth inside a 3D tank: a billboard
## Sprite3D cut from the species' sprite sheet (see fish_art.gd). Fry are
## smaller. Position is in the tank's local space, kept inside `bounds`.

const FishArt := preload("res://scenes/world/fish_art.gd")
const UI := preload("res://scenes/ui/ui_kit.gd")
## Metres per sprite pixel (a guppy is about 20 cm long).
const PIXEL_SIZE := 0.003
const SPEED_RANGE := Vector2(0.07, 0.17)

var fish: Fish
var species: Dictionary
var bounds := AABB(Vector3(-0.4, 0.1, -0.2), Vector3(0.8, 0.4, 0.4))

var _sprite: Sprite3D
var _fallback: MeshInstance3D
var _target := Vector3.ZERO
var _speed := 0.1
var _rest := 0.0
var _facing_right := true
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: Fish, p_species: Dictionary, p_bounds: AABB) -> void:
	fish = p_fish
	species = p_species
	bounds = p_bounds
	_rng.seed = fish.id * 7919 + 13
	_time = _rng.randf() * 10.0
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_sprite.region_enabled = true
	add_child(_sprite)
	position = _random_point()
	_pick_target()
	_update_frame()


## A new tank size (or a grown fish): keep the fish inside it.
func set_bounds(p_bounds: AABB) -> void:
	bounds = p_bounds
	position = position.clamp(bounds.position, bounds.end)


func _random_point() -> Vector3:
	return Vector3(_rng.randf_range(bounds.position.x, bounds.end.x),
		_rng.randf_range(bounds.position.y, bounds.end.y),
		_rng.randf_range(bounds.position.z, bounds.end.z))


func _pick_target() -> void:
	_target = _random_point()
	_target.y = lerpf(position.y, _target.y, 0.4)  # mostly sideways, gentle up and down
	_speed = _rng.randf_range(SPEED_RANGE.x, SPEED_RANGE.y)


func _process(delta: float) -> void:
	_time += delta
	if _rest > 0.0:
		_rest -= delta
		if _rest <= 0.0:
			_pick_target()
	else:
		var to := _target - position
		if to.length() < 0.03:
			_rest = _rng.randf_range(0.4, 2.0)
		else:
			position += to.normalized() * _speed * delta
			if absf(to.x) > 0.02:
				_facing_right = to.x > 0.0
	_update_frame()


func _update_frame() -> void:
	var art := FishArt.frame(fish, species, _facing_right, _rest <= 0.0, _time)
	var growth := FishArt.growth(fish, species)
	if art.is_empty():
		_show_fallback(growth)
		return
	var rect: Rect2 = art["rect"]
	_sprite.texture = UI.sheet_texture(art["sheet"])
	_sprite.region_rect = rect
	_sprite.flip_h = art["flip"]
	_sprite.pixel_size = PIXEL_SIZE * float(art["scale"]) * growth
	_sprite.modulate = art["tint"]
	_sprite.modulate.a = lerpf(0.8, 1.0, growth)


## Species without a sprite sheet: a little coloured oval.
func _show_fallback(growth: float) -> void:
	if _fallback == null:
		_fallback = MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.04
		mesh.height = 0.08
		_fallback.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(species.get("palette", {}).get(fish.get_trait("body_color"), "#cccccc"))
		_fallback.material_override = mat
		add_child(_fallback)
	_fallback.scale = Vector3(1.6, 1.0, 0.7) * growth
