extends RefCounted
## Builds the whole building out of boxes: shop floor (door, counter, retail
## shelf, display tank), the doorway behind the counter and the back room (tanks
## on racks, a desk). Layout, with -Z towards the street:
##   shop floor    x -6..6, z -5..2.5   (front door at x 0, z -5)
##   back room     x -6..6, z 2.7..11
## Returns the spots people walk to (see customer_manager.gd).

const BuildUtil := preload("res://scenes/world/build_util.gd")
const Interactable := preload("res://scenes/world/interactable.gd")
const Tank3D := preload("res://scenes/world/tank_3d.gd")
const BackRoom3D := preload("res://scenes/world/back_room_3d.gd")
const ShelfStock := preload("res://scenes/world/shelf_stock.gd")

const CREAM := Color("#f4ecdf")
const TEAL := Color("#74a99a")
const TERRACOTTA := Color("#d98a6a")
const WOOD := Color("#b98b5e")
const DARK_WOOD := Color("#8a6a4f")

const WALL_HEIGHT := 3.0
const DOOR_HALF := 1.0
const DOORWAY_HEIGHT := 2.3
const DIVIDER_Z := 2.6

const COUNTER_CENTRE := Vector3(-0.8, 0.0, -1.6)
const COUNTER_SIZE := Vector3(4.0, 1.0, 0.8)
const DISPLAY_POS := Vector3(3.6, 0.0, -2.8)
const SHELF_POS := Vector3(-5.6, 0.0, -2.5)
const DESK_POS := Vector3(3.0, 0.0, 10.3)

var root: Node3D


## Builds everything under `parent` and returns {"anchors": {...}, "display_tank": Tank3D}.
func build(parent: Node3D) -> Dictionary:
	root = Node3D.new()
	root.name = "Building"
	parent.add_child(root)
	_floors()
	_walls()
	_windows()
	_lights()
	_counter()
	_shelf()
	var display := _display_tank()
	_back_room()
	_signs()
	return {
		"anchors": {
			"door": Vector3(0, 0, -6.2),
			"shelf": Vector3(-4.7, 0, SHELF_POS.z),
			"display": Vector3(DISPLAY_POS.x, 0, -4.0),
			"counter": Vector3(-0.6, 0, -2.9),
			"start": Vector3(-0.6, 0.05, -0.4),
			"back_room": Vector3(0, 0.05, 3.6),
		},
		"display_tank": display,
	}


# --- Floors, walls, ceiling ---------------------------------------------------

func _floors() -> void:
	# Wood floor in the shop, pale tile in the back room, pavement outside.
	var shop_floor := BuildUtil.box(root, Vector3(0, -0.1, -1.25), Vector3(12.4, 0.2, 7.9), WOOD, true)
	shop_floor.material_override = _plank_material()
	BuildUtil.box(root, Vector3(0, -0.1, 6.95), Vector3(12.4, 0.2, 8.5), Color("#b9b2a4"), true)
	BuildUtil.box(root, Vector3(0, -0.12, -10.0), Vector3(30.0, 0.2, 9.6), Color("#a9a39a"), true)
	# Ceiling over both rooms.
	BuildUtil.box(root, Vector3(0, WALL_HEIGHT + 0.05, 3.0), Vector3(12.4, 0.1, 16.6), Color("#faf4ea"))


## Wood planks drawn into a small texture, tiled over the floor.
func _plank_material() -> StandardMaterial3D:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for row in 8:
		var shade := rng.randf_range(-0.07, 0.07)
		var c := WOOD.lightened(shade) if shade > 0.0 else WOOD.darkened(-shade)
		img.fill_rect(Rect2i(0, row * 32, 256, 32), c)
		img.fill_rect(Rect2i(0, row * 32, 256, 2), c.darkened(0.25))
		var seam := rng.randi_range(20, 230)
		img.fill_rect(Rect2i(seam, row * 32, 2, 32), c.darkened(0.25))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.uv1_scale = Vector3(5.0, 3.0, 1.0)
	mat.roughness = 0.85
	return mat


