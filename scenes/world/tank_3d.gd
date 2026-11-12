extends Node3D
## One tank on its stand: a glass box with blue water, a sand floor, decor
## (display tank) and its fish swimming about. Refreshes itself on Game.changed.
## `location` is Fish.DISPLAY, a breeding tank location or Fish.HOLDING.

const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")
const Fish3D := preload("res://scenes/world/fish_3d.gd")
const UI := preload("res://scenes/ui/ui_kit.gd")

## Decor placement, like scenes/tank_view.gd: x as a share of the tank width, row depth.
const SLOT_X := [0.24, 0.74, 0.1, 0.52, 0.34, 0.88]
const ROW_Z := {"back": -0.28, "mid": 0.0, "front": 0.28}
const ROW_SCALE := {"back": 0.85, "mid": 0.95, "front": 1.0}
const SPRITE_HEIGHT := {"short": 0.2, "medium": 0.34, "tall": 0.6}
const SAND_HEIGHT := 0.07
const FRAME := Color("#4f6770")

var location := Fish.DISPLAY
var size := Vector3(1.2, 0.6, 0.55)
var stand_height := 0.75

var _glass_root: Node3D
var _decor_root: Node3D
var _label: Label3D
var _label_text := ""
var _fish: Dictionary = {}  # fish id -> Fish3D
var _decor_key := "-"


## Builds the tank. `kind` / `prompt` go to the clickable body (see interactable.gd).
func setup(p_location: String, p_size: Vector3, p_stand: float, p_label: String, kind: String,
		prompt: String, stand_color: Color) -> void:
	location = p_location
	size = p_size
	stand_height = p_stand
	_label_text = p_label
	var base := stand_height
	# Stand (a cabinet) with a lighter top.
	BuildUtil.box(self, Vector3(0, base * 0.5 - 0.02, 0), Vector3(size.x + 0.08, base - 0.04, size.z + 0.08), stand_color)
	BuildUtil.box(self, Vector3(0, base - 0.02, 0), Vector3(size.x + 0.14, 0.04, size.z + 0.14), stand_color.lightened(0.2))
	_glass_root = Node3D.new()
	add_child(_glass_root)
	_build_glass(base)
	_decor_root = Node3D.new()
	add_child(_decor_root)
	_label = BuildUtil.label(self, p_label, Vector3(0, base + size.y + 0.22, 0))
	var body := Interactable.new()
	body.setup(kind, prompt, Vector3(0, (base + size.y) * 0.5, 0), Vector3(size.x + 0.14, base + size.y, size.z + 0.14), location)
	add_child(body)
	Game.changed.connect(refresh)
	refresh()


func _build_glass(base: float) -> void:
	var water_mesh := BoxMesh.new()
	water_mesh.size = Vector3(size.x - 0.02, size.y * 0.92, size.z - 0.02)
	var water := MeshInstance3D.new()
	water.mesh = water_mesh
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.36, 0.66, 0.82, 0.38)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.render_priority = 0
	water.material_override = wm
	water.position = Vector3(0, base + size.y * 0.46, 0)
	_glass_root.add_child(water)
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = size
	var glass := MeshInstance3D.new()
	glass.mesh = glass_mesh
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.96, 1.0, 0.14)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.1
	gm.render_priority = 1
	glass.material_override = gm
	glass.position = Vector3(0, base + size.y * 0.5, 0)
	_glass_root.add_child(glass)
	# Frame: a base plate, four corner posts and a rim.
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var top := base + size.y
	BuildUtil.box(_glass_root, Vector3(0, base + 0.01, 0), Vector3(size.x + 0.06, 0.03, size.z + 0.06), FRAME)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			BuildUtil.box(_glass_root, Vector3(sx * hx, base + size.y * 0.5, sz * hz), Vector3(0.035, size.y, 0.035), FRAME)
	BuildUtil.box(_glass_root, Vector3(0, top, hz), Vector3(size.x + 0.04, 0.035, 0.035), FRAME)
	BuildUtil.box(_glass_root, Vector3(0, top, -hz), Vector3(size.x + 0.04, 0.035, 0.035), FRAME)
	BuildUtil.box(_glass_root, Vector3(hx, top, 0), Vector3(0.035, 0.035, size.z), FRAME)
	BuildUtil.box(_glass_root, Vector3(-hx, top, 0), Vector3(0.035, 0.035, size.z), FRAME)


