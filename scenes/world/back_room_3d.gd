extends Node3D
## The tanks of the back room: one per breeding tank (rebuilt when you buy
## another, up to 10) in two rows along the side walls, plus the holding tank
## on the back wall. Each has a label over it.

const Tank3D := preload("res://scenes/world/tank_3d.gd")

const TANK_SIZE := Vector3(1.2, 0.6, 0.55)
const STAND_HEIGHT := 0.78
const PER_WALL := 5
## Where the holding tank stands (the back wall) and the walls the rows sit against.
const HOLDING_POS := Vector3(0.0, 0.0, 10.2)
const WALL_X := 5.3
const FIRST_Z := 4.2
const SPACING := 1.5

var _tanks: Array[Node3D] = []
var _count := -1


func _ready() -> void:
	var holding := Tank3D.new()
	holding.position = HOLDING_POS
	add_child(holding)
	holding.setup(Fish.HOLDING, Vector3(1.5, 0.6, 0.55), STAND_HEIGHT, "Holding", "tank",
		"Click: Holding tank", Color("#74a99a"))
	Game.changed.connect(_sync)
	_sync()


## Where breeding tank `index` (0-based) stands: the first five down the left
## wall, the rest down the right wall, all facing into the room.
static func slot_position(index: int) -> Vector3:
	var side := -1.0 if index < PER_WALL else 1.0
	return Vector3(side * WALL_X, 0.0, FIRST_Z + SPACING * float(index % PER_WALL))


func _sync() -> void:
	var count := Game.state.breeding_tanks.size()
	if count == _count:
		return
	_count = count
	for tank in _tanks:
		tank.queue_free()
	_tanks.clear()
	for i in mini(count, PER_WALL * 2):
		var tank := Tank3D.new()
		tank.position = slot_position(i)
		tank.rotation.y = PI * 0.5  # long side along the wall
		add_child(tank)
		tank.setup(Fish.breeding_location(i), TANK_SIZE, STAND_HEIGHT, "Tank %d" % (i + 1), "tank",
			"Click: Tank %d" % (i + 1), Color("#8a6a4f"))
		_tanks.append(tank)
