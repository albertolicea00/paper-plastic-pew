class_name InfoScreen
extends Control
## Game-styled Controls and Credits overlays, themed by the active dimension.
## Controls is drawn (key caps, a gamepad, touch zones) with a device tab bar;
## Credits is a styled, scrollable list. Opened from the menu and pause.

var on_close: Callable
var pack: DimensionPack
var which = "controls"
var device = "keyboard"
var tabs: Array[Button] = []
var diagram: Control

func open(active_pack: DimensionPack, screen: String, closer: Callable) -> void:
	pack = active_pack
	which = screen
	on_close = closer
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Pick the device that matches how the player is most likely playing.
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"):
		device = "touch"
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
	frame.custom_minimum_size = Vector2(minf(size.x - 48.0, 1040.0), minf(size.y - 40.0, 680.0))
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	frame.add_child(column)
	var header = HBoxContainer.new()
	column.add_child(header)
	var title = Label.new()
	title.text = _case("Controls" if which == "controls" else "Credits")
	title.add_theme_font_override("font", _font())
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", pack.color("ui_accent"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if which == "controls":
		for id in [["keyboard", "Keyboard"], ["gamepad", "Gamepad"], ["touch", "Touch"]]:
			var tab = _mk_button(id[1], func(): _switch(id[0]))
			tab.custom_minimum_size = Vector2(150, 48)
			header.add_child(tab)
			tab.set_meta("device", id[0])
			tabs.append(tab)
	column.add_child(_rule())
	var content = _build_content()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	var back = _mk_button("Back", _close)
	back.custom_minimum_size = Vector2(0, 60)
	back.add_theme_font_size_override("font_size", 26)
	column.add_child(back)
	if which == "controls":
		_switch(device)
	back.grab_focus.call_deferred()

func _build_content() -> Control:
	if which == "credits":
		var scroll = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var text = RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.add_theme_font_override("normal_font", _font())
		text.add_theme_font_override("bold_font", _font())
		text.add_theme_font_size_override("normal_font_size", 18)
		text.add_theme_font_size_override("bold_font_size", 18)
		text.add_theme_color_override("default_color", pack.color("ui_fg"))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.text = _credits_bbcode()
		scroll.add_child(text)
		return scroll
	diagram = Control.new()
	diagram.custom_minimum_size = Vector2(0, 380)
	diagram.draw.connect(_draw_device)
	return diagram

func _switch(id: String) -> void:
	device = id
	for tab in tabs:
		_skin(tab, tab.get_meta("device") == id)
	if diagram != null:
		diagram.queue_redraw()

# ---- Credits ----------------------------------------------------------------

func _credits_bbcode() -> String:
	var fg = pack.color("ui_fg").to_html(false)
	var accent = pack.color("ui_accent").to_html(false)
	var path = "res://CREDITS.txt"
	if not FileAccess.file_exists(path):
		return "Third-party credits are in CREDITS.txt."
	var out = PackedStringArray()
	var lines = FileAccess.get_file_as_string(path).split("\n")
	var i = 0
	while i < lines.size():
		var line: String = lines[i]
		var next: String = lines[i + 1] if i + 1 < lines.size() else ""
		# A line underlined by === or --- is a heading.
		if next.length() > 2 and (next.begins_with("==") or next.begins_with("--")):
			out.append("\n[b][color=#%s]%s[/color][/b]" % [accent, _case(line.strip_edges())])
			i += 2
			continue
		if line.strip_edges() == "":
			out.append("")
		elif line.begins_with("  ") or line.begins_with("\t"):
			out.append("[color=#%s]%s[/color]" % [fg, line.strip_edges()])
		else:
			out.append("[color=#%s]%s[/color]" % [accent, line])
		i += 1
	return "\n".join(out)

# ---- Controls diagrams ------------------------------------------------------

func _draw_device() -> void:
	var r = diagram.get_rect()
	r.position = Vector2.ZERO
	match device:
		"gamepad": _draw_gamepad(diagram, r)
		"touch": _draw_touch(diagram, r)
		_: _draw_keyboard(diagram, r)

