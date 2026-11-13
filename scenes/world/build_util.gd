extends RefCounted
## Small helpers for the 3D shop. (The models themselves come from Synty: see synty.gd.)


## A text label that always faces the player (or fixed, facing +Z, if not billboard).
static func label(parent: Node, text: String, pos: Vector3, pixel_size: float = 0.004, billboard: bool = true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = pixel_size
	l.font_size = 64
	l.outline_size = 12
	l.modulate = Color("#fffaf0")
	l.outline_modulate = Color("#3d3a36")
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l
