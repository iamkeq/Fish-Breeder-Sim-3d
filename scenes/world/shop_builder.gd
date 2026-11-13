extends RefCounted
## Builds the whole building out of Synty Polygon Shops pieces: wall, floor and
## ceiling tiles (2.5 m each), the counter, retail shelf, display tank, the doorway
## behind the counter, the back room (tanks along the walls, a desk) and the
## dressing (plants, mats, bench, notice board, lamps). Layout, -Z towards the street:
##   shop floor    x -6.25..6.25, z -5..2.5   (front door at x 0, z -5)
##   back room     x -6.25..6.25, z 2.5..12.5
## Returns the spots people walk to (see customer_manager.gd).

const Tank3D := preload("res://scenes/world/tank_3d.gd")
const BackRoom3D := preload("res://scenes/world/back_room_3d.gd")
const ShelfStock := preload("res://scenes/world/shelf_stock.gd")
const Interactable := preload("res://scenes/world/interactable.gd")
const BuildUtil := preload("res://scenes/world/build_util.gd")
const Synty := preload("res://scenes/world/synty.gd")
const ShopFront3D := preload("res://scenes/world/shop_front_3d.gd")

const BAY := 2.5  # every wall, floor and ceiling tile is 2.5 m
const X0 := -6.25
const Z0 := -5.0
const BAYS_X := 5
const BAYS_Z := 7
const WALL_HEIGHT := 3.0
const DIVIDER_Z := 2.5

const COUNTER_CENTRE := Vector3(-0.8, 0.0, -1.6)
const COUNTER_SIZE := Vector3(3.0, 1.0, 1.2)
## The desk buttons sit on the bottom shelf of the recess on the shopkeeper side (+Z).
const BUTTON_Y := 0.5
## The open middle of the desk on the shopkeeper's side (where the buttons are).
const RECESS_WIDTH := 1.1
const RECESS_DEPTH := 0.45
const BUTTON_Z := 0.3
const DISPLAY_POS := Vector3(3.6, 0.0, -2.8)
const DISPLAY2_POS := Vector3(3.6, 0.0, -0.4)
const SHELF_POS := Vector3(-5.6, 0.0, -2.5)
const DESK_POS := Vector3(3.0, 0.0, 11.5)

const WALL_MATERIAL := "Building_Mats/PolygonShops_Mat_Base_Blank_01_mat"
const SHOP_FLOOR_MATERIAL := "Building_Mats/PolygonShops_Mat_Base_Wood_02_mat"
const BACK_FLOOR_MATERIAL := "Building_Mats/PolygonShops_Mat_Tile_03_mat"
const TRIM_MATERIAL := "Building_Mats/PolygonShops_Mat_Base_Wood_01_mat"
const RUG_MATERIAL := "Building_Mats/PolygonShops_Mat_Carpet_01_mat"
## Warm cream the plain wall and ceiling texture is multiplied by.
const PAINT := Color(1.0, 0.9, 0.74)

var root: Node3D
## Labels over the desk buttons, whose text the world keeps up to date.
var button_labels := {}


## Builds everything under `parent` and returns {"anchors": {...}, "display_tank": Tank3D}.
func build(parent: Node3D) -> Dictionary:
	root = Node3D.new()
	root.name = "Building"
	parent.add_child(root)
	_floors()
	_walls()
	_lights()
	_counter()
	_shelf()
	_decor()
	var display := _display_tank()
	var display2 := _display_tank_2()
	root.add_child(ShopFront3D.new())
	_back_room()
	_signs()
	_outside()
	return {
		"anchors": {
			"door": Vector3(0, 0, -6.2),
			"shelf": Vector3(-4.7, 0, SHELF_POS.z),
			"display": Vector3(DISPLAY_POS.x, 0, -4.0),
			"display2": Vector3(DISPLAY2_POS.x, 0, -1.6),
			"counter": Vector3(-0.6, 0, -2.9),
			"start": Vector3(-0.6, 0.05, -0.4),
			"back_room": Vector3(0, 0.05, 3.6),
		},
		"display_tank": display,
		"display_tank_2": display2,
		"button_labels": button_labels,
	}


# --- Floors, walls, ceiling ---------------------------------------------------

