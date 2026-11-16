class_name MainMenu
extends Control
## Main menu: the Workbench. A 3D artist's desk (ui/menu/desk.gd) carries one
## object per dimension pack; picking one lifts it and themes the whole menu
## with that pack. Contract with core/main.gd: setup(main) is called before
## the node enters the tree, and start_requested carries a match config:
## {mode: survival|shift|campaign|skirmish, dimension: <pack id>, bots: 1..8, difficulty: 0..2}
## Developer arguments: --menu-pick=<pack id> --menu-mode=<mode>
##   --menu-objects=<kind,kind,...> (force desk objects by pack order)
##   --menu-start (press Start after a moment, for automated checks)

signal start_requested(config: Dictionary)

# id, name, one-liner, uses every dimension
const MODES = [
	["survival", "Survival", "Endless waves in one world", false],
	["shift", "Multiverse Shift", "Waves while reality snaps between worlds", true],
	["campaign", "Campaign", "Stage and boss in every world, in order", true],
	["skirmish", "Skirmish vs bots", "Free-for-all against AI in one world", false]]
const LEVELS = ["Easy", "Normal", "Hard"]
const SIDE = 404.0
const EDGE = 16.0

var main: Node
var packs: Array = []
var pick = 0
var mode = 0
var level = 1
var bots = 4
var desk: MenuDesk
var title: Label
var card: PanelContainer
var card_name: Label
var card_family: Label
var card_tagline: Label
var prev: Button
var next: Button
var side: PanelContainer
var mode_buttons: Array[Button] = []
var note: Label
var level_buttons: Array[Button] = []
var level_label: Label
var bots_row: HBoxContainer
var bots_label: Label
var bots_value: Label
var bots_buttons: Array[Button] = []
var go: Button
var quit: Button

func setup(owner_main: Node) -> void:
	main = owner_main

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	packs = main.dimensions.packs
	var options: Dictionary = main.options
	for i in packs.size():
		if packs[i].id == options.get("menu-pick", main.dimensions.active.id):
			pick = i
	for i in MODES.size():
		if MODES[i][0] == options.get("menu-mode", ""):
			mode = i
	desk = MenuDesk.new()
	desk.setup(packs, Array(str(options.get("menu-objects", "")).split(",", false)))
	desk.selected = pick
	add_child(desk)
	title = Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	_build_card()
	_build_side()
	resized.connect(_layout)
	_refresh()
	_layout()
	go.grab_focus.call_deferred()
	if options.has("menu-start"):
		get_tree().create_timer(0.6).timeout.connect(_start)

func _build_card() -> void:
	prev = _button("<", func(): _step(-1))
	next = _button(">", func(): _step(1))
	for arrow in [prev, next]:
		# Keyboard and gamepad change dimension with left/right instead.
		arrow.focus_mode = Control.FOCUS_NONE
		add_child(arrow)
	card = PanelContainer.new()
	add_child(card)
	var lines = VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(lines)
	card_family = _label(lines)
	card_name = _label(lines)
	card_tagline = _label(lines)

func _build_side() -> void:
	side = PanelContainer.new()
	add_child(side)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	side.add_child(column)
	for i in MODES.size():
		var button = _button("", func(): _set_mode(i, true))
		button.custom_minimum_size = Vector2(0, 62)
		button.focus_entered.connect(func(): _set_mode(i, false))
		var pad = MarginContainer.new()
		pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_theme_constant_override("margin_left", 16)
		pad.add_theme_constant_override("margin_right", 16)
		button.add_child(pad)
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_child(row)
		var words = VBoxContainer.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", -2)
		row.add_child(words)
		_label(words, HORIZONTAL_ALIGNMENT_LEFT)
		_label(words, HORIZONTAL_ALIGNMENT_LEFT)
		var best = _label(row, HORIZONTAL_ALIGNMENT_RIGHT)
		best.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.set_meta("labels", [words.get_child(0), words.get_child(1), best])
		column.add_child(button)
		mode_buttons.append(button)
	note = _label(column)
	note.custom_minimum_size = Vector2(0, 46)
	var levels = _row(column)
	level_label = _label(levels, HORIZONTAL_ALIGNMENT_LEFT)
	level_label.custom_minimum_size = Vector2(92, 0)
	for i in LEVELS.size():
		var button = _button(LEVELS[i], func(): level = i)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Rows keep left/right for themselves, see _input.
		button.set_meta("row", true)
		levels.add_child(button)
		level_buttons.append(button)
	bots_row = _row(column)
	bots_label = _label(bots_row, HORIZONTAL_ALIGNMENT_LEFT)
	bots_label.custom_minimum_size = Vector2(92, 0)
	var fewer = _button("-", func(): bots = maxi(1, bots - 1))
	var more = _button("+", func(): bots = mini(8, bots + 1))
	bots_buttons = [fewer, more]
	for button in bots_buttons:
		button.custom_minimum_size = Vector2(72, 56)
		button.set_meta("row", true)
	bots_row.add_child(fewer)
	bots_value = _label(bots_row)
	bots_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bots_row.add_child(more)
	var gap = Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	go = _button("", _start)
	go.custom_minimum_size = Vector2(0, 76)
	column.add_child(go)
	quit = _button("Quit", func(): get_tree().quit())
	quit.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	column.add_child(quit)