func _walls() -> void:
	var h := WALL_HEIGHT
	var mid := h * 0.5
	# Side walls and the back wall run the full length of the building.
	BuildUtil.box(root, Vector3(-6.1, mid, 3.0), Vector3(0.2, h, 16.4), CREAM, true)
	BuildUtil.box(root, Vector3(6.1, mid, 3.0), Vector3(0.2, h, 16.4), CREAM, true)
	BuildUtil.box(root, Vector3(0, mid, 11.1), Vector3(12.4, h, 0.2), CREAM, true)
	# Front wall with the door gap, and the divider with the back-room doorway.
	_wall_with_gap(-5.1, DOORWAY_HEIGHT)
	_wall_with_gap(DIVIDER_Z, DOORWAY_HEIGHT)
	# Teal panelling along the inside of the walls, and door frames.
	var panel := 0.95
	for side in [-1.0, 1.0]:
		BuildUtil.box(root, Vector3(side * 5.98, panel * 0.5, 3.0), Vector3(0.04, panel, 16.2), TEAL)
	BuildUtil.box(root, Vector3(0, panel * 0.5, 10.98), Vector3(12.0, panel, 0.04), TEAL)
	for z in [-5.1, DIVIDER_Z]:
		for side in [-1.0, 1.0]:
			BuildUtil.box(root, Vector3(side * (DOOR_HALF + 0.06), DOORWAY_HEIGHT * 0.5, z), Vector3(0.12, DOORWAY_HEIGHT, 0.3), TERRACOTTA)
		BuildUtil.box(root, Vector3(0, DOORWAY_HEIGHT + 0.06, z), Vector3(DOOR_HALF * 2.0 + 0.24, 0.12, 0.3), TERRACOTTA)
	for side in [-1.0, 1.0]:  # panelling on the two cross walls (not across the gaps)
		BuildUtil.box(root, Vector3(side * 3.6, panel * 0.5, -4.98), Vector3(4.8, panel, 0.04), TEAL)
		BuildUtil.box(root, Vector3(side * 3.6, panel * 0.5, 2.48), Vector3(4.8, panel, 0.04), TEAL)


## A wall across the building at `z` with a doorway (x -1..1) in it.
func _wall_with_gap(z: float, gap_height: float) -> void:
	var seg_len := 6.2 - DOOR_HALF
	for side in [-1.0, 1.0]:
		BuildUtil.box(root, Vector3(side * (DOOR_HALF + seg_len * 0.5), WALL_HEIGHT * 0.5, z),
			Vector3(seg_len, WALL_HEIGHT, 0.2), CREAM, true)
	var above := WALL_HEIGHT - gap_height
	BuildUtil.box(root, Vector3(0, gap_height + above * 0.5, z), Vector3(DOOR_HALF * 2.0, above, 0.2), CREAM, true)


## Pale blue panes on the walls, so the rooms don't feel like boxes.
func _windows() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("#bfe3f2")
	glass.emission_enabled = true
	glass.emission = Color("#9fd2e6")
	glass.emission_energy_multiplier = 0.6
	for spot in [Vector3(-5.97, 1.7, 0.0), Vector3(5.97, 1.7, -2.0), Vector3(5.97, 1.7, 0.6),
			Vector3(-5.97, 1.7, 6.0), Vector3(5.97, 1.7, 8.0)]:
		var pane := BuildUtil.box(root, spot, Vector3(0.03, 1.0, 1.4), Color.WHITE)
		pane.material_override = glass
		BuildUtil.box(root, spot + Vector3(signf(spot.x) * 0.02, 0, 0), Vector3(0.05, 1.12, 1.52), Color("#e8dcc8"))


func _lights() -> void:
	for spot in [Vector3(-3, 2.7, -2), Vector3(3, 2.7, -2), Vector3(0, 2.7, 1.2),
			Vector3(-3, 2.7, 5), Vector3(3, 2.7, 5), Vector3(-3, 2.7, 9), Vector3(3, 2.7, 9), Vector3(0, 2.7, 7)]:
		var light := OmniLight3D.new()
		light.position = spot
		light.omni_range = 8.0
		light.light_energy = 0.6
		light.light_color = Color("#fff1d6")
		root.add_child(light)
		# A little lamp shade so the light has a source.
		BuildUtil.box(root, spot + Vector3(0, 0.3, 0), Vector3(0.4, 0.06, 0.4), Color("#fff6e5"))


# --- Furniture ------------------------------------------------------------------

