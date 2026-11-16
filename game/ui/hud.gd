class_name Hud
extends Control
## In-game HUD. The layout never moves between dimensions; colours, font,
## corner radius, border, drop shadow and tilt come from the active pack's
## palette (ui_*) and "hud" block.

var game: GameMatch
var banner = ""
var banner_sub = ""
var banner_left = 0.0
var banner_span = 1.0
var sheet: VBoxContainer
var sheet_title: Label
var sheet_body: Label
var resume: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet = VBoxContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sheet.grow_vertical = Control.GROW_DIRECTION_BOTH
	sheet.add_theme_constant_override("separation", 14)
	sheet.visible = false
	add_child(sheet)
	sheet_title = Label.new()
	sheet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(sheet_title)
	sheet_body = Label.new()
	sheet_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(sheet_body)
	resume = _button("Resume", func(): game.set_paused(false))
	_button("Restart", func(): game.main.start(game.config))
	_button("Main menu", func(): game.main.show_menu())

func _button(text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 64)
	button.pressed.connect(action)
	sheet.add_child(button)
	return button

func announce(text: String, sub: String = "", seconds: float = 1.6) -> void:
	banner = text
	banner_sub = sub
	banner_left = seconds
	banner_span = seconds

## Pause / result sheet. An empty title hides it.
func show_sheet(title: String, body: String) -> void:
	sheet.visible = title != ""
	if not sheet.visible:
		return
	var pack = game.dimensions.active
	sheet_title.text = _case(title)
	sheet_body.text = body
	sheet_body.visible = body != ""
	resume.visible = not game.over
	var font = _font()
	sheet_title.add_theme_font_override("font", font)
	sheet_title.add_theme_font_size_override("font_size", 64)
	sheet_title.add_theme_color_override("font_color", pack.color("ui_accent"))
	sheet_title.add_theme_color_override("font_outline_color", pack.color("ink"))
	sheet_title.add_theme_constant_override("outline_size", 12)
	sheet_body.add_theme_font_override("font", font)
	sheet_body.add_theme_font_size_override("font_size", 28)
	sheet_body.add_theme_color_override("font_color", pack.color("ui_fg"))
	sheet_body.add_theme_color_override("font_outline_color", pack.color("ink"))
	sheet_body.add_theme_constant_override("outline_size", 8)
	for child in sheet.get_children():
		if child is Button:
			child.add_theme_font_override("font", font)
			child.add_theme_font_size_override("font_size", 28)
			child.add_theme_color_override("font_color", pack.color("ui_fg"))
			child.add_theme_color_override("font_hover_color", pack.color("ui_accent"))
			child.add_theme_stylebox_override("normal", _box(pack, pack.color("ui_bg")))
			child.add_theme_stylebox_override("hover", _box(pack, pack.color("ui_bg").lightened(0.15)))
			child.add_theme_stylebox_override("pressed", _box(pack, pack.color("ui_accent").darkened(0.3)))
			child.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _font() -> Font:
	var pack = game.dimensions.active
	return pack.font if pack.font != null else get_theme_default_font()

func _case(text: String) -> String:
	return text.to_upper() if game.dimensions.active.hud.uppercase else text

func _box(pack: DimensionPack, fill: Color) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = pack.color("ink")
	box.set_border_width_all(int(pack.hud.border))
	box.set_corner_radius_all(int(pack.hud.radius))
	box.shadow_color = Color(pack.color("ink"), 0.9)
	box.shadow_size = 1 if float(pack.hud.shadow) > 0.0 else 0
	box.shadow_offset = Vector2.ONE * float(pack.hud.shadow)
	box.anti_aliasing = true
	return box

func _process(delta: float) -> void:
	banner_left = maxf(0.0, banner_left - delta / maxf(Engine.time_scale, 0.01))
	queue_redraw()

func _panel(rect: Rect2, fill: Color, tilt: float) -> void:
	var pack = game.dimensions.active
	draw_set_transform(rect.get_center(), deg_to_rad(tilt * float(pack.hud.tilt)), Vector2.ONE)
	draw_style_box(_box(pack, fill), Rect2(-rect.size * 0.5, rect.size))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _text(at: Vector2, text: String, text_size: int, tone: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 0) -> void:
	var pack = game.dimensions.active
	var font = _font()
	var scaled = int(text_size * float(pack.hud.font_scale))
	var shown = _case(text)
	var width = font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled).x
	var origin = at - Vector2(width * (0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else 1.0 if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0), 0)
	if outline > 0:
		draw_string_outline(font, origin, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled, outline, pack.color("ink"))
	draw_string(font, origin, shown, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled, tone)