func _row(parent: Control) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	return row

func _label(parent: Control, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label = Label.new()
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label

func _button(text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(64, 56)
	button.pressed.connect(action)
	button.pressed.connect(_refresh)
	return button

func _pack() -> DimensionPack:
	return packs[pick]

func _step(by: int) -> void:
	_choose(posmod(pick + by, packs.size()))

func _choose(index: int) -> void:
	if index == pick:
		return
	pick = index
	main.sfx.play("swap")
	_refresh()
	_layout()

func _set_mode(index: int, confirm: bool) -> void:
	mode = index
	# Accept on a mode moves on to Start, so two presses begin a match.
	if confirm and get_viewport().gui_get_focus_owner() == mode_buttons[index]:
		go.grab_focus()
	_refresh()

func _start() -> void:
	start_requested.emit({"mode": MODES[mode][0], "dimension": _pack().id, "bots": bots, "difficulty": level})

func _input(event: InputEvent) -> void:
	var by = 0
	if event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true):
		var focused = get_viewport().gui_get_focus_owner()
		if focused != null and focused.has_meta("row"):
			return
		by = -1 if event.is_action_pressed("ui_left", true) else 1
	elif event is InputEventJoypadButton and event.pressed:
		by = -1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1 if event.button_index == JOY_BUTTON_RIGHT_SHOULDER else 0
	elif event is InputEventKey and event.pressed and not event.echo:
		by = -1 if event.keycode == KEY_Q else 1 if event.keycode == KEY_E else 0
	if by != 0:
		_step(by)
		get_viewport().set_input_as_handled()

# Clicks and taps that no button took land here: pick the object under them.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		desk.hovered = desk.pick(event.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if desk.hovered >= 0 else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit = desk.pick(event.position)
		if hit >= 0:
			_choose(hit)
			accept_event()

func _font() -> Font:
	return _pack().font if _pack().font != null else get_theme_default_font()

func _case(text: String) -> String:
	return text.to_upper() if _pack().hud.uppercase else text

func _box(fill: Color, shadow: bool = true) -> StyleBoxFlat:
	var pack = _pack()
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = pack.color("ink")
	box.set_border_width_all(int(pack.hud.border))
	box.set_corner_radius_all(int(pack.hud.radius))
	if shadow and float(pack.hud.shadow) > 0.0:
		box.shadow_color = Color(pack.color("ink"), 0.9)
		box.shadow_size = 1
		box.shadow_offset = Vector2.ONE * float(pack.hud.shadow)
	box.anti_aliasing = true
	return box

# Text in a size that shrinks until it fits the width it is given.
func _write(label: Label, text: String, text_size: float, tone: Color, width: float = 0.0, outline: int = 0) -> void:
	var font = _font()
	var shown = _case(text)
	var scaled = int(text_size * clampf(float(_pack().hud.font_scale), 0.8, 1.15))
	while width > 0.0 and scaled > 11 and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled).x > width:
		scaled -= 1
	label.text = shown
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", scaled)
	label.add_theme_color_override("font_color", tone)
	label.add_theme_color_override("font_outline_color", _pack().color("ink"))
	label.add_theme_constant_override("outline_size", outline)

func _skin(button: Button, chosen: bool, text_size: int = 22) -> void:
	var pack = _pack()
	var fill = pack.color("ui_accent") if chosen else pack.color("ui_bg").lightened(0.1)
	var tone = _on(fill)
	button.add_theme_font_override("font", _font())
	button.add_theme_font_size_override("font_size", text_size)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, tone)
	button.add_theme_stylebox_override("normal", _box(fill, false))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.14), false))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.2), false))
	var halo = _box(Color.TRANSPARENT, false)
	halo.draw_center = false
	halo.border_color = pack.color("ui_fg")
	halo.set_border_width_all(3)
	halo.set_expand_margin_all(4)
	halo.set_corner_radius_all(int(pack.hud.radius) + 4)
	button.add_theme_stylebox_override("focus", halo)

# Readable text colour on a fill: the pack's ink or foreground, whichever contrasts more.
func _on(fill: Color) -> Color:
	var ink = _pack().color("ink")
	var fg = _pack().color("ui_fg")
	return ink if absf(fill.get_luminance() - ink.get_luminance()) > absf(fill.get_luminance() - fg.get_luminance()) else fg

