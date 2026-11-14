extends Node
## Renders the game's logo from the game's own models: Synty's 3D sign letters spelling
## FISH BREEDING / STORE, a "SIM 3D" name plate, and guppies from the game's sprite sheet
## swimming round the words. Writes, into art/:
##   logo.png        1600 x 900, transparent background
##   cover.png       630 x 500, the logo over the shop front (itch.io cover image)
##   icon_square.png 512 x 512, the logo over the shop front, square
##
##   godot --path . --resolution 1280x720 res://tools/make_logo.tscn
## (needs a window: it renders on the GPU). Never touches the save file.

const Synty := preload("res://scenes/world/synty.gd")
const BuildUtil := preload("res://scenes/world/build_util.gd")
const FishArt := preload("res://scenes/world/fish_art.gd")
const UI := preload("res://scenes/ui/ui_kit.gd")

const OUT := "res://art/"
const LETTER := "Signs/SM_Sign_3dText_Letter_"
const LINES := [["FISH BREEDING", Color("#f39a3c")], ["STORE", Color("#36b3a8")]]
const LETTER_GAP := 0.05
const SPACE := 0.32
const LINE_HEIGHT := 0.86
const EDGE := Color("#4a2a17")  # the darker rim behind each letter
## Guppies round the words: variety, position, size, facing right.
const FISH := [
	["red", Vector3(-3.25, 0.62, 0.35), 1.15, true], ["blue", Vector3(3.15, 0.95, 0.35), 1.05, false],
	["yellow", Vector3(-2.3, -0.95, 0.4), 0.95, true], ["black", Vector3(0.0, -1.35, 0.4), 1.0, false],
	["orange", Vector3(-0.35, 1.25, 0.3), 0.8, true],
]


func _ready() -> void:
	Game.persist = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var logo_view := _logo_viewport(Vector2i(1600, 900))
	add_child(logo_view)
	# The shop front, from the street, as a backdrop for the cover.
	var world: Node = load("res://scenes/world/world.tscn").instantiate()
	world.capture_mouse = false
	add_child(world)
	await get_tree().process_frame
	world.hud.visible = false
	world.player.place(Vector3(0, 0.05, -9.0), PI, deg_to_rad(14))
	for i in 12:
		await get_tree().process_frame
	var logo := logo_view.get_texture().get_image()
	logo.convert(Image.FORMAT_RGBA8)
	logo.save_png(OUT + "logo.png")
	var street := get_viewport().get_texture().get_image()
	street.convert(Image.FORMAT_RGBA8)
	_compose(street, logo, Vector2i(630, 500), "cover.png")
	_compose(street, logo, Vector2i(512, 512), "icon_square.png")
	print("make_logo: wrote art/logo.png, art/cover.png, art/icon_square.png")
	get_tree().quit()


## The street picture cropped to `size`, softened a little, with the logo on top.
func _compose(street: Image, logo: Image, size: Vector2i, file: String) -> void:
	var aspect := float(size.x) / float(size.y)
	var src_h := street.get_height()
	var src_w := int(src_h * aspect)
	var crop := street.get_region(Rect2i((street.get_width() - src_w) / 2, 0, src_w, src_h))
	crop.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	# A warm wash so the words stand out.
	for y in size.y:
		for x in size.x:
			var c := crop.get_pixel(x, y)
			crop.set_pixel(x, y, c.lerp(Color("#fff3df"), 0.35))
	var l := logo.duplicate()
	var w := int(size.x * 0.96)
	l.resize(w, int(w * float(logo.get_height()) / float(logo.get_width())), Image.INTERPOLATE_LANCZOS)
	var at := Vector2i((size.x - l.get_width()) / 2, (size.y - l.get_height()) / 2)
	crop.blend_rect(l, Rect2i(Vector2i.ZERO, l.get_size()), at)
	crop.save_png(OUT + file)


func _logo_viewport(size: Vector2i) -> SubViewport:
	var view := SubViewport.new()
	view.size = size
	view.transparent_bg = true
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1d8")
	env.ambient_light_energy = 0.55
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	view.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	view.add_child(sun)
	var words := Node3D.new()
	view.add_child(words)
	for i in LINES.size():
		_word_line(words, LINES[i][0], LINES[i][1], LINE_HEIGHT * (0.5 - i), 1.0 if i == 0 else 1.25)
	BuildUtil.sign(words, "SIM 3D", Vector3(2.35, -LINE_HEIGHT * 0.5 - 0.2, 0.15), -4.0, 0.42)
	for f in FISH:
		_guppy(words, f[0], f[1], f[2], f[3])
	words.rotation_degrees = Vector3(6, -8, 0)
	var camera := Camera3D.new()
	camera.fov = 32.0
	camera.position = Vector3(0, -0.05, 7.6)
	view.add_child(camera)
	return view


## One line of Synty 3D letters, centred on x = 0 at height `y`.
func _word_line(parent: Node3D, text: String, color: Color, y: float, size: float) -> void:
	var face := StandardMaterial3D.new()
	face.albedo_color = color
	face.roughness = 0.55
	var rim := StandardMaterial3D.new()
	rim.albedo_color = EDGE
	rim.roughness = 0.9
	var pieces := []
	var width := 0.0
	for ch in text:
		if ch == " ":
			pieces.append(null)
			width += SPACE * size
			continue
		var letter := Synty.make(LETTER + ch)
		var b := Synty.bounds(letter)
		pieces.append([letter, b])
		width += (b.size.x + LETTER_GAP) * size
	var x := -width * 0.5
	for piece in pieces:
		if piece == null:
			x += SPACE * size
			continue
		var letter: Node3D = piece[0]
		var b: AABB = piece[1]
		Synty.paint(letter, face)
		letter.scale = Vector3.ONE * size
		letter.position = Vector3(x - b.position.x * size, y - 0.36 * size, 0)
		parent.add_child(letter)
		# A darker, slightly bigger copy behind, for a chunky rim.
		var back := Synty.make(LETTER + text[pieces.find(piece)])
		Synty.paint(back, rim)
		back.scale = Vector3(size * 1.12, size * 1.1, size * 1.4)
		back.position = letter.position + Vector3(-b.size.x * size * 0.06, -0.045, -0.07)
		parent.add_child(back)
		x += (b.size.x + LETTER_GAP) * size


## A guppy card from the game's sprite sheet.
func _guppy(parent: Node3D, variety: String, pos: Vector3, size: float, right: bool) -> void:
	var species: Dictionary = Game.db.species["guppy"]
	var f := Fish.new()
	f.species_id = "guppy"
	f.traits = {"variety": variety}
	f.age_days = int(species.get("days_to_adult", 3))
	var art := FishArt.frame(f, species, right, false, 0.0)
	if art.is_empty():
		return
	var sprite := Sprite3D.new()
	sprite.texture = UI.sheet_texture(art["sheet"])
	sprite.region_enabled = true
	sprite.region_rect = art["rect"]
	sprite.flip_h = art["flip"]
	sprite.modulate = art["tint"]
	sprite.pixel_size = 0.0105 * size
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.position = pos
	parent.add_child(sprite)
