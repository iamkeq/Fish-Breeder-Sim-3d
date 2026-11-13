extends RefCounted
## Icons for food buffs: a Synty potion bottle each (rendered by synty_icons.gd).

const SyntyIcons := preload("res://scenes/world/synty_icons.gd")

const MODELS := {
	"heart": "Dungeon/Items/SM_Item_Potion_01",  # Spawning Pellets
	"arm": "Dungeon/Items/SM_Item_Potion_02",  # Growth Flakes
}


## The icon called `icon_name` ("heart", "arm"), or null for "" / unknown names.
static func texture(icon_name: String) -> Texture2D:
	if not MODELS.has(icon_name):
		return null
	return SyntyIcons.model(MODELS[icon_name], Vector2i(64, 64))
