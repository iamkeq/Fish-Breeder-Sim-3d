extends Node3D
## The 3D shop: the building, the player, the customer, and the 2D game's top
## bar and menus (hud.tscn) laid over it. This script ties them together and
## owns the mouse: captured while you walk, free while a menu is open or after
## you press Esc (click the game to capture it again).

const ShopBuilder := preload("res://scenes/world/shop_builder.gd")
const Player := preload("res://scenes/world/player.gd")
const CustomerManager := preload("res://scenes/world/customer_manager.gd")
const HUD_SCENE := preload("res://scenes/world/hud.tscn")

## Set to false (before adding to the tree) for scripts that shouldn't grab the mouse.
var capture_mouse := true

var player: CharacterBody3D
var hud: Control
var anchors: Dictionary = {}
var display_tank: Node3D

var _prompt: Label
var _crosshair: ColorRect
## False after you pressed Esc: stay free until you click the game again.
var _want_capture := true
var _was_blocked := false


func _ready() -> void:
	_build_environment()
	var built := ShopBuilder.new().build(self)
	anchors = built["anchors"]
	display_tank = built["display_tank"]
	player = Player.new()
	add_child(player)
	player.place(anchors["start"], 0.0)
	var customers := CustomerManager.new()
	customers.anchors = anchors
	add_child(customers)
	_build_ui()
	if capture_mouse and not OS.has_feature("web") and not hud.overlay_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # the web build waits for a click


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#cfe3ea")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff3e0")
	env.ambient_light_energy = 0.6
	var holder := WorldEnvironment.new()
	holder.environment = env
	add_child(holder)


func _build_ui() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 0
	add_child(overlay)
	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.85)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -3
	_crosshair.offset_right = 3
	_crosshair.offset_top = -3
	_crosshair.offset_bottom = 3
	overlay.add_child(_crosshair)
	_prompt = Label.new()
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.08))
	_prompt.add_theme_constant_override("outline_size", 6)
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 0.5
	_prompt.anchor_bottom = 0.5
	_prompt.offset_left = -200
	_prompt.offset_right = 200
	_prompt.offset_top = 16
	_prompt.offset_bottom = 46
	overlay.add_child(_prompt)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	hud = HUD_SCENE.instantiate()
	hud_layer.add_child(hud)


func _process(_delta: float) -> void:
	var blocked: bool = hud.overlay_open()
	if blocked != _was_blocked:
		_was_blocked = blocked
		if blocked:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # a menu needs the mouse
		elif _want_capture and capture_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	player.active = captured and not blocked
	_crosshair.visible = player.active
	_prompt.text = ""
	if player.active:
		var target = player.look_target()
		if target != null:
			_prompt.text = target.prompt


func _unhandled_input(event: InputEvent) -> void:
	if hud.overlay_open():
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel") and captured:
		_want_capture = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		interact()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if captured:
			interact()
		else:
			_want_capture = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Click or E: open whatever the crosshair is on.
func interact() -> void:
	if not player.active:
		return
	var target = player.look_target()
	if target != null:
		open_target(target)


## Opens the menu for a clickable thing (also used by tests and previews).
func open_target(target) -> void:
	match target.kind:
		"display_tank":
			hud.open_display_tank()
		"tank":
			hud.open_tank(target.arg)
		"counter", "customer":
			hud.open_counter()
		"shelf":
			hud.open_market()
		"desk":
			hud.open_desk()
