extends "res://tests/test_case.gd"
## The pure helpers behind the 3D world: customer routes, sprite frame choice
## and the back-room tank layout.

const CustomerPath := preload("res://scenes/world/customer_path.gd")
const CustomerManager := preload("res://scenes/world/customer_manager.gd")
const FishArt := preload("res://scenes/world/fish_art.gd")
const BackRoom3D := preload("res://scenes/world/back_room_3d.gd")

const SPECIES := {
	"days_to_adult": 4,
	"sprites": {
		"sheet": "res://assets/fish/guppy_sheet.png", "trait": "variety", "scale": 0.8, "fps": 10,
		"varieties": {"red": [10, 20, 30, 40], "blue": [50, 60, 30, 40]},
		"animations": {"red": {"swim_right": [[0, 0, 5, 5], [5, 0, 5, 5]], "swim_left": [[0, 10, 5, 5]]}},
		"placeholders": {"pink": {"base": "red", "tint": "#ff80c0"}},
	},
}


func _stops(kind: String) -> Array:
	return CustomerPath.steps(kind).map(func(s): return s["at"])


func test_item_customers_browse_the_shelf_then_pay() -> void:
	assert_eq(_stops("item"), ["shelf", "counter"])
	assert_true(CustomerPath.pays_automatically("item"))


func test_fish_collector_and_tank_customers_look_at_the_display_tank() -> void:
	for kind in ["fish", "collector", "tank"]:
		assert_eq(_stops(kind), ["display", "counter"], kind)
		assert_false(CustomerPath.pays_automatically(kind), kind)


func test_everyone_else_goes_straight_to_the_counter() -> void:
	for kind in ["request", "wish_item", "wish_fish", "browse"]:
		assert_eq(_stops(kind), ["counter"], kind)
		assert_false(CustomerPath.pays_automatically(kind), kind)


func test_every_route_ends_at_the_counter() -> void:
	for kind in ["item", "fish", "collector", "tank", "request", "wish_item", "wish_fish", "browse", "unknown"]:
		assert_eq(CustomerPath.steps(kind).back()["at"], "counter", kind)


func test_route_maps_stops_to_positions_and_faces_the_player_at_the_counter() -> void:
	var spots := {"door": Vector3(0, 0, -6), "shelf": Vector3(-4, 0, -2), "display": Vector3(3, 0, -4), "counter": Vector3(-1, 0, -3)}
	var route: Array = CustomerManager.route_for("item", spots)
	assert_eq(route.size(), 2)
	assert_eq(route[0]["pos"], Vector3(-4, 0, -2))
	assert_eq(route[0]["pause"], 1.0)
	assert_eq(route[1]["pos"], Vector3(-1, 0, -3))
	assert_true(route[1].has("face"))
	assert_false(route[0].has("face"))


func test_fish_frame_uses_the_variety_rect_and_flips_when_facing_left() -> void:
	var f := Fish.new()
	f.traits = {"variety": "blue"}
	var right := FishArt.frame(f, SPECIES, true, false, 0.0)
	assert_eq(right["rect"], Rect2(50, 60, 30, 40))
	assert_false(right["flip"])
	var left := FishArt.frame(f, SPECIES, false, false, 0.0)
	assert_true(left["flip"])


func test_fish_frame_animates_while_swimming() -> void:
	var f := Fish.new()
	f.traits = {"variety": "red"}
	assert_eq(FishArt.frame(f, SPECIES, true, true, 0.0)["rect"], Rect2(0, 0, 5, 5))
	assert_eq(FishArt.frame(f, SPECIES, true, true, 0.15)["rect"], Rect2(5, 0, 5, 5))
	# Left-swim frames already face left, so no flip.
	var left := FishArt.frame(f, SPECIES, false, true, 0.0)
	assert_eq(left["rect"], Rect2(0, 10, 5, 5))
	assert_false(left["flip"])


func test_fish_frame_tints_placeholder_varieties() -> void:
	var f := Fish.new()
	f.traits = {"variety": "pink"}
	var art := FishArt.frame(f, SPECIES, true, false, 0.0)
	assert_eq(art["rect"], Rect2(10, 20, 30, 40))
	assert_eq(art["tint"], Color("#ff80c0"))


func test_fish_frame_is_empty_for_species_without_sprites() -> void:
	var f := Fish.new()
	assert_true(FishArt.frame(f, {"days_to_adult": 3}, true, false, 0.0).is_empty())


func test_fry_are_drawn_smaller() -> void:
	var f := Fish.new()
	f.age_days = 0
	assert_eq(FishArt.growth(f, SPECIES), 0.4)
	f.age_days = 2
	assert_eq(FishArt.growth(f, SPECIES), 0.7)
	f.age_days = 9
	assert_eq(FishArt.growth(f, SPECIES), 1.0)


func test_back_room_tanks_fill_the_left_wall_then_the_right() -> void:
	var seen := {}
	for i in 10:
		var p := BackRoom3D.slot_position(i)
		assert_eq(signf(p.x), -1.0 if i < 5 else 1.0, "tank %d side" % i)
		assert_false(seen.has(p), "tank %d has its own spot" % i)
		seen[p] = true
	assert_true(BackRoom3D.slot_position(9).z + 0.6 < 11.0, "the last tank is inside the back wall")