func _bar(rect: Rect2, ratio: float, tone: Color) -> void:
	var pack = game.dimensions.active
	_panel(rect, pack.color("ui_bg"), 0.0)
	var inner = rect.grow(-float(pack.hud.border) - 2.0)
	inner.size.x *= clampf(ratio, 0.0, 1.0)
	if inner.size.x > 1.0:
		var fill = StyleBoxFlat.new()
		fill.bg_color = tone
		fill.set_corner_radius_all(int(maxf(0.0, float(pack.hud.radius) - float(pack.hud.border) - 2.0)))
		draw_style_box(fill, inner)

func _draw() -> void:
	if game == null or game.player == null:
		return
	var pack = game.dimensions.active
	var inset = TouchSticks.safe_insets(self)
	var left = inset[0] + 24.0
	var top = inset[1] + 20.0
	var right = size.x - inset[2] - 24.0
	var player = game.player
	var fg = pack.color("ui_fg")
	var accent = pack.color("ui_accent")
	var director = game.director
	# Health and weapon, top left.
	_bar(Rect2(left, top, 300, 34), player.health / player.max_health, pack.color("ui_danger") if player.health < 35 else pack.color("pickup_health"))
	_text(Vector2(left + 14, top + 25), "%d" % ceilf(player.health), 20, fg, HORIZONTAL_ALIGNMENT_LEFT, 6)
	_panel(Rect2(left, top + 46, 210, 44), pack.color("ui_bg"), -1.0)
	var rounds: int = player.ammo.get(player.weapon_id, -1)
	_text(Vector2(left + 14, top + 77), game.weapons[player.weapon_id].name, 22, accent)
	_text(Vector2(left + 196, top + 77), "INF" if rounds < 0 else str(rounds), 22, fg, HORIZONTAL_ALIGNMENT_RIGHT)
	_bar(Rect2(left, top + 98, 120, 14), 1.0 - player.dash_wait / Player.DASH_COOLDOWN, accent)
	# Mode status, top centre.
	var middle = size.x * 0.5
	if director.mode == "skirmish":
		var rows = director.board()
		_panel(Rect2(right - 250, top + 64, 200, 20 + rows.size() * 26), Color(pack.color("ui_bg"), 0.8), 1.0)
		for i in rows.size():
			var tone = accent if rows[i][0] == player.label else fg
			_text(Vector2(right - 236, top + 92 + i * 26), rows[i][0], 20, tone)
			_text(Vector2(right - 64, top + 92 + i * 26), str(rows[i][1]), 20, tone, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(Vector2(middle, top + 30), "First to %d" % Director.KILL_LIMIT, 26, fg, HORIZONTAL_ALIGNMENT_CENTER, 8)
		if not player.alive and not game.over:
			_text(Vector2(middle, size.y * 0.6), "Respawning...", 30, fg, HORIZONTAL_ALIGNMENT_CENTER, 8)
	else:
		_panel(Rect2(middle - 150, top, 300, 46), pack.color("ui_bg"), 1.0)
		_text(Vector2(middle - 134, top + 32), "Wave %d" % director.wave, 24, accent)
		_text(Vector2(middle + 134, top + 32), "%d" % game.score, 24, fg, HORIZONTAL_ALIGNMENT_RIGHT)
		if is_instance_valid(director.boss) and director.boss.alive:
			_bar(Rect2(middle - 260, top + 58, 520, 22), director.boss.health / director.boss.max_health, pack.color("boss"))
	if game.shifting:
		var warn = director.shift_timer < 3.0
		_text(Vector2(middle, top + 112), "Shift in %d" % ceilf(director.shift_timer) if warn else pack.title, 30 if warn else 20, accent if warn else fg, HORIZONTAL_ALIGNMENT_CENTER, 8)
	# Announcement banner.
	if banner_left > 0.0 and not sheet.visible:
		var age = banner_span - banner_left
		var pop = minf(1.0, age * 8.0) * minf(1.0, banner_left * 4.0)
		var at = Vector2(middle, size.y * 0.3)
		draw_set_transform(at, deg_to_rad(-2.0 * float(pack.hud.tilt)), Vector2.ONE * (0.6 + 0.4 * pop))
		var tone = Color(accent, pop)
		var font = _font()
		var shown = _case(banner)
		var width = font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x
		draw_string_outline(font, Vector2(-width * 0.5, 0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 14, Color(pack.color("ink"), pop))
		draw_string(font, Vector2(-width * 0.5, 0), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, tone)
		if banner_sub != "":
			var sub_width = font.get_string_size(banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
			draw_string_outline(font, Vector2(-sub_width * 0.5, 44), banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 8, Color(pack.color("ink"), pop))
			draw_string(font, Vector2(-sub_width * 0.5, 44), banner_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(fg, pop))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