# A keyboard key cap with a letter, plus an optional caption under it.
func _cap(c: Control, at: Vector2, side: Vector2, label: String, caption: String = "") -> void:
	var ink = pack.color("ink")
	c.draw_rect(Rect2(at + Vector2(3, 4), side), Color(ink, 0.4))
	var face = _box(pack.color("ui_bg").lightened(0.16), 2)
	face.draw(c.get_canvas_item(), Rect2(at, side))
	_center(c, label, at + side * 0.5, 20, pack.color("ui_fg"))
	if caption != "":
		_center(c, caption, at + Vector2(side.x * 0.5, side.y + 14), 13, Color(pack.color("ui_fg"), 0.8))

func _draw_keyboard(c: Control, r: Rect2) -> void:
	var left = r.position + Vector2(r.size.x * 0.06, 70)
	var k = Vector2(54, 54)
	var gap = 10.0
	# WASD cluster.
	_cap(c, left + Vector2(k.x + gap, 0), k, "W")
	_cap(c, left + Vector2(0, k.y + gap), k, "A")
	_cap(c, left + Vector2(k.x + gap, k.y + gap), k, "S")
	_cap(c, left + Vector2((k.x + gap) * 2, k.y + gap), k, "D")
	_caption(c, left + Vector2((k.x + gap) * 1.5, -22), "MOVE", pack.color("ui_accent"))
	# Action keys row.
	var row = left + Vector2(0, (k.y + gap) * 2 + 34)
	var keys = [["SPACE", "DASH", 92.0], ["Q", "SWAP", k.x], ["V", "VIEW", k.x], ["ESC", "PAUSE", 72.0]]
	var x = row.x
	for key in keys:
		_cap(c, Vector2(x, row.y), Vector2(key[2], k.y), key[0], key[1])
		x += key[2] + gap + 24.0
	# Mouse on the right.
	var mouse_at = r.position + Vector2(r.size.x * 0.72, 60)
	_draw_mouse(c, mouse_at, Vector2(96, 150))
	_caption(c, mouse_at + Vector2(48, -22), "AIM & FIRE", pack.color("ui_accent"))

func _draw_mouse(c: Control, at: Vector2, side: Vector2) -> void:
	var ink = pack.color("ink")
	c.draw_rect(Rect2(at + Vector2(4, 5), side), Color(ink, 0.35))
	var body = StyleBoxFlat.new()
	body.bg_color = pack.color("ui_bg").lightened(0.16)
	body.border_color = ink
	body.set_border_width_all(3)
	body.set_corner_radius_all(int(side.x * 0.5))
	body.draw(c.get_canvas_item(), Rect2(at, side))
	# Left button highlighted = fire.
	var lmb = StyleBoxFlat.new()
	lmb.bg_color = pack.color("ui_accent")
	lmb.border_color = ink
	lmb.set_border_width_all(3)
	lmb.corner_radius_top_left = int(side.x * 0.5)
	lmb.draw(c.get_canvas_item(), Rect2(at, Vector2(side.x * 0.5, side.y * 0.42)))
	c.draw_line(at + Vector2(side.x * 0.5, 2), at + Vector2(side.x * 0.5, side.y * 0.42), ink, 3.0)
	_center(c, "FIRE", at + Vector2(side.x * 0.5, side.y + 16), 14, pack.color("ui_fg"))

# Real controller art from the Kenney Input Prompts pack (CC0), with the action
# mapping as a legend beneath — the standard way a control screen reads.
const XBOX_TEX = preload("res://assets/ui/controllers/xbox.png")
const PS_TEX = preload("res://assets/ui/controllers/playstation.png")

func _draw_gamepad(c: Control, r: Rect2) -> void:
	var s = minf(r.size.x * 0.40, 360.0)
	var y = r.position.y + r.size.y * 0.42
	_pad_image(c, XBOX_TEX, "XBOX", Vector2(r.position.x + r.size.x * 0.28, y), s)
	_pad_image(c, PS_TEX, "PLAYSTATION", Vector2(r.position.x + r.size.x * 0.72, y), s)
	var legend = r.position + Vector2(r.size.x * 0.5, r.size.y * 0.92)
	_caption(c, legend + Vector2(0, -32), "LEFT STICK MOVE   ·   RIGHT STICK AIM & FIRE", pack.color("ui_accent"))
	_caption(c, legend + Vector2(0, -8), "A / CROSS DASH   ·   Y / TRIANGLE SWAP   ·   BUMPERS HELP MOVE", Color(pack.color("ui_fg"), 0.85))
	_caption(c, legend + Vector2(0, 16), "START PAUSE   ·   BACK / SHARE CHANGE VIEW", Color(pack.color("ui_fg"), 0.85))

