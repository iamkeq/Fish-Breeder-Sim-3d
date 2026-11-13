extends "res://scenes/main.gd"
## The 2D game's top bar and menus, laid over the 3D world. Everything in
## main.gd (clock, money, toasts, day summary, goals, market, tank editor, new
## game...) is reused as it is. What changes: the room switch buttons go away
## (you walk now) and the shop floor, back room and orders room open as a
## panel when you click the counter, a tank or the Orders button.

const RoomOverlay := preload("res://scenes/world/room_overlay.gd")
const UI_KIT := preload("res://scenes/ui/ui_kit.gd")
const ShopFront := preload("res://scenes/shop_front.gd")

const COUNTER_SIZE := Vector2(360, 540)
const DISPLAY_SIZE := Vector2(800, 540)
const WIDE_SIZE := Vector2(1200, 540)

var _room_overlay: ColorRect
var _rooms: Control
var _desk_box: VBoxContainer


func _init() -> void:
	ShopFront.enabled = false  # the shop shows its own improvements


func _ready() -> void:
	super._ready()
	$Background.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks and mouse look reach the 3D world
	$Margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Margin/Layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_button.visible = false
	_back_room_button.visible = false
	_orders_button.toggle_mode = false
	_orders_button.button_group = null
	_hint.visible = false
	_rooms = _shop_floor.get_parent()
	_room_overlay = RoomOverlay.new()
	add_child(_room_overlay)
	move_child(_room_overlay, 2)  # under the other menus, so they close first on Esc
	_room_overlay.adopt(_rooms)
	_desk_box = VBoxContainer.new()
	_desk_box.add_theme_constant_override("separation", 8)
	_room_overlay.adopt(_desk_box)


## True while any menu, panel or the new-game screen is up.
func overlay_open() -> bool:
	for child in get_children():
		if child is ColorRect and child.visible:
			return true
	return false


# --- Opening things from the world ---------------------------------------------

## The counter: whoever is waiting, back-orders and orders.
func open_counter() -> void:
	_show_columns(false, false, true)
	_open_rooms(_shop_floor, "Counter", COUNTER_SIZE)


## The display tank: its fish, with move / name / favourite, and Edit tank.
func open_display_tank(location: String = Fish.DISPLAY) -> void:
	_shop_floor._display_loc = location if Game.state.has_second_display() else Fish.DISPLAY
	_shop_floor.refresh()
	_show_columns(false, true, false)
	_open_rooms(_shop_floor, "Display tank", DISPLAY_SIZE)


## A breeding tank by location, or the holding tank.
func open_tank(location: String) -> void:
	_back_room.show_tank(-1 if location == Fish.HOLDING else Fish.breeding_index(location))
	_open_rooms(_back_room, "Back room", WIDE_SIZE)


func open_market() -> void:
	_fish_market.open()


## Lab, shows, gallery, breeding book and staff.
func open_desk() -> void:
	for child in _desk_box.get_children():
		child.queue_free()
	var state := Game.state
	_desk_button("Lab", state.lab_unlocked(), "Reach '%s' to open the Lab" % state.unlock_level_name("lab"),
		func(): Game.lab_requested.emit())
	_desk_button("Fish Show", state.shows_unlocked(), "Reach '%s' to open fish shows" % state.unlock_level_name("fish_show"),
		func(): Game.fish_show_requested.emit())
	_desk_button("Goals", true, "", func(): _goals.open())
	_desk_button("Gallery", true, "", func(): Game.gallery_requested.emit())
	_desk_button("Breeding book", true, "", func(): _book.open())
	_desk_button("Staff", state.staff_unlocked(), "Reach '%s' to hire staff" % state.unlock_level_name("staff"),
		func(): Game.staff_requested.emit())
	_room_overlay.show_content(_desk_box, "Back room desk", Vector2(300, 0))


func _desk_button(text: String, unlocked: bool, locked_tip: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.disabled = not unlocked
	b.tooltip_text = "" if unlocked else locked_tip
	b.pressed.connect(func():
		_room_overlay.close()
		action.call())
	_desk_box.add_child(b)


# --- Room panel ---------------------------------------------------------------

## The top bar's Orders button (and "Build in Orders room" on the counter).
func _show_room(room: Control) -> void:
	_open_rooms(room, "Orders" if room == _orders_room else "Back room", WIDE_SIZE)


func _show_columns(shelf: bool, tank: bool, counter: bool) -> void:
	_shop_floor.get_node("Columns/ShelfPanel").visible = shelf
	_shop_floor.get_node("Columns/TankColumn").visible = tank
	_shop_floor.get_node("Columns/CounterPanel").visible = counter


func _open_rooms(room: Control, title: String, min_size: Vector2) -> void:
	_shop_floor.visible = room == _shop_floor
	_back_room.visible = room == _back_room
	_orders_room.visible = room == _orders_room
	_room_overlay.show_content(_rooms, title, min_size)


# --- Overrides of main.gd -------------------------------------------------------

## The shop bell rings for everyone except shelf customers, who pay by themselves.
func _on_customer_arrived() -> void:
	if str(Game.state.customer.get("kind", "")) != "item":
		_bell.play()


func _on_day_ended(summary: Dictionary) -> void:
	_room_overlay.close()
	super._on_day_ended(summary)