## Where fish may swim (tank-local).
func swim_bounds() -> AABB:
	var hx := size.x * 0.5 - 0.12
	var hz := size.z * 0.5 - 0.1
	var y0 := stand_height + SAND_HEIGHT + 0.08
	return AABB(Vector3(-hx, y0, -hz), Vector3(hx * 2.0, maxf(size.y - SAND_HEIGHT - 0.22, 0.05), hz * 2.0))


func refresh() -> void:
	var state := Game.state
	var tank := state.tank_at(location)
	var present := tank != null or location == Fish.HOLDING
	_glass_root.visible = present
	_decor_root.visible = present
	_label.text = _label_text if present else _label_text + " (empty stand)"
	var ids: Array = []
	if tank != null:
		ids = tank.fish_ids
	elif location == Fish.HOLDING:
		ids = state.inventory.fish_list(Fish.HOLDING).map(func(f: Fish): return f.id)
	for fish_id in _fish.keys():
		if not fish_id in ids:
			_fish[fish_id].queue_free()
			_fish.erase(fish_id)
	for fish_id in ids:
		if _fish.has(fish_id):
			_fish[fish_id].set_bounds(swim_bounds())
			continue
		var f: Fish = state.inventory.get_fish(fish_id)
		if f == null:
			continue
		var fish3d := Fish3D.new()
		add_child(fish3d)
		fish3d.setup(f, state.species_of(f), swim_bounds())
		_fish[fish_id] = fish3d
	_refresh_decor(tank)


## Sand floor and placed decor; rebuilt only when they changed.
func _refresh_decor(tank: Tank) -> void:
	var substrate := ""
	var slots: Array = []
	if tank != null:
		substrate = tank.substrate
		slots = tank.slots
		if substrate == "" and Fish.is_breeding(location):
			substrate = Game.db.economy["breeding_tanks"].get("substrate", "")
	var key := substrate + "|" + ",".join(PackedStringArray(slots.map(func(s): return str(s))))
	if key == _decor_key:
		return
	_decor_key = key
	for child in _decor_root.get_children():
		child.queue_free()
	if substrate != "":
		var color := Color(Game.db.items[substrate].get("color", "#d9c9a0"))
		BuildUtil.box(_decor_root, Vector3(0, stand_height + SAND_HEIGHT * 0.5 + 0.015, 0),
			Vector3(size.x - 0.03, SAND_HEIGHT, size.z - 0.03), color)
	if tank == null:
		return
	for slot in tank.slot_count():
		if not tank.is_slot_empty(slot):
			_add_decor(Game.db.items[tank.slots[slot]], slot, tank.row_of(slot))


func _add_decor(item: Dictionary, slot: int, row: String) -> void:
	var x: float = (float(SLOT_X[slot]) - 0.5) * (size.x - 0.25)
	var z: float = float(ROW_Z[row]) * (size.z - 0.15)
	var floor_y := stand_height + SAND_HEIGHT + 0.01
	var height: float = size.y * float(SPRITE_HEIGHT.get(item.get("height", "short"), 0.2)) * float(ROW_SCALE[row])
	if item.has("sprite"):
		var r: Array = item["sprite"]
		var sprite := Sprite3D.new()
		sprite.texture = UI.sheet_texture(item["sheet"])
		sprite.region_enabled = true
		sprite.region_rect = Rect2(r[0], r[1], r[2], r[3])
		var pixel: float = height / float(r[3])
		var width: float = float(r[2]) * pixel
		if width > size.x * 0.4:
			pixel *= size.x * 0.4 / width
		sprite.pixel_size = pixel
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.shaded = false
		sprite.double_sided = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		sprite.position = Vector3(x, floor_y + float(r[3]) * pixel * 0.5 - 0.01, z)
		_decor_root.add_child(sprite)
	else:  # no art: a small coloured block
		var color := Color(item.get("color", "#999999"))
		BuildUtil.box(_decor_root, Vector3(x, floor_y + height * 0.5, z), Vector3(0.1, height, 0.1), color)