# One controller illustration, centred, with its name above.
func _pad_image(c: Control, tex: Texture2D, name: String, mid: Vector2, s: float) -> void:
	_caption(c, mid + Vector2(0, -s * 0.5 - 16), name, pack.color("ui_fg"))
	# Tint the white Kenney art to the theme's foreground so it shows on any page.
	c.draw_texture_rect(tex, Rect2(mid - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), false, pack.color("ui_fg"))

func _stick(c: Control, at: Vector2, radius: float, label: String) -> void:
	var ink = pack.color("ink")
	c.draw_circle(at, radius + 3, Color(ink, 0.4))
	c.draw_circle(at, radius, pack.color("ui_bg").darkened(0.2))
	c.draw_arc(at, radius, 0, TAU, 32, ink, 3.0, true)
	c.draw_circle(at, radius * 0.55, pack.color("ui_accent"))
	c.draw_arc(at, radius * 0.55, 0, TAU, 24, ink, 2.5, true)
	_center(c, label, at + Vector2(0, radius + 16), 13, pack.color("ui_fg"))

func _draw_touch(c: Control, r: Rect2) -> void:
	var ink = pack.color("ink")
	var screen = Rect2(r.position + Vector2(r.size.x * 0.5 - 300, 30), Vector2(600, 320))
	var body = StyleBoxFlat.new()
	body.bg_color = pack.color("ui_bg").darkened(0.12)
	body.border_color = ink
	body.set_border_width_all(4)
	body.set_corner_radius_all(26)
	body.draw(c.get_canvas_item(), screen)
	# Left half = move, right half = aim/fire.
	var left_c = screen.position + Vector2(screen.size.x * 0.25, screen.size.y * 0.62)
	var right_c = screen.position + Vector2(screen.size.x * 0.75, screen.size.y * 0.62)
	_stick(c, left_c, 46, "MOVE")
	_stick(c, right_c, 46, "AIM / FIRE")
	# Action buttons.
	_touch_btn(c, right_c + Vector2(-20, -120), "DASH")
	_touch_btn(c, right_c + Vector2(-110, -90), "SWAP")
	_touch_btn(c, screen.position + Vector2(screen.size.x - 40, 36), "II")
	_caption(c, screen.position + Vector2(screen.size.x * 0.5, -22), "DRAG EACH THUMB — LEFT MOVES, RIGHT AIMS & FIRES", Color(pack.color("ui_fg"), 0.85))

func _touch_btn(c: Control, at: Vector2, label: String) -> void:
	var ink = pack.color("ink")
	c.draw_circle(at, 26, Color(pack.color("ui_bg").lightened(0.2), 0.95))
	c.draw_arc(at, 26, 0, TAU, 24, ink, 3.0, true)
	_center(c, label, at, 14, pack.color("ui_fg"))

# ---- helpers ----------------------------------------------------------------

func _center(c: Control, text: String, at: Vector2, text_size: int, tone: Color) -> void:
	var font = _font()
	var shown = _case(text)
	var w = font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size)
	c.draw_string(font, at - Vector2(w.x * 0.5, -text_size * 0.34), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, tone)

func _caption(c: Control, at: Vector2, text: String, tone: Color) -> void:
	_center(c, text, at, 15, tone)

func _rule() -> Control:
	var line = ColorRect.new()
	line.color = Color(pack.color("ui_accent"), 0.6)
	line.custom_minimum_size = Vector2(0, 3)
	return line

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	if on_close.is_valid():
		on_close.call()
	queue_free()

func _mk_button(text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = _case(text)
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
	box.set_content_margin_all(18)
	return box
