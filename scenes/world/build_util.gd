extends RefCounted
## Tiny helpers for building the shop out of primitives.

static var _materials := {}


## A plain matte material for a colour (shared between everything of that colour).
static func material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(true), roughness]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		if color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = m
	return _materials[key]


## A box mesh centred on `pos`; `solid` also gives it a collider for the player.
static func box(parent: Node, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material(color)
	inst.position = pos
	parent.add_child(inst)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		shape.shape = s
		body.add_child(shape)
		inst.add_child(body)
	return inst


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