func _floors() -> void:
	var wood := Synty.material(SHOP_FLOOR_MATERIAL)
	var checker := Synty.material(BACK_FLOOR_MATERIAL)
	var ceiling_paint := Synty.tinted(WALL_MATERIAL, PAINT)
	for ix in BAYS_X:
		for iz in BAYS_Z:
			var at := Vector3(X0 + ix * BAY, 0.0, Z0 + iz * BAY)
			var shop_side := Z0 + (iz + 1) * BAY <= DIVIDER_Z + 0.01
			var floor_tile := Synty.put(root, "Buildings/SM_Bld_Base_Floor_01", at)
			Synty.paint(floor_tile, wood if shop_side else checker)
			var ceiling := Synty.put(root, "Buildings/SM_Bld_Base_Ceiling_01", at + Vector3(0, WALL_HEIGHT, 0))
			Synty.paint(ceiling, ceiling_paint)
	# One big collider for the whole floor (and the ground under the door step).
	Synty.solid(root, Vector3(0, -0.5, (Z0 + Z0 + BAYS_Z * BAY) * 0.5), Vector3(BAYS_X * BAY, 1.0, BAYS_Z * BAY))


func _walls() -> void:
	var x1 := X0 + BAYS_X * BAY
	var z1 := Z0 + BAYS_Z * BAY
	# kinds: "wall", "window" or "door". Each run starts at `from`, heads along `yaw`
	# (local +X of a tile) and has its inside face on local +Z.
	_wall_run(Vector3(X0, 0, Z0), 0.0, ["window", "window", "door", "window", "window"], true)
	_wall_run(Vector3(x1, 0, z1), 180.0, ["wall", "wall", "wall", "wall", "wall"], true)
	_wall_run(Vector3(x1, 0, Z0), -90.0, ["window", "wall", "window", "wall", "window", "wall", "window"], true)
	_wall_run(Vector3(X0, 0, z1), 90.0, ["wall", "wall", "window", "wall", "window", "wall", "window"], true)
	# The divider between the shop and the back room: tiles once, trim on both faces.
	_wall_run(Vector3(X0, 0, DIVIDER_Z), 0.0, ["wall", "wall", "door", "wall", "wall"], true)
	_trim_run(Vector3(x1, 0, DIVIDER_Z), 180.0, BAYS_X, ["wall", "wall", "door", "wall", "wall"])


## One straight wall of tiles. `from` is where its first tile starts (a tile's origin is
## its left end, seen from inside); `yaw_deg` is how the run is turned.
func _wall_run(from: Vector3, yaw_deg: float, kinds: Array, with_trim: bool) -> void:
	var along := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(yaw_deg))
	var wall_mat := Synty.tinted(WALL_MATERIAL, PAINT)
	for i in kinds.size():
		var rel := "Buildings/SM_Bld_Base_Wall_01"
		match kinds[i]:
			"window":
				rel = "Buildings/SM_Bld_Base_Wall_Window_Double_01"
			"door":
				rel = "Buildings/SM_Bld_Base_Wall_Door_Double_01"
		var tile := Synty.put(root, rel, from + along * (BAY * i), yaw_deg)
		_paint_walls(tile, wall_mat)
		# Colliders: the whole tile, or the two sides and the top of a doorway.
		if kinds[i] == "door":
			_tile_solid(tile, Vector3(0.12, 1.5, 0.0), Vector3(0.24, 3.0, 0.3))
			_tile_solid(tile, Vector3(BAY - 0.12, 1.5, 0.0), Vector3(0.24, 3.0, 0.3))
			_tile_solid(tile, Vector3(BAY * 0.5, 2.65, 0.0), Vector3(BAY, 0.7, 0.3))
		else:
			_tile_solid(tile, Vector3(BAY * 0.5, 1.5, 0.0), Vector3(BAY, 3.0, 0.3))
	if with_trim:
		_trim_run(from, yaw_deg, kinds.size(), kinds)


