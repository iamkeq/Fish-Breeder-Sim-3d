extends Node3D
## The goldfish tank on the shop floor: a small tank of plain goldfish, one
## swimming fish per goldfish (up to MAX_SHOWN), drawn with the look from
## economy goldfish_tank.look (a gold guppy sprite for now), with a price sign. Clicking it
## opens the Market, where it's restocked. Mirrors Game.state.goldfish.

const Tank3D := preload("res://scenes/world/tank_3d.gd")
const Fish3D := preload("res://scenes/world/fish_3d.gd")
const Synty := preload("res://scenes/world/synty.gd")
const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")

const SIZE := Vector3(1.0, 0.5, 0.5)
## More than this many fish would just be a crowd: the rest are "in the back".
const MAX_SHOWN := 12
const GOLD := "#f08a2e"
## Used if the game data gives the goldfish no look: the plain Synty fish model.
const PLAIN_SPECIES := {"id": "goldfish", "name": "Goldfish", "days_to_adult": 1, "sprites": {}}

var _swimmers: Array[Node3D] = []
var _sign: Node3D
var _bounds: AABB
var _shown := -1


func _ready() -> void:
	var sx := SIZE.x / Tank3D.MODEL_GLASS_WIDTH
	var sz := SIZE.z / Tank3D.MODEL_GLASS_DEPTH
	var sy := clampf(minf(sx, sz), 0.8, 1.15)
	var model := Synty.office_tank()
	model.scale = Vector3(sx, sy, sz)
	add_child(model)
	var bottom := Tank3D.MODEL_GLASS_BOTTOM * sy
	var height := Tank3D.MODEL_GLASS_HEIGHT * sy
	# A pale gravel floor.
	var gravel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(SIZE.x - 0.06, 0.05, SIZE.z - 0.06)
	gravel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#d9c9a3")
	mat.roughness = 1.0
	gravel.material_override = mat
	gravel.position = Vector3(0, bottom + 0.025, 0)
	add_child(gravel)
	var hx := SIZE.x * 0.5 - 0.12
	var hz := SIZE.z * 0.5 - 0.1
	_bounds = AABB(Vector3(-hx, bottom + 0.12, -hz), Vector3(hx * 2.0, maxf(height - 0.25, 0.05), hz * 2.0))
	# A price sign on the front of the cabinet (+Z faces into the shop).
	_sign = BuildUtil.sign(self, "Goldfish", Vector3(0, bottom - 0.08 * sy, 0.334 * sz + 0.004), 0.0, 0.085)
	var top := bottom + height
	var body := Interactable.new()
	body.setup("goldfish", "Click: Goldfish tank (restock at the Market)", Vector3(0, top * 0.5, 0),
		Vector3(SIZE.x + 0.1, top, SIZE.z + 0.1))
	add_child(body)
	Synty.solid(self, Vector3(0, bottom * 0.5, 0), Vector3(SIZE.x + 0.1, bottom, SIZE.z + 0.1))
	Game.changed.connect(refresh)
	Game.day_started.connect(refresh)
	refresh()


## The sign text: price and how many are left.
static func sign_text(count: int, price: int) -> String:
	return "Goldfish $%d · sold out" % price if count <= 0 else "Goldfish $%d · %d left" % [price, count]


func refresh() -> void:
	var state := Game.state
	BuildUtil.set_sign_text(_sign, sign_text(state.goldfish, state.goldfish_price()))
	var want := mini(state.goldfish, MAX_SHOWN)
	if want == _shown:
		return
	_shown = want
	while _swimmers.size() > want:
		_swimmers.pop_back().queue_free()
	var species := state.goldfish_look_species()
	if species.is_empty():
		species = PLAIN_SPECIES
	while _swimmers.size() < want:
		var swimmer := Fish3D.new()
		add_child(swimmer)
		swimmer.setup(state.goldfish_look_fish(_swimmers.size()), species, _bounds)
		_swimmers.append(swimmer)
