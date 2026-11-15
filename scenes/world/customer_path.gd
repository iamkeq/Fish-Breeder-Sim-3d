extends RefCounted
## Where a shop customer walks, by what they came for. Pure (no nodes) so the
## routes can be tested. Stops are names the world maps to spots: "shelf",
## "display" (the display tank), "goldfish" (the goldfish tank) and "counter". The door is the start and end.


## The stops after the door, in order: {"at": stop, "pause": seconds to look around}.
static func steps(kind: String) -> Array:
	match kind:
		"item":  # ordinary shelf stock: browse the shelf, then pay
			return [{"at": "shelf", "pause": 1.0}, {"at": "counter", "pause": 0.0}]
		"fish", "collector", "tank":  # admire the display tank, then ask at the counter
			return [{"at": "display", "pause": 1.5}, {"at": "counter", "pause": 0.0}]
		"goldfish":  # pick one out of the goldfish tank, then ask at the counter
			return [{"at": "goldfish", "pause": 1.5}, {"at": "counter", "pause": 0.0}]
		_:  # requests, back-order wishes and browsers go straight to the counter
			return [{"at": "counter", "pause": 0.0}]


## Shelf customers pay by themselves once they reach the counter; everyone
## else waits for the player.
static func pays_automatically(kind: String) -> bool:
	return kind == "item"
