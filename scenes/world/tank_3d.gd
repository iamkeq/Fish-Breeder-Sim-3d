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
const SPRITE_HEIGHT := {"short": 0.3, "medium": 0.42, "tall": 0.62}
const SAND_HEIGHT := 0.07
## How close you must be to see a tank's name.
const LABEL_RANGE := 4.5

## The Synty tank model: where its glass sits (model metres) before stretching.
const MODEL_GLASS_BOTTOM := 0.70
const MODEL_GLASS_HEIGHT := 0.55
const MODEL_GLASS_WIDTH := 1.18
const MODEL_GLASS_DEPTH := 0.57

## Which Synty model stands in for each kind of decor (Polygon Pirates and Polygon Dungeon).
const PIRATE_ENV := "Pirates/Environments/SM_Env_"
const ROCK := "Dungeon/Environments/Rocks/SM_Env_"
## Plants by height class (anything not named gets one picked by its id).
const PLANTS := {
	"tall": [PIRATE_ENV + "Plants_03", PIRATE_ENV + "PalmBush_03", PIRATE_ENV + "Flowers_01"],
	"medium": [PIRATE_ENV + "Plants_01", PIRATE_ENV + "Plants_02", PIRATE_ENV + "Fern_01"],
	"short": [PIRATE_ENV + "Grass_01", PIRATE_ENV + "Grass_02", PIRATE_ENV + "Grass_03"],
}
const ROCKS := [ROCK + "Rock_Round_01", ROCK + "Rock_Round_02", ROCK + "Rock_Round_03", ROCK + "Rock_Round_04"]
const WOOD := [PIRATE_ENV + "Mangrove_Roots_01", "Pirates/Props/SM_Prop_WoodPlank_01"]
## Decor, rocks and wood with a model of their own, by item id.
const DECOR := {
	"clay_pot": "Dungeon/Props/SM_Prop_Vase_02",
	"coconut_hut": "Pirates/Props/SM_Prop_Barrel_Half_01",
	"ruined_arch": "Dungeon/Environments/Walls/SM_Env_Wall_Archway_01",
	"treasure_chest": "Pirates/Props/SM_Prop_Chest_01",
	"seiryu_stone": ROCK + "Rock_Pillar_01",
	"mountain_rock": ROCK + "Rock_Round_02",
	"rock_cave": ROCK + "RockPile_Rounded_01",
	"holey_rock": PIRATE_ENV + "Rock_Arch_01",
	"lava_rock": ROCK + "Rock_Spike_01",
	"mossy_slate": ROCK + "Rock_Flat_Large_01",
	"seiryu_spire": ROCK + "Rock_Spike_03",
	"slate_stack": ROCK + "Rock_Flat_01",
	"zen_stones": ROCK + "Rock_Pebble_01",
	"mixed_pebbles": ROCK + "Rubble_Pebbles_01",
	"mossy_driftwood": PIRATE_ENV + "Mangrove_Roots_01",
	"spider_wood": "Pirates/Props/SM_Prop_WoodPlank_01",
	"hollow_log": "Generic/SM_Generic_TreeStump_01",
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
var _body: StaticBody3D
var _label_hidden := false
var _solid: StaticBody3D


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
	_body = body
	_solid = Synty.solid(self, Vector3(0, stand_height * 0.5, 0), Vector3(size.x + 0.1, stand_height, size.z + 0.1))
	Game.changed.connect(refresh)
	refresh()


## Where decor in `slot` (in `row`) stands, tank-local (used by the tank editor's markers).
func decor_base(slot: int, row: String) -> Vector3:
	return Vector3((float(SLOT_X[slot]) - 0.5) * (size.x - 0.25), stand_height + SAND_HEIGHT,
		float(ROW_Z[row]) * (size.z - 0.15))


## Hides the floating name for good (when the tank is shown inside a menu).
func hide_label() -> void:
	_label.visible = false
	_label_hidden = true


## The name floats over a tank only while you are near it, so neighbouring tanks don't overlap.
func _process(_delta: float) -> void:
	if _label_hidden or _label == null:
		return
	var camera := get_viewport().get_camera_3d()
	_label.visible = camera != null and camera.global_position.distance_to(_label.global_position) < LABEL_RANGE


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
	# The second display stand only exists once it is bought.
	var shown := location != Fish.DISPLAY2 or state.has_second_display()
	visible = shown
	if _body != null:
		_body.collision_layer = 1 if shown else 0
		_solid.collision_layer = 1 if shown else 0
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
			_fish[fish_id].set_buff(state.food_buff_icon(state.inventory.get_fish(fish_id)))
			continue
		var f: Fish = state.inventory.get_fish(fish_id)
		if f == null:
			continue
		var fish3d := Fish3D.new()
		add_child(fish3d)
		fish3d.setup(f, state.species_of(f), swim_bounds())
		fish3d.set_buff(state.food_buff_icon(f))
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


## The model for a decor item: its own by id, else one for its category (and height).
func _decor_model(item: Dictionary) -> String:
	var id := String(item.get("id", ""))
	if DECOR.has(id):
		return DECOR[id]
	var pool: Array = DECOR.values()
	match item.get("category", ""):
		"plant":
			pool = PLANTS.get(item.get("height", "medium"), PLANTS["medium"])
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
