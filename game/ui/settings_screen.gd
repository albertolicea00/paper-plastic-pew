class_name SettingsScreen
extends Control
## Classic settings overlay: music/sound volume, camera view, graphics, touch,
## fullscreen, FPS. Themed by the active dimension. Changes apply live and save
## through main.set_setting(). Opened from the menu and the pause sheet.

var main: Node
var pack: DimensionPack
var on_close: Callable
var rows: VBoxContainer

func open(owner_main: Node, active_pack: DimensionPack, closer: Callable) -> void:
	main = owner_main
	pack = active_pack
	on_close = closer
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.color = Color(pack.color("ink"), 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(pack.color("ui_bg"), 3))
	frame.anchor_left = 0.5
	frame.anchor_top = 0.5
	frame.anchor_right = 0.5
	frame.anchor_bottom = 0.5
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(frame)
	frame.custom_minimum_size = Vector2(minf(size.x - 48.0, 760.0), minf(size.y - 40.0, 640.0))
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)
	var title = Label.new()
	title.text = _case("Settings")
	title.add_theme_font_override("font", _font())
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", pack.color("ui_accent"))
	column.add_child(title)
	var rule = ColorRect.new()
	rule.color = Color(pack.color("ui_accent"), 0.6)
	rule.custom_minimum_size = Vector2(0, 3)
	column.add_child(rule)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(rows)
	_stepper("Music", "music")
	_stepper("Sound", "sfx")
	_choice("Default view", "view", [["top", "Top"], ["shoulder", "Behind"], ["weapon", "Weapon"]])
	_choice("Graphics", "quality", [["high", "High"], ["low", "Low"]])
	if not OS.has_feature("mobile"):
		_choice("Touch controls", "touch", [[false, "Off"], [true, "On"]])
		_choice("Fullscreen", "fullscreen", [[false, "Off"], [true, "On"]])
	_choice("Show FPS", "fps", [[false, "Off"], [true, "On"]])
	var back = _button(_case("Back"), _close)
	back.custom_minimum_size = Vector2(0, 60)
	back.add_theme_font_size_override("font_size", 26)
	column.add_child(back)
	back.grab_focus.call_deferred()

# A label with a - value + stepper, for a 0..1 volume.
func _stepper(label: String, key: String) -> void:
	var row = _row(label)
	var value = Label.new()
	value.custom_minimum_size = Vector2(110, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var refresh = func():
		value.text = "%d%%" % roundi(float(main.settings.get(key, 0.6)) * 100.0)
		_style_label(value)
	var step = func(d):
		main.set_setting(key, clampf(float(main.settings.get(key, 0.6)) + d, 0.0, 1.0))
		if key == "sfx":
			main.sfx.play("swap")
		refresh.call()
	var minus = _button("-", func(): step.call(-0.1))
	var plus = _button("+", func(): step.call(0.1))
	minus.custom_minimum_size = Vector2(64, 52)
	plus.custom_minimum_size = Vector2(64, 52)
	row.add_child(minus)
	row.add_child(value)
	row.add_child(plus)
	refresh.call()

# A label with a segmented set of choices bound to a setting key.
func _choice(label: String, key: String, choices: Array) -> void:
	var row = _row(label)
	var buttons: Array[Button] = []
	var paint = func():
		for i in choices.size():
			_skin(buttons[i], main.settings.get(key) == choices[i][0])
	for choice in choices:
		var button = _button(_case(choice[1]), func():
			main.set_setting(key, choice[0])
			paint.call())
		button.custom_minimum_size = Vector2(110, 52)
		row.add_child(button)
		buttons.append(button)
	paint.call()

func _row(label: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rows.add_child(row)
	var name = Label.new()
	name.text = _case(label)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(name)
	row.add_child(name)
	return row

func _style_label(label: Label) -> void:
	label.add_theme_font_override("font", _font())
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", pack.color("ui_fg"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()

func _button(text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.add_theme_font_override("font", _font())
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	_skin(button, false)
	return button

func _skin(button: Button, on: bool) -> void:
	var fill = pack.color("ui_accent") if on else pack.color("ui_bg").lightened(0.12)
	var tone = _contrast(fill)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, tone)
	button.add_theme_stylebox_override("normal", _box(fill, 2))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.12), 2))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.15), 2))
	var halo = _box(Color.TRANSPARENT, 0)
	halo.draw_center = false
	halo.border_color = pack.color("ui_fg")
	halo.set_border_width_all(3)
	halo.set_corner_radius_all(int(pack.hud.radius) + 2)
	button.add_theme_stylebox_override("focus", halo)

func _font() -> Font:
	return pack.font if pack.font != null else get_theme_default_font()

func _case(text: String) -> String:
	return text.to_upper() if pack.hud.uppercase else text

func _contrast(fill: Color) -> Color:
	return pack.color("ink") if fill.get_luminance() > 0.5 else pack.color("ui_fg")

func _box(fill: Color, border: int) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = pack.color("ink")
	box.set_border_width_all(border)
	box.set_corner_radius_all(int(pack.hud.radius))
	box.set_content_margin_all(14)
	return box
