extends Node
## Works out which Synty files the game can actually load and leaves the rest of the packs
## out of exported builds, so the download isn't 600 MB of unused models and textures.
##
##   godot --headless --path . res://tools/export_filter.tscn
##
## It builds the shop (every shop improvement included), puts every decor item in a tank,
## makes every customer, shelf product and menu picture, and notes every model that was
## loaded, plus the materials, the fish tank and fish, and the customer animations. Then
## it follows each of those files' dependencies, and writes every other file in the asset
## packs into export_presets.cfg as the presets' exclude list (export_filter="exclude").
## Run it again after adding a model to the game.

const Synty := preload("res://scenes/world/synty.gd")
const SyntyAnims := preload("res://scenes/world/synty_anims.gd")
const Customer3D := preload("res://scenes/world/customer_3d.gd")
const FoodIcons := preload("res://scenes/ui/food_icons.gd")
const PACKS := ["res://assets/Synty/", "res://assets/PolygonPirates/", "res://assets/PolygonDungeon/"]
const PRESETS := "res://export_presets.cfg"


func _ready() -> void:
	Game.persist = false
	await _load_everything()
	var seeds := {}
	for rel in Synty._scenes:
		seeds[Synty._path(rel)] = true
	for path in _material_paths():
		seeds[path] = true
	for f in ["SM_Prop_Fishtank_01.fbx", "SM_Prop_Fish_01.fbx"]:
		seeds[Synty.OFFICE + "Models/" + f] = true
	for clip in SyntyAnims.CLIPS.values():
		for body in ["_Femn", "_Masc"]:
			seeds[SyntyAnims.DIR + clip[0] + body + ".fbx"] = true
	var needed := {}
	for path in seeds:
		_collect(path, needed)
	var excluded: Array[String] = []
	var total := 0
	for pack in PACKS:
		_list(pack, excluded, needed)
	for path in needed:
		if _in_packs(path):
			total += 1
	_write_presets(excluded)
	print("export_filter: %d pack files needed, %d left out of builds" % [total, excluded.size()])
	get_tree().quit()


## Build everything the game can show, so every model it can load gets loaded once.
func _load_everything() -> void:
	for id in ["fresh_paint", "striped_awning", "neon_sign", "reading_corner", "second_display"]:
		Game.state.upgrades[id] = 1
	var world: Node = load("res://scenes/world/world.tscn").instantiate()
	world.capture_mouse = false
	add_child(world)
	await get_tree().process_frame
	# Every decor item, a tank-load at a time.
	var tank: Tank = Game.state.display_tank
	var decor: Array = Game.db.items.keys().filter(func(id): return Game.db.items[id].get("category", "") in ["plant", "rock", "driftwood", "decor"])
	for start in range(0, decor.size(), tank.slot_count()):
		for i in tank.slot_count():
			tank.slots[i] = decor[start + i] if start + i < decor.size() else ""
		Game.changed.emit()
		await get_tree().process_frame
	# Every customer look, every shelf product, every menu picture.
	for i in Customer3D.PEOPLE.size():
		Synty.make(Customer3D.PEOPLE[i]).free()
	for i in 49:
		Synty.make("Products/SM_Prop_Product_%02d" % (i + 1)).free()
	for icon in FoodIcons.MODELS:
		Synty.make(FoodIcons.MODELS[icon]).free()
	world.queue_free()
	await get_tree().process_frame


## Materials the code asks for by name (Synty.material / Synty.tinted).
func _material_paths() -> Array:
	var out := []
	var regex := RegEx.create_from_string("\"([A-Za-z0-9_/]+_mat)\"")
	var dir := DirAccess.open("res://scenes/world")
	for file in dir.get_files():
		if not file.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string("res://scenes/world/" + file)
		for m in regex.search_all(text):
			var path: String = Synty.MATERIALS + m.get_string(1) + ".tres"
			if ResourceLoader.exists(path):
				out.append(path)
	return out


func _collect(path: String, needed: Dictionary) -> void:
	if needed.has(path) or not ResourceLoader.exists(path):
		return
	needed[path] = true
	for dep in ResourceLoader.get_dependencies(path):
		var i := dep.rfind("res://")
		if i >= 0:
			_collect(dep.substr(i), needed)


func _in_packs(path: String) -> bool:
	for pack in PACKS:
		if path.to_lower().begins_with(pack.to_lower()):
			return true
	return false


## Every resource file under `dir` that isn't needed.
func _list(dir_path: String, out: Array[String], needed: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	var lower_needed := {}
	for p in needed:
		lower_needed[String(p).to_lower()] = true
	for file in dir.get_files():
		if file.ends_with(".import") or file.ends_with(".uid") or file.ends_with(".bak") or file.ends_with(".unwrap_cache"):
			continue
		var path := dir_path + file
		if not lower_needed.has(path.to_lower()):
			out.append(path)
	for sub in dir.get_directories():
		_list(dir_path + sub + "/", out, needed)


func _write_presets(excluded: Array[String]) -> void:
	var config := ConfigFile.new()
	if config.load(PRESETS) != OK:
		push_error("Couldn't read export_presets.cfg")
		return
	for section in config.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			config.set_value(section, "export_filter", "exclude")
			config.set_value(section, "export_files", PackedStringArray(excluded))
	config.save(PRESETS)