## Skirting along the bottom and a trim band along the top of a wall.
## No skirting across a doorway (`kinds` as in _wall_run), so you don't see a plank in the gap.
func _trim_run(from: Vector3, yaw_deg: float, count: int, kinds: Array = []) -> void:
	var along := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(yaw_deg))
	var wood := Synty.material(TRIM_MATERIAL)
	for i in count:
		var at := from + along * (BAY * i)
		if i >= kinds.size() or kinds[i] != "door":
			Synty.paint(Synty.put(root, "Buildings/SM_Bld_Trim_Wall_Low_01", at, yaw_deg), wood)
		Synty.paint(Synty.put(root, "Buildings/SM_Bld_Trim_Ceiling_01", at, yaw_deg), wood)


## Give the plain parts of a wall tile the cream material (the glass stays glass).
func _paint_walls(tile: Node, wall_mat: Material) -> void:
	for node in [tile] + tile.find_children("*", "MeshInstance3D", true, false):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m != null and String(m.resource_name).contains("Brick"):
				mi.set_surface_override_material(s, wall_mat)


func _tile_solid(tile: Node3D, local_pos: Vector3, size: Vector3) -> void:
	var body := Synty.solid(tile, local_pos, size)
	body.position = local_pos


## Hanging lamps over both rooms, each with a warm light under it.
func _lights() -> void:
	for spot in [Vector3(-3, 2.7, -2), Vector3(3, 2.7, -2), Vector3(0, 2.7, 1.2),
			Vector3(-3, 2.7, 5), Vector3(3, 2.7, 5), Vector3(-3, 2.7, 9), Vector3(3, 2.7, 9), Vector3(0, 2.7, 7)]:
		var lamp := Synty.put(root, "Props/SM_Prop_Lighting_Ceiling_Shaded_01", Vector3(spot.x, 2.62, spot.z))
		lamp.scale = Vector3(1.0, 0.7, 1.0)
		lamp.position.y = WALL_HEIGHT - 0.54 * 0.7
		var light := OmniLight3D.new()
		light.position = Vector3(spot.x, 2.2, spot.z)
		light.omni_range = 8.0
		light.omni_attenuation = 1.2
		light.light_energy = 1.3
		light.light_color = Color("#ffe4bc")
		root.add_child(light)


# --- Furniture ------------------------------------------------------------------

func _counter() -> void:
	var c := COUNTER_CENTRE
	Synty.put(root, "Props/SM_Prop_Shop_Desk_01", c, 180.0)
	# Three boxes, leaving the recess on the shopkeeper's side open so the crosshair can
	# reach the buttons on its bottom shelf: the two ends full depth, the middle shallower.
	var side_w := (COUNTER_SIZE.x - RECESS_WIDTH) * 0.5
	var back_d := COUNTER_SIZE.z - RECESS_DEPTH
	var boxes := [
		[Vector3(-(RECESS_WIDTH + side_w) * 0.5, 0, 0), Vector3(side_w, COUNTER_SIZE.y, COUNTER_SIZE.z)],
		[Vector3((RECESS_WIDTH + side_w) * 0.5, 0, 0), Vector3(side_w, COUNTER_SIZE.y, COUNTER_SIZE.z)],
		[Vector3(0, 0, -RECESS_DEPTH * 0.5), Vector3(RECESS_WIDTH, COUNTER_SIZE.y, back_d)],
	]
	for box in boxes:
		Synty.solid(root, c + box[0] + Vector3(0, 0.5, 0), box[1])
		var body := Interactable.new()
		body.setup("counter", "Click: Counter", c + box[0] + Vector3(0, 0.55, 0), box[1] + Vector3(0.1, 0.1, 0.0))
		root.add_child(body)
	# The till, a tip jar and a laptop on top.
	Synty.put(root, "Props/SM_Prop_Shop_Cash_Register_02", c + Vector3(0.95, 1.01, 0.05), 0.0)
	Synty.put(root, "Props/SM_Prop_Cafe_Tip_Jar_01", c + Vector3(-0.2, 1.01, -0.1))
	Synty.put(root, "Props/SM_Prop_Computer_Laptop_01", c + Vector3(-0.9, 1.01, 0.2), 10.0)
	# The laptop opens the Market.
	var laptop := Interactable.new()
	laptop.setup("market", "Click: Market (order stock)", c + Vector3(-0.9, 1.2, 0.2), Vector3(0.6, 0.4, 0.55))
	root.add_child(laptop)
	_desk_buttons(c)


