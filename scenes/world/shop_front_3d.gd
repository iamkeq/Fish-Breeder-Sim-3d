extends Node3D
## The shop improvements you can buy on the Market's Upgrades tab, as Synty models
## that appear when you buy them: Fresh Paint & Planters (window boxes), the Striped
## Awning, the Neon Fish Sign and the Comfy Reading Corner.

const Synty := preload("res://scenes/world/synty.gd")

const WINDOW_X := [-5.0, -2.5, 2.5, 5.0]  # centres of the front windows
const FRONT_Z := -5.2  # the outside face of the front wall

var _groups := {}  # upgrade id -> Node3D
var _solids := {}  # upgrade id -> Array of StaticBody3D


func _ready() -> void:
	_paint()
	_awning()
	_neon()
	_corner()
	Game.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for id in _groups:
		var on: bool = Game.state.has_upgrade(id)
		_groups[id].visible = on
		for body in _solids.get(id, []):
			body.collision_layer = 1 if on else 0


func _group(id: String) -> Node3D:
	var g := Node3D.new()
	g.name = id
	add_child(g)
	_groups[id] = g
	return g


func _solid(id: String, pos: Vector3, size: Vector3) -> void:
	var list: Array = _solids.get(id, [])
	list.append(Synty.solid(self, pos, size))
	_solids[id] = list


## Window boxes under every front window, outside, and a pot plant either side of the door.
func _paint() -> void:
	var g := _group("fresh_paint")
	for x in WINDOW_X:
		Synty.put(g, "City/Props/SM_Prop_PlanterWindow_01", Vector3(x, 0.85, FRONT_Z), 180.0)
	for x in [-1.9, 1.9]:
		Synty.put(g, "City/Props/SM_Prop_PotPlant_02", Vector3(x, 0.0, FRONT_Z - 0.4))


## An awning over every window and the door.
func _awning() -> void:
	var g := _group("striped_awning")
	for x in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		Synty.put(g, "Buildings/SM_Bld_Awning_01", Vector3(x, 0.0, FRONT_Z), 180.0)


## A fish-shaped sign over the street and an "open" neon in a window.
func _neon() -> void:
	var g := _group("neon_sign")
	Synty.put(g, "Props/SM_Prop_Sign_Fish_01", Vector3(3.9, 2.8, FRONT_Z - 0.3), 180.0, Vector3.ONE * 0.12)
	Synty.put(g, "Signs/SM_Sign_Neon_Open_01", Vector3(-2.5, 1.95, -4.9), 180.0)


## A sofa, small table, chair and bookcase in the left corner of the shop floor.
func _corner() -> void:
	var g := _group("reading_corner")
	Synty.put(g, "City/Props/SM_Prop_Couch_01", Vector3(-5.6, 0.0, 0.6), 90.0)
	_solid("reading_corner", Vector3(-5.6, 0.45, 0.6), Vector3(1.1, 0.9, 1.8))
	Synty.put(g, "Props/SM_Prop_Cafe_Table_Small_01", Vector3(-4.4, 0.0, 0.6))
	Synty.put(g, "Props/SM_Prop_Cafe_Chair_01", Vector3(-4.4, 0.0, 1.5), 180.0)
	_solid("reading_corner", Vector3(-4.4, 0.45, 0.9), Vector3(0.9, 0.9, 1.6))
	Synty.put(g, "Props/SM_Prop_Shop_Shelf_Basic_02", Vector3(-3.4, 0.0, 2.15), 180.0)
	_solid("reading_corner", Vector3(-3.4, 1.1, 2.15), Vector3(1.9, 2.2, 0.7))
