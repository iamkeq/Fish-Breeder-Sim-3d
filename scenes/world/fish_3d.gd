extends Node3D
## One fish swimming slowly back and forth inside a 3D tank: the Synty fish model,
## coloured by its variety. Fry are smaller. Position is in the tank's local space,
## kept inside `bounds`.

const Synty := preload("res://scenes/world/synty.gd")
const BuildUtil := preload("res://scenes/world/build_util.gd")
## Size of an adult fish relative to the model (a guppy is about 20 cm; the model is 17 cm).
const ADULT_SCALE := 1.15
const SPEED_RANGE := Vector2(0.07, 0.17)
## Body colour per guppy variety. Anything not listed gets a colour made from its name.
const VARIETY_COLORS := {
	"normal": "#b9b2a0", "red": "#e0453a", "blue": "#3b6fd1", "yellow": "#f2cf3d", "black": "#2b2b30",
	"white": "#f4f1ea", "grass": "#6fae5a", "orange": "#f08a2e", "purple": "#8a52c9", "pink": "#f08fb8",
	"turquoise": "#3cc7c0", "gold": "#e5b72e", "sunset": "#f26a3d", "pastel": "#f7d6dc", "half_black": "#5a4a52",
	"tuxedo": "#35353d", "dalmatian": "#d9d6cf", "koi": "#f2a45a", "leopard": "#d9a441", "snakeskin": "#8fa05a",
	"mosaic": "#6a8fc0", "neon": "#3df0d8", "albino": "#fbf3e6", "glass": "#cfeaf2", "lavender": "#b79be0",
	"platinum": "#d8dbe2", "galaxy": "#4a3aa8", "dragon": "#c2352e", "phoenix": "#f5883a", "calico": "#e6b98d",
	"midnight": "#23265c", "opal": "#bfe3d6", "tiger": "#e89a2f",
}

var fish: Fish
var species: Dictionary
var bounds := AABB(Vector3(-0.4, 0.1, -0.2), Vector3(0.8, 0.4, 0.4))

var _model: Node3D
## A little symbol over the fish while a food buff is on it (see set_buff).
var _buff: Label3D
var _target := Vector3.ZERO
var _speed := 0.1
var _rest := 0.0
var _facing_right := true
var _yaw := -PI * 0.5
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: Fish, p_species: Dictionary, p_bounds: AABB) -> void:
	fish = p_fish
	species = p_species
	bounds = p_bounds
	_rng.seed = fish.id * 7919 + 13
	_time = _rng.randf() * 10.0
	_model = Synty.fish(_body_color())
	add_child(_model)
	position = _random_point()
	_pick_target()
	_update_frame()


## Shows a symbol above the fish for its food buff ("heart" = spawning pellets,
## "arm" = growth flakes); "" removes it.
func set_buff(icon: String) -> void:
	if icon == "":
		if _buff != null:
			_buff.queue_free()
			_buff = null
		return
	if _buff == null:
		_buff = BuildUtil.label(self, "", Vector3(0, 0.13, 0), 0.0016)
		_buff.no_depth_test = true
	_buff.text = "♥" if icon == "heart" else "▲"
	_buff.modulate = Color("#ff6f91") if icon == "heart" else Color("#ffd24d")


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
	var growth := lerpf(0.4, 1.0, clampf(float(fish.age_days) / float(species.get("days_to_adult", 1)), 0.0, 1.0))
	_model.scale = Vector3.ONE * ADULT_SCALE * growth
	# The model's nose points to -Z: -90 degrees faces right (+X), +90 faces left.
	_yaw = lerp_angle(_yaw, -PI * 0.5 if _facing_right else PI * 0.5, 0.12)
	_model.rotation.y = _yaw
	# A gentle wiggle while swimming.
	_model.rotation.z = sin(_time * 9.0) * 0.06 if _rest <= 0.0 else 0.0


## The variety's colour (see VARIETY_COLORS), or one made from its name.
func _body_color() -> Color:
	return color_for(fish, species)


static func color_for(p_fish: Fish, p_species: Dictionary) -> Color:
	var data: Dictionary = p_species.get("sprites", {})
	var look := String(p_fish.get_trait(data.get("trait", "variety")))
	if VARIETY_COLORS.has(look):
		return Color(VARIETY_COLORS[look])
	var palette: Dictionary = p_species.get("palette", {})
	var from_palette := String(palette.get(String(p_fish.get_trait("body_color")), ""))
	if from_palette != "":
		return Color(from_palette)
	return Color.from_hsv(float(absi(look.hash()) % 360) / 360.0, 0.55, 0.9)