func _counter() -> void:
	var c := COUNTER_CENTRE
	BuildUtil.box(root, c + Vector3(0, 0.5, 0), COUNTER_SIZE, TERRACOTTA)
	BuildUtil.box(root, c + Vector3(0, 1.03, 0), Vector3(COUNTER_SIZE.x + 0.1, 0.06, COUNTER_SIZE.z + 0.12), WOOD.lightened(0.15))
	var body := Interactable.new()
	body.setup("counter", "Click: Counter", c + Vector3(0, 0.55, 0), Vector3(COUNTER_SIZE.x + 0.1, 1.1, COUNTER_SIZE.z + 0.12))
	root.add_child(body)
	# The till and the bell.
	BuildUtil.box(root, c + Vector3(1.5, 1.2, 0.05), Vector3(0.45, 0.28, 0.35), Color("#4a5568"))
	BuildUtil.box(root, c + Vector3(1.5, 1.38, 0.0), Vector3(0.3, 0.1, 0.2), Color("#9fd2e6"))
	BuildUtil.box(root, c + Vector3(-0.9, 1.09, 0.0), Vector3(0.12, 0.08, 0.12), Color("#e0b84f"))


func _shelf() -> void:
	var back_x := SHELF_POS.x - 0.37
	BuildUtil.box(root, Vector3(back_x, 1.05, SHELF_POS.z), Vector3(0.04, 2.1, 3.0), DARK_WOOD)
	for z in [-1.0, 1.0]:
		BuildUtil.box(root, Vector3(SHELF_POS.x - 0.12, 1.05, SHELF_POS.z + z * 1.5), Vector3(0.5, 2.1, 0.05), TEAL)
	for y in [0.1] + Array(ShelfStock.BOARDS):
		BuildUtil.box(root, Vector3(SHELF_POS.x - 0.12, y, SHELF_POS.z), Vector3(0.5, 0.04, 3.0), TEAL)
	var stock := ShelfStock.new()
	stock.position = SHELF_POS
	root.add_child(stock)
	var body := Interactable.new()
	body.setup("shelf", "Click: Shelf", Vector3(SHELF_POS.x - 0.12, 1.05, SHELF_POS.z), Vector3(0.5, 2.1, 3.1))
	root.add_child(body)
	BuildUtil.label(root, "Shop shelf", Vector3(SHELF_POS.x + 0.3, 2.35, SHELF_POS.z), 0.004)


func _display_tank() -> Node3D:
	var tank := Tank3D.new()
	tank.position = DISPLAY_POS
	root.add_child(tank)
	tank.setup(Fish.DISPLAY, Vector3(2.0, 0.8, 0.8), 0.7, "Display tank", "display_tank",
		"Click: Display tank", TEAL.darkened(0.25))
	return tank


func _back_room() -> void:
	var tanks := BackRoom3D.new()
	root.add_child(tanks)
	# A desk for the Lab, shows, gallery and staff.
	var p := DESK_POS
	BuildUtil.box(root, p + Vector3(0, 0.74, 0), Vector3(1.6, 0.06, 0.8), WOOD.lightened(0.1))
	for sx in [-1.0, 1.0]:
		BuildUtil.box(root, p + Vector3(sx * 0.72, 0.36, 0), Vector3(0.08, 0.72, 0.7), DARK_WOOD)
	BuildUtil.box(root, p + Vector3(0, 1.05, -0.1), Vector3(0.6, 0.4, 0.04), Color("#4a5568"))
	BuildUtil.box(root, p + Vector3(0, 1.05, -0.08), Vector3(0.54, 0.34, 0.02), Color("#9fd2e6"))
	BuildUtil.box(root, p + Vector3(-0.5, 0.82, 0.1), Vector3(0.3, 0.1, 0.22), Color("#f0e6d2"))
	var body := Interactable.new()
	body.setup("desk", "Click: Back room desk", p + Vector3(0, 0.6, 0), Vector3(1.7, 1.2, 0.85))
	root.add_child(body)
	BuildUtil.label(root, "Desk", p + Vector3(0, 1.5, 0), 0.004)


func _signs() -> void:
	# Facing +Z, readable from the shop side of the front wall.
	BuildUtil.label(root, "Fig Tree Fish Breeder", Vector3(0, 2.68, -4.96), 0.005, false)
	var back_sign := BuildUtil.label(root, "Back room", Vector3(0, 2.68, DIVIDER_Z - 0.12), 0.005, false)
	back_sign.rotation.y = PI  # faces the shop
	BuildUtil.label(root, "Shop floor", Vector3(0, 2.68, DIVIDER_Z + 0.12), 0.005, false)
