extends Node3D
## One tank on its stand: the Synty fish tank model stretched to this tank's size,
## a substrate floor, decor (Synty plants, rocks, pots and wood) and its fish
## swimming about. Refreshes itself on Game.changed.
## `location` is Fish.DISPLAY, a breeding tank location or Fish.HOLDING.

const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")
const Fish3D := preload("res://scenes/world/fish_3d.gd")
const Synty := preload("res://scenes/world/synty.gd")

## Decor placement, like scenes/tank_view.gd: x as a share of the tank width, row depth.
const SLOT_X := [0.24, 0.74, 0.1, 0.52, 0.34, 0.88]
const ROW_Z := {"back": -0.28, "mid": 0.0, "front": 0.28}
const ROW_SCALE := {"back": 0.85, "mid": 0.95, "front": 1.0}
const SPRITE_HEIGHT := {"short": 0.2, "medium": 0.34, "tall": 0.6}
const SAND_HEIGHT := 0.07

## The Synty tank model: where its glass sits (model metres) before stretching.
const MODEL_GLASS_BOTTOM := 0.70
const MODEL_GLASS_HEIGHT := 0.55
const MODEL_GLASS_WIDTH := 1.18
const MODEL_GLASS_DEPTH := 0.57

## Which Synty model stands in for each kind of decor (the closest match in the packs).
const PLANTS := ["Environments/SM_Env_Plant_01", "Environments/SM_Env_Plant_02"]
const ROCKS := ["Generic/SM_Generic_Small_Rocks_01", "Generic/SM_Generic_Small_Rocks_02", "Generic/SM_Generic_Small_Rocks_03",
	"Generic/SM_Generic_Small_Rocks_04", "Generic/SM_Generic_Small_Rocks_05"]
const WOOD := ["Generic/SM_Generic_TreeStump_01"]
const DECOR := {
	"clay_pot": "Props/SM_Prop_Planter_Vase_01",
	"coconut_hut": "Props/SM_Prop_Planter_Box_Wood_01",
	"ruined_arch": "Props/SM_Prop_Planter_Box_Wood_02",
	"treasure_chest": "Props/SM_Prop_Cardboard_Box_02",
}
## Substrate colour: the Synty material laid over the tank floor.
const SUBSTRATE_MATERIAL := {
	"fine_sand": "Building_Mats/PolygonShops_Mat_Base_Blank_01_mat",
	"planted_soil": "Building_Mats/PolygonShops_Mat_Base_Wood_01_mat",
}

var location := Fish.DISPLAY
var size := Vector3(1.2, 0.6, 0.55)
var stand_height := 0.75

var _glass_parts: Array[Node3D] = []
var _decor_root: Node3D
var _label: Label3D
var _label_text := ""
var _fish: Dictionary = {}  # fish id -> Fish3D
var _decor_key := "-"


## Builds the tank. `p_size` gives the footprint (x, z) and `kind` / `prompt` go to
## the clickable body (see interactable.gd). The height comes from the model.
func setup(p_location: String, p_size: Vector3, _p_stand: float, p_label: String, kind: String,
		prompt: String, _stand_color: Color) -> void:
	location = p_location
	_label_text = p_label
	var sx := p_size.x / MODEL_GLASS_WIDTH
	var sz := p_size.z / MODEL_GLASS_DEPTH
	var sy := clampf(minf(sx, sz), 0.8, 1.15)
	size = Vector3(p_size.x, MODEL_GLASS_HEIGHT * sy, p_size.z)
	stand_height = MODEL_GLASS_BOTTOM * sy
	var model := Synty.office_tank()
	model.scale = Vector3(sx, sy, sz)
	add_child(model)
	for part in model.find_children("*Glass*", "Node3D", true, false) + model.find_children("*FX*", "Node3D", true, false):
		_glass_parts.append(part)
	_decor_root = Node3D.new()
	add_child(_decor_root)
	var top := stand_height + size.y
	_label = BuildUtil.label(self, p_label, Vector3(0, top + 0.22, 0))
	var body := Interactable.new()
	body.setup(kind, prompt, Vector3(0, top * 0.5, 0), Vector3(size.x + 0.1, top, size.z + 0.1), location)
	add_child(body)
	Synty.solid(self, Vector3(0, stand_height * 0.5, 0), Vector3(size.x + 0.1, stand_height, size.z + 0.1))
	Game.changed.connect(refresh)
	refresh()


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
	for part in _glass_parts:
		part.visible = present
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


## Substrate and placed decor; rebuilt only when they changed.
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
		var floor_tile := Synty.put(_decor_root, "Generic/SM_Generic_Ground_Tile_01",
			Vector3(-(size.x - 0.03) * 0.5, stand_height + 0.005, -(size.z - 0.03) * 0.5), 0.0,
			Vector3((size.x - 0.03) / 2.5, SAND_HEIGHT / 0.04, (size.z - 0.03) / 2.5))
		Synty.paint(floor_tile, Synty.material(SUBSTRATE_MATERIAL.get(substrate, SUBSTRATE_MATERIAL["fine_sand"])))
	if tank == null:
		return
	for slot in tank.slot_count():
		if not tank.is_slot_empty(slot):
			_add_decor(Game.db.items[tank.slots[slot]], slot, tank.row_of(slot))


## The closest Synty model for a decor item, by id first and then by category.
func _decor_model(item: Dictionary) -> String:
	var id := String(item.get("id", ""))
	if DECOR.has(id):
		return DECOR[id]
	var pool: Array = DECOR.values()
	match item.get("category", ""):
		"plant":
			pool = PLANTS
		"rock":
			pool = ROCKS
		"driftwood":
			pool = WOOD
	return pool[absi(id.hash()) % pool.size()]


func _add_decor(item: Dictionary, slot: int, row: String) -> void:
	var x: float = (float(SLOT_X[slot]) - 0.5) * (size.x - 0.25)
	var z: float = float(ROW_Z[row]) * (size.z - 0.15)
	var floor_y := stand_height + SAND_HEIGHT
	var height: float = size.y * float(SPRITE_HEIGHT.get(item.get("height", "short"), 0.2)) * float(ROW_SCALE[row])
	var piece := Synty.make(_decor_model(item))
	var b := Synty.bounds(piece)
	if b.size.y <= 0.0 or b.size.x <= 0.0:
		piece.free()
		return
	# Scale to the wanted height, but never wider than a slot can hold. Only plants
	# are stretched upwards (their models are low and wide).
	var across := minf(height / b.size.y, size.x * 0.3 / maxf(b.size.x, b.size.z))
	var up := height / b.size.y if item.get("category", "") == "plant" else across
	piece.scale = Vector3(across, up, across)
	piece.position = Vector3(x, floor_y - b.position.y * up, z)
	_decor_root.add_child(piece)