func _refresh() -> void:
	var pack = _pack()
	var fg = pack.color("ui_fg")
	var accent = pack.color("ui_accent")
	var everywhere: bool = MODES[mode][3]
	desk.select(pick)
	desk.all_worlds = everywhere
	var panel = _box(Color(pack.color("ui_bg"), 0.94))
	panel.set_content_margin_all(14)
	side.add_theme_stylebox_override("panel", panel)
	var plate = _box(Color(pack.color("ui_bg"), 0.94))
	plate.content_margin_left = 18
	plate.content_margin_right = 18
	plate.content_margin_top = 8
	plate.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", plate)
	var inner = SIDE - 28.0 - 32.0
	for i in MODES.size():
		var chosen = i == mode
		_skin(mode_buttons[i], chosen)
		var labels: Array = mode_buttons[i].get_meta("labels")
		var tone = _on(pack.color("ui_accent") if chosen else pack.color("ui_bg").lightened(0.1))
		var score: int = main.best.get(MODES[i][0], 0)
		_write(labels[2], "Best %d" % score if score > 0 else "", 15, tone)
		var room = inner - (labels[2].get_minimum_size().x + 8.0 if score > 0 else 0.0)
		_write(labels[0], MODES[i][1], 23, tone, room)
		_write(labels[1], MODES[i][2], 15, Color(tone, 0.85), room)
	var world = pack.title
	_write(note, "Visits ALL dimensions\nStarting world: %s" % world if everywhere else "One dimension\nPlayed entirely in %s" % world, 15, accent if everywhere else fg, inner + 32.0)
	_write(level_label, "Difficulty", 16, fg, 92.0)
	for i in LEVELS.size():
		_skin(level_buttons[i], i == level, 18)
		level_buttons[i].text = _case(LEVELS[i])
	bots_row.visible = MODES[mode][0] == "skirmish"
	_write(bots_label, "Bots", 16, fg, 92.0)
	_write(bots_value, str(bots), 26, accent)
	for button in bots_buttons:
		_skin(button, false, 28)
	_skin(go, true, 30)
	go.text = _case("Start")
	_skin(quit, false, 18)
	quit.text = _case("Quit")
	for arrow in [prev, next]:
		_skin(arrow, false, 30)
		arrow.add_theme_stylebox_override("normal", _box(pack.color("ui_bg").lightened(0.1)))
		arrow.visible = packs.size() > 1
	_layout()

func _layout() -> void:
	if side == null or size.x <= 0.0:
		return
	var pack = _pack()
	var inset = TouchSticks.safe_insets(self)
	var left = inset[0] + EDGE
	var top = inset[1] + EDGE
	var right = size.x - inset[2] - EDGE
	var bottom = size.y - inset[3] - EDGE
	var wide = minf(SIDE, size.x * 0.44)
	side.position = Vector2(right - wide, top)
	side.size = Vector2(wide, bottom - top)
	var open = Rect2(left, top, right - wide - EDGE - left, bottom - top)
	# Title, top left of the open area.
	_write(title, "Paper, Plastic, Pew!", 52, pack.color("ui_accent"), open.size.x - 24.0, 12)
	title.reset_size()
	title.position = Vector2(left + 12.0, top + 10.0)
	title.pivot_offset = Vector2(0, title.size.y * 0.5)
	title.rotation_degrees = -float(pack.hud.tilt)
	# Name card with prev/next, bottom centre of the open area.
	var arrow = Vector2(64, 64)
	var plate_wide = clampf(open.size.x - arrow.x * 2.0 - 40.0, 240.0, 520.0)
	var text_room = plate_wide - 40.0
	_write(card_family, "%s family  -  %d of %d" % [pack.family, pick + 1, packs.size()], 14, pack.color("ui_accent"), text_room)
	_write(card_name, pack.title, 32, pack.color("ui_fg"), text_room)
	_write(card_tagline, pack.tagline, 16, Color(pack.color("ui_fg"), 0.85), text_room)
	card_tagline.visible = pack.tagline != ""
	card.size = Vector2(plate_wide, 0)
	card.reset_size()
	card.size.x = plate_wide
	card.position = Vector2(open.get_center().x - plate_wide * 0.5, bottom - card.size.y - 4.0)
	prev.size = arrow
	next.size = arrow
	prev.position = Vector2(card.position.x - arrow.x - 12.0, card.position.y + (card.size.y - arrow.y) * 0.5)
	next.position = Vector2(card.position.x + plate_wide + 12.0, prev.position.y)
	# The desk shows through between the title and the card.
	var stage_top = title.position.y + title.size.y
	desk.frame(size, Rect2(open.position.x, stage_top, open.size.x, card.position.y - stage_top))
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

# Name tags under the objects still lying on the desk.
func _draw() -> void:
	if desk == null or desk.objects.size() != packs.size() or not desk.settled:
		return
	var pack = _pack()
	var font = _font()
	for i in packs.size():
		if i == pick:
			continue
		var text = _case(packs[i].title)
		var at = desk.tag_point(i)
		var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var tag = Rect2(at.x - width * 0.5 - 10.0, at.y - 13.0, width + 20.0, 26.0)
		# Tags never slide under the side panel or the name card.
		if tag.end.x > side.position.x - 4.0 or tag.position.x < 0.0 or tag.end.y > card.position.y - 4.0:
			continue
		var box = _box(Color(pack.color("ui_bg"), 0.85 if i != desk.hovered else 1.0), false)
		box.set_border_width_all(mini(2, int(pack.hud.border)))
		box.set_corner_radius_all(mini(13, int(pack.hud.radius)))
		draw_style_box(box, tag)
		draw_string(font, Vector2(tag.position.x + 10.0, tag.position.y + 19.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, pack.color("ui_accent") if i == desk.hovered else pack.color("ui_fg"))