## Two buttons on the desk's bottom shelf, on the shopkeeper's side: close the shop for the
## day (from 13:00), and close for restock / reopen.
func _desk_buttons(c: Vector3) -> void:
	var specs := [["close_shop", -0.3, "Close shop"], ["restock", 0.3, "Restock"]]
	for spec in specs:
		var at := c + Vector3(spec[1], BUTTON_Y, BUTTON_Z)
		Synty.put(root, "Props/SM_Prop_Toilet_Button_01", at, 0.0, Vector3.ONE * 1.6)
		var body := Interactable.new()
		# The click box reaches out past the desk's front edge, so the crosshair finds the
		# button before the counter (whose box covers the whole desk).
		body.setup(spec[0], "", at + Vector3(0, 0.02, 0.22), Vector3(0.34, 0.28, 0.66))
		root.add_child(body)
		button_labels[spec[0]] = BuildUtil.label(root, spec[2], at + Vector3(0, 0.2, 0.16), 0.0016, false)


func _shelf() -> void:
	# A shelving unit along the left wall; the stock sits on its three boards.
	Synty.put(root, "Props/SM_Prop_Shop_Shelf_Basic_01", SHELF_POS, 90.0, Vector3(3.0 / 2.93, 1.0, 1.0))
	Synty.solid(root, SHELF_POS + Vector3(0, 0.95, 0), Vector3(0.9, 1.9, 3.0))
	var stock := ShelfStock.new()
	stock.position = SHELF_POS
	root.add_child(stock)
	var body := Interactable.new()
	body.setup("shelf", "Click: Shelf", SHELF_POS + Vector3(0.0, 0.95, 0.0), Vector3(0.9, 1.9, 3.1))
	root.add_child(body)
	BuildUtil.label(root, "Shop shelf", Vector3(SHELF_POS.x + 0.5, 2.3, SHELF_POS.z), 0.004)


## Things that only make the shop cosy: door mat, rug, plants, bench, notice board, posters.
func _decor() -> void:
	Synty.put(root, "Props/SM_Prop_Shop_Mat_01", Vector3(0, 0.0, -4.35))
	# A rug in front of the counter: a floor tile with the carpet material, flattened and stretched.
	var rug := Synty.put(root, "Buildings/SM_Bld_Base_Floor_01", Vector3(-1.9, 0.012, -4.4), 0.0, Vector3(1.5, 1.0, 0.7))
	Synty.paint(rug, Synty.material(RUG_MATERIAL))
	for spot in [Vector3(5.6, 0, -4.4), Vector3(-5.7, 0, 1.8), Vector3(-2.7, 0, -4.4), Vector3(5.6, 0, 11.7), Vector3(-5.7, 0, 11.7)]:
		_plant(spot)
	# A bench along the right wall under the window.
	Synty.put(root, "Props/SM_Prop_Bench_01", Vector3(5.75, 0, 0.9), -90.0)
	Synty.solid(root, Vector3(5.75, 0.3, 0.9), Vector3(0.6, 0.6, 1.8))
	# Notice board and posters on the front wall and the divider.
	Synty.put(root, "Signs/SM_Prop_Notice_Board_01", Vector3(3.75, 1.7, Z0 + 0.14))
	Synty.put(root, "Signs/SM_Prop_Poster_03", Vector3(-3.75, 1.7, Z0 + 0.14))
	Synty.put(root, "Signs/SM_Prop_Poster_07", Vector3(-2.2, 1.7, DIVIDER_Z - 0.14), 180.0)
	Synty.put(root, "Props/SM_Prop_Art_Frame_01", Vector3(2.2, 1.7, DIVIDER_Z - 0.14), 180.0)


## A plant in a clay pot, about 0.8 m tall.
func _plant(pos: Vector3) -> void:
	var pot := Synty.put(root, "Props/SM_Prop_Planter_Vase_01", pos, 0.0, Vector3(0.55, 0.55, 0.55))
	pot.name = "Pot"
	var leaves := Synty.put(root, "Environments/SM_Env_Plant_01", pos + Vector3(0, 0.5, 0), randf() * 360.0, Vector3(0.45, 0.9, 0.45))
	leaves.name = "Leaves"
	Synty.solid(root, pos + Vector3(0, 0.25, 0), Vector3(0.4, 0.5, 0.4))


