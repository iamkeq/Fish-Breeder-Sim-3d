extends Node3D
## Shows the shop's one customer as a walking person. The rules are untouched:
## this only mirrors Game.state.customer (door -> shelf or display tank ->
## counter -> door). A shelf customer is served here, through the same
## Game.serve_customer(), when they reach the counter.

const Customer3D := preload("res://scenes/world/customer_3d.gd")
const CustomerPath := preload("res://scenes/world/customer_path.gd")

## Stop name -> position: "door", "shelf", "display", "counter".
var anchors: Dictionary = {}

var _current: Node3D  # the person for Game.state.customer, if any
var _kind := ""
var _name := ""
## False for the first sync: someone already waiting when the world loads.
var _live := false


func _ready() -> void:
	Game.customer_changed.connect(_sync)
	_sync()
	_live = true


func _sync() -> void:
	var c: Dictionary = Game.state.customer
	if c.is_empty():
		_send_off()
		return
	if _current != null and _name == c["name"] and _kind == c["kind"]:
		return
	_send_off()
	_spawn(c)


func _spawn(c: Dictionary) -> void:
	_kind = c["kind"]
	_name = c["name"]
	var person := Customer3D.new()
	add_child(person)
	person.setup(_name, hash(_name) + int(Game.state.day))
	_current = person
	if not _live:  # already waiting at the counter
		person.global_position = anchors["counter"]
		person.rotation.y = PI
		return
	person.global_position = anchors["door"]
	person.go(route_for(_kind, anchors))
	person.route_done.connect(_on_route_done.bind(person))


## The stops for a customer kind, turned into positions (the counter stop makes
## them face the player behind it).
static func route_for(kind: String, spots: Dictionary) -> Array:
	var stops := []
	for step in CustomerPath.steps(kind):
		var stop := {"pos": spots[step["at"]], "stop": step["at"], "pause": step["pause"]}
		if step["at"] == "counter":
			stop["face"] = Vector3(0, 0, 1)
		stops.append(stop)
	return stops


## They've left the counter (served, declined or walked out): head for the door.
func _send_off() -> void:
	if _current == null:
		return
	var person := _current
	_current = null
	_kind = ""
	_name = ""
	person.leave(anchors["door"])
	person.route_done.connect(person.queue_free)


func _on_route_done(person: Node3D) -> void:
	if person != _current:
		return
	if CustomerPath.pays_automatically(_kind):
		_serve_at_counter()


## A shelf customer pays now, exactly like clicking "Sell": same Game call,
## and the same ding and toast the 2D shop gave when this happened instantly.
func _serve_at_counter() -> void:
	var c: Dictionary = Game.state.customer.duplicate()
	if c.is_empty():
		return
	var earned := Game.serve_customer()
	if earned > 0:
		Game.auto_sale.emit(Game.db.items[c["item_id"]]["name"], earned)
