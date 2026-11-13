extends Control
## One tank in a menu: a live view of the real 3D tank (Synty tank model, substrate, decor and
## swimming fish) in a little 3D world of its own. In the tank editor it also draws the slot
## markers over the picture and reports clicks on them.

const Tank3D := preload("res://scenes/world/tank_3d.gd")
const UI := preload("res://scenes/ui/ui_kit.gd")

## Back row first so the front row is drawn on top. x is a fraction of the water width.
const SLOT_X := [0.24, 0.74, 0.1, 0.52, 0.34, 0.88]
const ROW_LIFT := {"back": 14.0, "mid": 6.0, "front": -2.0}
## The tank model's whole height (cabinet and lid) before stretching, and the footprint shown.
const MODEL_HEIGHT := 1.341
const SHOWN_FOOTPRINT := Vector3(1.5, 0.8, 0.62)

const GLASS := Color("#d7eef5")
const FRAME := Color("#5b6b73")
const WATER_TOP := Color("#a6d8e8")
const WATER_BOTTOM := Color("#5fa9c4")
const EMPTY_TEXT := Color("#7a6e64")
const SUBSTRATE_HEIGHT := 22.0

## Fish.DISPLAY, or a breeding tank location ("breeding", "breeding2", ...).
@export var location: String = "display"
## Editor preview: faint markers on empty slots, and a pulsing ring on
## `highlight_slot` (-1 = the substrate, -2 = nothing).
## Emitted in editor mode when a slot marker (or the substrate, -1) is clicked.
signal slot_clicked(slot: int)

var show_slot_markers: bool = false
var highlight_slot: int = -2

const HIGHLIGHT := Color("#e07a4f")
const SLOT_SHORT := ["B1", "B2", "M1", "M2", "F1", "F2"]

var _pulse := 0.0
var _container: SubViewportContainer
var _viewport: SubViewport
var _camera: Camera3D
var _tank3d: Node3D


func _ready() -> void:
	clip_contents = true
	_build_view()
	Game.changed.connect(refresh)
	resized.connect(_on_resized)
	refresh()


## The little 3D world: sunlit room colours, an upright orthogonal camera and the tank.
func _build_view() -> void:
	_container = SubViewportContainer.new()
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_container.add_child(_viewport)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1d8")
	env.ambient_light_energy = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	sun.light_energy = 0.7
	_viewport.add_child(sun)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_viewport.add_child(_camera)
	_build_tank()


func _build_tank() -> void:
	if _tank3d != null:
		_tank3d.queue_free()
	_tank3d = Tank3D.new()
	_viewport.add_child(_tank3d)
	_tank3d.setup(location, SHOWN_FOOTPRINT, 0.0, "", "", "", Color.WHITE)
	_tank3d.hide_label()
	_frame_camera()


## Frame the whole tank (cabinet and all) in the control, keeping it centred.
func _frame_camera() -> void:
	if _camera == null or _tank3d == null:
		return
	var scale_y: float = _tank3d.stand_height / 0.70
	var glass_top := MODEL_HEIGHT * scale_y
	var bottom: float = _tank3d.stand_height - 0.16 * scale_y  # a little cabinet under the glass
	var aspect := maxf(size.x, 1.0) / maxf(size.y, 1.0)
	_camera.size = maxf((glass_top - bottom) * 1.06, SHOWN_FOOTPRINT.x * 1.08 / aspect)
	_camera.position = Vector3(0, (glass_top + bottom) * 0.5, 4.0)
	_camera.rotation = Vector3.ZERO


func tank() -> Tank:
	return Game.state.tank_at(location)


func water_rect() -> Rect2:
	return Rect2(Vector2(10, 26), size - Vector2(20, 36))


func swim_rect() -> Rect2:
	var w := water_rect()
	return Rect2(w.position + Vector2(0, 14), w.size - Vector2(0, 14 + SUBSTRATE_HEIGHT + 6))


func refresh() -> void:
	queue_redraw()


func _on_resized() -> void:
	_frame_camera()
	queue_redraw()


func _draw() -> void:
	var t := tank()
	var font := get_theme_default_font()
	if t == null and location != Fish.HOLDING:
		var r := Rect2(Vector2(10, 26), size - Vector2(20, 36))
		draw_rect(r, EMPTY_TEXT, false, 2.0)
		draw_string(font, Vector2(r.position.x, r.get_center().y), "No tank on display",
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, EMPTY_TEXT)
		return
	if show_slot_markers and t != null:
		_draw_slot_markers(t, water_rect(), font)


## Where a slot's decor stands on the picture (the 3D position, projected through the camera).
func _slot_base(t: Tank, slot: int, w: Rect2) -> Vector2:
	var row: String = t.row_of(slot)
	if _camera != null and _tank3d != null and _camera.is_inside_tree():
		return _camera.unproject_position(_tank3d.to_global(_tank3d.decor_base(slot, row)))
	return Vector2(w.position.x + w.size.x * SLOT_X[slot], w.end.y - SUBSTRATE_HEIGHT * 0.5 - ROW_LIFT[row])


func _process(delta: float) -> void:
	if show_slot_markers:
		_pulse += delta
		queue_redraw()


## Where the editor marker for a slot sits (above the item's base).
func slot_marker_position(slot: int) -> Vector2:
	var t := tank()
	var w := water_rect()
	return _slot_base(t, slot, w) + Vector2(0, -16)


func _draw_slot_markers(t: Tank, w: Rect2, font: Font) -> void:
	for slot in t.slot_count():
		var p := slot_marker_position(slot)
		if t.is_slot_empty(slot):
			draw_circle(p, 13.0, Color(1, 1, 1, 0.35))
			draw_arc(p, 13.0, 0.0, TAU, 24, Color(1, 1, 1, 0.8), 1.5, true)
			draw_string(font, p + Vector2(-13, 5), SLOT_SHORT[slot], HORIZONTAL_ALIGNMENT_CENTER, 26, 12, Color(0.2, 0.3, 0.35))
		if slot == highlight_slot:
			var r := 18.0 + sin(_pulse * 5.0) * 2.5
			draw_arc(p, r, 0.0, TAU, 32, HIGHLIGHT, 3.0, true)
	if highlight_slot == -1:
		var band := Rect2(w.position.x + 2, w.end.y - SUBSTRATE_HEIGHT - 4, w.size.x - 4, SUBSTRATE_HEIGHT + 2)
		var a := 0.6 + 0.4 * sin(_pulse * 5.0)
		draw_rect(band, Color(HIGHLIGHT, a), false, 3.0)


func _gui_input(event: InputEvent) -> void:
	if not show_slot_markers or tank() == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var t := tank()
		var best := -2
		var best_dist := 26.0
		for slot in t.slot_count():
			var d: float = slot_marker_position(slot).distance_to(event.position)
			if d < best_dist:
				best = slot
				best_dist = d
		if best == -2 and event.position.y > water_rect().end.y - SUBSTRATE_HEIGHT - 6:
			best = -1
		if best != -2:
			slot_clicked.emit(best)
			accept_event()


## Show a different tank (e.g. switching breeding-tank tabs).
func set_location(new_location: String) -> void:
	if new_location == location:
		return
	location = new_location
	_build_tank()
	refresh()
