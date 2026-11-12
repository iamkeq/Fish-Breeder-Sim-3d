extends Node3D
## Small coloured boxes on the retail shelf, one cell per item in stock (up to
## four boxes in a cell, so a full cell means "plenty"). Refreshes on
## Game.changed. The node sits at the shelf's front face; boxes face +X.

const BuildUtil := preload("res://scenes/world/build_util.gd")

## Board heights and cells along the shelf (z).
const BOARDS := [0.55, 1.0, 1.45, 1.9]
const CELLS_PER_BOARD := 8
const CELL_WIDTH := 0.36
const BOX := 0.16
## Items without a `color` in data (decor, plants) get a colour by category.
const CATEGORY_COLORS := {"rock": "#8f8f8f", "plant": "#5fa05a", "decor": "#d98a6a", "driftwood": "#8a6a4f"}


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
		var item: Dictionary = Game.db.items[id]
		var color := Color(item.get("color", CATEGORY_COLORS.get(item.get("category", ""), "#b0a090")))
		var board: int = cell / CELLS_PER_BOARD
		var along: int = cell % CELLS_PER_BOARD
		var z := (float(along) - (CELLS_PER_BOARD - 1) * 0.5) * CELL_WIDTH
		for k in mini(int(stock[id]), 4):
			var dz := (float(k % 2) - 0.5) * (BOX + 0.02)
			var dy := float(k / 2) * (BOX + 0.01)
			BuildUtil.box(self, Vector3(-0.12, BOARDS[board] + 0.03 + BOX * 0.5 + dy, z + dz),
				Vector3(BOX, BOX, BOX), color)
		cell += 1
