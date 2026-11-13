extends Node3D
## Synty product models on the retail shelf, one cell per item in stock (up to four
## in a cell, so a full cell means "plenty"). Refreshes on Game.changed. The node sits
## at the middle of the shelving unit; products face +X (into the shop).

const Synty := preload("res://scenes/world/synty.gd")

## Top of each board of the shelving unit, and the cells along the shelf (z).
const BOARDS := [0.40, 1.10, 1.76]
const CELLS_PER_BOARD := 8
const CELL_WIDTH := 0.36
const PRODUCT_COUNT := 49
const MAX_HEIGHT := 0.3
const MAX_WIDTH := 0.16


func _ready() -> void:
	Game.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for child in get_children():
		child.queue_free()
	var stock := Game.state.inventory.stock()
	var ids := stock.keys()
	ids.sort_custom(func(a, b): return Game.db.items[a]["name"] < Game.db.items[b]["name"])
	var cell := 0
	for id in ids:
		if cell >= BOARDS.size() * CELLS_PER_BOARD:
			break
		var board: int = cell / CELLS_PER_BOARD
		var along: int = cell % CELLS_PER_BOARD
		var z := (float(along) - (CELLS_PER_BOARD - 1) * 0.5) * CELL_WIDTH
		var model := "Products/SM_Prop_Product_%02d" % (absi(String(id).hash()) % PRODUCT_COUNT + 1)
		for k in mini(int(stock[id]), 4):
			var product := Synty.make(model)
			var b := Synty.bounds(product)
			if b.size.y <= 0.0:
				product.free()
				continue
			var s := minf(MAX_HEIGHT / b.size.y, MAX_WIDTH / maxf(b.size.x, b.size.z))
			var dz := (float(k % 2) - 0.5) * 0.17
			var dy := float(k / 2) * (b.size.y * s + 0.02)
			product.scale = Vector3.ONE * s
			product.rotation_degrees.y = 90.0
			product.position = Vector3(0.1, float(BOARDS[board]) + dy - b.position.y * s, z + dz)
			add_child(product)
		cell += 1
