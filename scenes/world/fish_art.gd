extends RefCounted
## Which piece of a species' sprite sheet to show for a fish in the 3D world.
## Same data and same choices as scenes/fish_sprite.gd (variety frame, swim
## animation, placeholder tint for varieties without their own art), just
## returned as plain values for a Sprite3D. Pure: no nodes.


## {"sheet": path, "rect": Rect2, "flip": bool, "tint": Color, "scale": float}
## for the fish facing left or right, or {} if the species has no sprite sheet.
## `moving` picks the swim animation (otherwise the idle frame); `t` is seconds.
static func frame(fish: Fish, species: Dictionary, facing_right: bool, moving: bool, t: float) -> Dictionary:
	var data: Dictionary = species.get("sprites", {})
	if data.is_empty():
		return {}
	var look := fish.get_trait(data["trait"])
	var placeholder: Dictionary = {}
	if not data["varieties"].has(look):
		placeholder = data.get("placeholders", {}).get(look, {})
	if not placeholder.is_empty():
		look = placeholder["base"]
	var rect: Array = data["varieties"].get(look, data["varieties"].values()[0])
	var tail_right := false
	var anims: Dictionary = data.get("animations", {}).get(look, {})
	var anim := ("swim_right" if facing_right else "swim_left") if moving else "idle"
	if anims.has(anim):
		var frames: Array = anims[anim]
		rect = frames[int(t * float(data.get("fps", 10))) % frames.size()]
		tail_right = anim == "swim_left"  # those frames already face left
	return {
		"sheet": data["sheet"],
		"rect": Rect2(rect[0], rect[1], rect[2], rect[3]),
		"flip": not facing_right and not tail_right,
		"tint": Color(placeholder.get("tint", "#ffffff")),
		"scale": float(data.get("scale", 1.0)),
	}


## How big a fish looks, 0.4 (newborn fry) to 1.0 (adult), like the 2D game.
static func growth(fish: Fish, species: Dictionary) -> float:
	var grown := clampf(float(fish.age_days) / float(species.get("days_to_adult", 1)), 0.0, 1.0)
	return lerpf(0.4, 1.0, grown)