func _display_tank() -> Node3D:
	var tank := Tank3D.new()
	tank.position = DISPLAY_POS
	root.add_child(tank)
	tank.setup(Fish.DISPLAY, Vector3(2.0, 0.8, 0.8), 0.7, "Display tank", "display_tank",
		"Click: Display tank", Color.WHITE)
	return tank


func _display_tank_2() -> Node3D:
	var tank := Tank3D.new()
	tank.position = DISPLAY2_POS
	root.add_child(tank)
	tank.setup(Fish.DISPLAY2, Vector3(2.0, 0.8, 0.8), 0.7, "Display tank 2", "display_tank",
		"Click: Display tank 2", Color.WHITE)
	return tank


func _back_room() -> void:
	var tanks := BackRoom3D.new()
	root.add_child(tanks)
	# A desk for the Lab, shows, gallery and staff.
	var p := DESK_POS
	Synty.put(root, "Props/SM_Prop_Shop_Desk_03", p, 180.0)
	Synty.solid(root, p + Vector3(0, 0.55, 0), Vector3(1.8, 1.1, 1.0))
	Synty.put(root, "Props/SM_Prop_Computer_Monitor_01", p + Vector3(0.1, 1.1, 0.15), 180.0)
	Synty.put(root, "Props/SM_Prop_Computer_Keyboard_01", p + Vector3(0.1, 1.1, -0.2), 180.0)
	Synty.put(root, "Props/SM_Prop_Shop_Chair_01", p + Vector3(0.1, 0, -1.0), 20.0)
	var body := Interactable.new()
	body.setup("desk", "Click: Back room desk", p + Vector3(0, 0.6, 0), Vector3(1.9, 1.2, 1.1))
	root.add_child(body)
	BuildUtil.label(root, "Desk", p + Vector3(0, 1.8, 0), 0.004)


const SIGN_Y := 2.38

func _signs() -> void:
	# Facing +Z, readable from the shop side of the front wall.
	# Under the ceiling trim and clear of the wall, so the letters don't cut into either.
	BuildUtil.label(root, "Fig Tree Fish Breeder", Vector3(0, SIGN_Y, Z0 + 0.3), 0.0042, false)
	var back_sign := BuildUtil.label(root, "Back room", Vector3(0, SIGN_Y, DIVIDER_Z - 0.3), 0.0042, false)
	back_sign.rotation.y = PI  # faces the shop
	BuildUtil.label(root, "Shop floor", Vector3(0, SIGN_Y, DIVIDER_Z + 0.3), 0.0042, false)


## The street outside, from Polygon City: a pavement along the shop front, a two-lane
## road, the pavement and shopfronts opposite, neighbouring shops either side, trees,
## lamps, parked cars and a skyline. The ground is solid all the way across, and
## invisible walls keep you on the pavement, the road and the far pavement.
const STREET_HALF := 35.0  # the street runs x -35..35
const FAR_WALL_Z := -25.0  # the far pavement's edge, in front of the shops opposite

func _outside() -> void:
	var c := "City/"
	# Ground: solid under everything, grass beyond the tarmac.
	Synty.solid(root, Vector3(0, -0.5, -27.5), Vector3(STREET_HALF * 2.0, 1.0, 45.0))
	var grass := Synty.put(root, c + "Environments/SM_Env_Grass_01", Vector3(100, -0.16, 100), 0.0, Vector3(40, 1, 40))
	grass.name = "Grass"
	# Pavement (z -10..-5), road (z -20..-10) and the far pavement (z -25..-20), in 5 m tiles.
	for ix in range(-7, 7):
		var x := ix * 5.0
		Synty.put(root, c + "Environments/SM_Env_Sidewalk_01", Vector3(x, 0.0, -5.0))
		Synty.put(root, c + "Environments/SM_Env_Sidewalk_01", Vector3(x, 0.0, -20.0))
		Synty.put(root, c + "Environments/SM_Env_Road_Lines_01", Vector3(x, 0.0, -10.0))
		Synty.put(root, c + "Environments/SM_Env_Road_Lines_01", Vector3(x, 0.0, -15.0), 180.0)
		Synty.put(root, c + "Environments/SM_Env_Sidewalk_Straight_01", Vector3(x, 0.0, -10.0))
		Synty.put(root, c + "Environments/SM_Env_Sidewalk_Straight_01", Vector3(x, 0.0, -20.0), 180.0)
	# Invisible walls.
	var wall_h := 8.0
	Synty.solid(root, Vector3(0, wall_h * 0.5, FAR_WALL_Z - 0.5), Vector3(STREET_HALF * 2.0, wall_h, 1.0))
	for side in [-1.0, 1.0]:
		Synty.solid(root, Vector3(float(side) * (STREET_HALF + 0.5), wall_h * 0.5, -15.0), Vector3(1.0, wall_h, 20.0))
		# the neighbours' fronts, either side of our own front wall
		var mid: float = float(side) * (6.25 + STREET_HALF) * 0.5
		Synty.solid(root, Vector3(mid, wall_h * 0.5, Z0 - 0.5), Vector3(STREET_HALF - 6.25, wall_h, 1.0))
	_neighbours(c)
	_behind(c)
	_across_the_street(c)
	_street_furniture(c)
	_skyline(c)
	# The shop's name over the door, readable from the street.
	var name_sign := BuildUtil.label(root, "Fig Tree Fish Breeder", Vector3(0, 2.8, Z0 - 0.45), 0.0045, false)
	name_sign.rotation.y = PI


