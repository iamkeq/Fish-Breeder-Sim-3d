extends StaticBody3D
## A solid thing the player can look at and click. `kind` says what it opens
## (see world.gd), `arg` carries a tank location when needed, `prompt` is the
## hint shown under the crosshair.

var kind := ""
var arg := ""
var prompt := ""


## Adds a box-shaped collider (centre `centre`, size `size`) and returns self.
## Furniture lives on layer 1 (solid for the player too); people on layer 2.
func setup(p_kind: String, p_prompt: String, centre: Vector3, size: Vector3, p_arg: String = "", layer: int = 1) -> StaticBody3D:
	kind = p_kind
	prompt = p_prompt
	arg = p_arg
	collision_layer = layer
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = centre
	add_child(shape)
	return self
