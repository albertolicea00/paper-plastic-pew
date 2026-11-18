class_name InfoScreen
extends Control
## A full-screen scrollable panel for Credits or Controls, themed by the active
## dimension. Opened from the menu and the pause sheet; closes itself.

const CONTROLS = """[ MOVE ]
Keyboard: WASD or Arrow keys
Gamepad: Left stick
Touch: Left thumb stick (left half of the screen)

[ AIM & FIRE ]
Mouse: aim with the pointer, hold Left button to fire
Gamepad: Right stick aims and fires
Touch: Right thumb stick (right half of the screen)

[ ACTIONS ]
Dash: Space / Shift  -  Gamepad A or LB  -  on-screen DASH
Swap weapon: Q / E  -  Gamepad Y or RB  -  on-screen SWAP
Change view: V  -  Gamepad Back  -  pause menu button
Pause: Esc / P  -  Gamepad Start  -  on-screen II

[ VIEWS ]
Top-down, Behind and Weapon. In the body-locked views the second
stick turns you, red chevrons mark threats off-screen, and a red
arrow shows where damage came from.

[ MULTIVERSE ]
The world, art, animation, music and feel snap between dimensions.
In Multiverse Shift it happens mid-fight; in Campaign, per stage."""

var on_close: Callable
var scroll: ScrollContainer
var body: Label
var title: Label
var back: Button
var pack: DimensionPack

func open(active_pack: DimensionPack, which: String, closer: Callable) -> void:
	pack = active_pack
	on_close = closer
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.color = Color(pack.color("ink"), 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(pack.color("ui_bg")))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("margin_left", 40)
	panel.add_theme_constant_override("margin_right", 40)
	panel.add_theme_constant_override("margin_top", 28)
	panel.add_theme_constant_override("margin_bottom", 28)
	add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	title = Label.new()
	title.text = _case("Credits" if which == "credits" else "Controls")
	title.add_theme_font_override("font", _font())
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", pack.color("ui_accent"))
	column.add_child(title)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = Label.new()
	body.text = _text(which)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 0)
	body.add_theme_font_override("font", _font())
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", pack.color("ui_fg"))
	scroll.add_child(body)
	back = Button.new()
	back.text = _case("Back")
	back.custom_minimum_size = Vector2(0, 62)
	back.add_theme_font_override("font", _font())
	back.add_theme_font_size_override("font_size", 26)
	back.add_theme_color_override("font_color", _contrast(pack.color("ui_accent")))
	back.add_theme_stylebox_override("normal", _box(pack.color("ui_accent")))
	back.add_theme_stylebox_override("hover", _box(pack.color("ui_accent").lightened(0.12)))
	back.add_theme_stylebox_override("pressed", _box(pack.color("ui_accent").darkened(0.15)))
	back.pressed.connect(_close)
	column.add_child(back)
	back.grab_focus.call_deferred()

func _text(which: String) -> String:
	if which == "controls":
		return CONTROLS
	var path = "res://CREDITS.txt"
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)
	return "Credits are listed in CREDITS.txt."

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()

func _font() -> Font:
	return pack.font if pack.font != null else get_theme_default_font()

func _case(text: String) -> String:
	return text.to_upper() if pack.hud.uppercase else text

func _contrast(fill: Color) -> Color:
	return pack.color("ink") if fill.get_luminance() > 0.5 else pack.color("ui_fg")

func _box(fill: Color) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = pack.color("ink")
	box.set_border_width_all(int(pack.hud.border))
	box.set_corner_radius_all(int(pack.hud.radius))
	box.set_content_margin_all(16)
	return box