## Shops either side of ours, fronts flush with our front wall (turned to face the road).
func _neighbours(c: String) -> void:
	var right := ["Shop_01", "Shop_03", "Shop_05", "Shop_02"]
	var left := ["Shop_04", "Shop_02", "Shop_06", "Shop_01", "Shop_05"]
	var edge := 6.25
	for name in right:
		var wide := 10.0 if name == "Shop_03" else 5.0
		Synty.put(root, c + "Buildings/SM_Bld_" + name, Vector3(edge + wide, 0.0, Z0 + 0.5), 180.0)
		edge += wide
	edge = -6.25
	for name in left:
		var wide := 10.0 if name == "Shop_03" else 5.0
		Synty.put(root, c + "Buildings/SM_Bld_" + name, Vector3(edge, 0.0, Z0 + 0.5), 180.0)
		edge -= wide


## Behind and beside the shop: paved alleys, the backs of taller buildings across them and
## a few bins, so the side and back windows look out on the town too.
func _behind(c: String) -> void:
	for ix in range(-6, 6):
		for iz in range(0, 7):
			Synty.put(root, c + "Environments/SM_Env_Road_Bare_01", Vector3(ix * 5.0, -0.01, 5.0 + iz * 5.0))
	# Either side of the shop, across a 2.5 m alley.
	Synty.put(root, c + "Buildings/SM_Bld_OfficeSquare_02", Vector3(8.75, 0.0, 16.0))
	Synty.put(root, c + "Buildings/SM_Bld_OfficeOld_Small_01", Vector3(-20.0, 0.0, 12.0), 90.0)
	Synty.put(root, c + "Buildings/SM_Bld_Apartment_Stack_01", Vector3(-8.75, 0.0, 6.0), 90.0)
	# Behind the back room, across the back alley.
	Synty.put(root, c + "Buildings/SM_Bld_OfficeOld_Large_01", Vector3(8.0, 0.0, 18.5), 180.0)
	Synty.put(root, c + "Buildings/SM_Bld_OfficeSquare_01", Vector3(-8.0, 0.0, 18.5), 180.0)
	Synty.put(root, c + "Buildings/SM_Bld_OfficeSquare_02", Vector3(24.0, 0.0, 18.5), 180.0)
	# Alley clutter.
	Synty.put(root, c + "Props/SM_Prop_Skip_01", Vector3(3.5, 0.0, 15.0))
	Synty.put(root, c + "Props/SM_Prop_TrashBag_01", Vector3(1.6, 0.0, 14.6))
	Synty.put(root, c + "Props/SM_Prop_TrashBag_02", Vector3(1.0, 0.0, 15.2))
	Synty.put(root, c + "Props/SM_Prop_Pallet_01", Vector3(-3.5, 0.0, 14.5), 20.0)
	Synty.put(root, c + "Props/SM_Prop_CardboardBox_01", Vector3(-4.6, 0.0, 14.2))
	Synty.put(root, c + "Props/SM_Prop_Aircon_01", Vector3(7.6, 0.0, 6.0), -90.0)
	Synty.put(root, c + "Props/SM_Prop_Trashbin_02", Vector3(-7.4, 0.0, 9.0))


