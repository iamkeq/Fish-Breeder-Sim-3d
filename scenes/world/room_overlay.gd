extends ColorRect
## A modal panel (dimmed backdrop, title, Close button) that hosts existing 2D
## screens (the shop floor, back room, orders room, desk buttons) over the 3D
## world. Pauses the clock while open; Esc or the Close button closes it.

signal closed

var _title: Label
var _holder: VBoxContainer
var _open := false


func _init() -> void:
	visible = false
	color = Color(0.15, 0.1, 0.08, 0.45)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)
	_holder = VBoxContainer.new()
	box.add_child(_holder)


## Puts a screen into the panel (it stays there; other screens are hidden).
func adopt(content: Control) -> void:
	if content.get_parent() != null:
		content.reparent(_holder)
	else:
		_holder.add_child(content)
	content.visible = false


## Shows `content` at least `min_size` big under `title`, opening the panel if needed.
func show_content(content: Control, title: String, min_size: Vector2) -> void:
	for child in _holder.get_children():
		child.visible = child == content
	content.custom_minimum_size = min_size
	_title.text = title
	if not _open:
		_open = true
		visible = true
		Game.push_pause()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Game.pop_pause()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