## Shopfronts opposite (facing us) with taller buildings behind them.
func _across_the_street(c: String) -> void:
	var row := ["Shop_03", "Shop_01", "Shop_05", "Shop_02", "Shop_04", "Shop_06", "Shop_03", "Shop_05", "Shop_01", "Shop_02", "Shop_06", "Shop_04"]
	var x := -STREET_HALF
	for name in row:
		var wide := 10.0 if name == "Shop_03" else 5.0
		if x + wide > STREET_HALF + 0.1:
			break
		Synty.put(root, c + "Buildings/SM_Bld_" + name, Vector3(x, 0.0, -25.0))
		x += wide
	var towers := [["OfficeSquare_01", -30.0], ["OfficeOld_Small_01", -8.0], ["OfficeSquare_01", 12.0], ["OfficeOld_Large_01", 28.0]]
	for t in towers:
		Synty.put(root, c + "Buildings/SM_Bld_" + t[0], Vector3(t[1], 0.0, -34.0))


## Trees, lamps, benches, bins, parked cars and so on, along the pavements and the road.
func _street_furniture(c: String) -> void:
	for x in [-16.0, -9.0, 9.0, 16.0, 24.0, -24.0]:
		Synty.put(root, c + "Environments/SM_Env_Tree_01" if int(x) % 2 == 0 else c + "Environments/SM_Env_Tree_03",
			Vector3(x, 0.0, -9.0))
	for x in [-20.0, -4.0, 8.0, 22.0]:
		Synty.put(root, c + "Environments/SM_Env_Tree_03", Vector3(x, 0.0, -21.2))
	# Near pavement: bench, bins, hydrant, mailbox, planters either side of the door, meters.
	Synty.put(root, c + "Props/SM_Prop_ParkBench_01", Vector3(4.0, 0.0, -6.0), 180.0)
	Synty.put(root, c + "Props/SM_Prop_Trashbin_01", Vector3(-3.5, 0.0, -9.4))
	Synty.put(root, c + "Props/SM_Prop_Hydrant_01", Vector3(12.0, 0.0, -9.4))
	Synty.put(root, c + "Props/SM_Prop_Mailbox_01", Vector3(-12.0, 0.0, -9.4))
	Synty.put(root, c + "Props/SM_Prop_PotPlant_01", Vector3(-2.0, 0.0, -5.6))
	Synty.put(root, c + "Props/SM_Prop_PotPlant_02", Vector3(2.0, 0.0, -5.6))
	for x in [-6.0, 6.0, 18.0, -18.0]:
		Synty.put(root, c + "Props/SM_Prop_ParkingMeter_01", Vector3(x, 0.0, -9.5))
	Synty.put(root, c + "Props/SM_Prop_BusStop_01", Vector3(-26.0, 0.0, -8.4))
	# Lamps along the kerb.
	for x in [-20.0, 0.0, 20.0]:
		Synty.put(root, c + "Props/SM_Prop_LightPole_Base_01", Vector3(x, 0.0, -9.6))
	# Far pavement.
	Synty.put(root, c + "Props/SM_Prop_ParkBench_01", Vector3(-12.0, 0.0, -24.0))
	Synty.put(root, c + "Props/SM_Prop_Trashbin_02", Vector3(6.0, 0.0, -24.0))
	Synty.put(root, c + "Props/SM_Prop_Planter_01", Vector3(16.0, 0.0, -24.0))
	# Cars in the lanes (they stay put).
	var cars := [["Sedan_01", -14.0, -12.5, 90.0], ["Taxi_01", 9.0, -12.5, 90.0], ["Small_01", -4.0, -17.5, -90.0],
		["Van_01", 14.0, -17.5, -90.0], ["Sedan_01", -26.0, -17.5, -90.0]]
	for car in cars:
		Synty.put(root, c + "Vehicles/SM_Veh_Car_" + car[0], Vector3(car[1], 0.0, car[2]), car[3])


## The distant skyline and the sky dome.
func _skyline(c: String) -> void:
	Synty.put(root, c + "Environments/SM_Gen_Env_Skyline_01", Vector3.ZERO)
