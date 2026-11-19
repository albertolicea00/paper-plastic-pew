class_name TouchSticks
extends Control
## Dual floating sticks: the left half moves, the right aims. A dedicated FIRE
## button shoots; dragging FIRE up past a lock toggles auto-fire, where pushing
## the right stick shoots instead (and FIRE shows locked). Buttons press normal
## input actions, so gameplay reads the same actions on every device.

const RADIUS = 80.0
const FIRE_AT = 0.3
const LOCK_DIST = 80.0
var move = Vector2.ZERO
var aim = Vector2.ZERO
# Unnormalised right stick, for views that turn with it instead of pointing.
var aim_raw = Vector2.ZERO
var firing = false
# Auto-fire: the right stick shoots and FIRE sits locked. Set by the match from
# the saved setting; save_auto persists a change the player makes by dragging.
var auto_fire = false
var save_auto: Callable
# One entry per stick: finger index, where it went down, where the thumb is.
var sticks = [{"finger": -1, "origin": Vector2.ZERO, "thumb": Vector2.ZERO}, {"finger": -1, "origin": Vector2.ZERO, "thumb": Vector2.ZERO}]
var held: Dictionary = {}
var buttons: Dictionary = {}
var fire_button: Array = []
var fire_finger = -1
var fire_origin = Vector2.ZERO
var fire_drag = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

static func safe_insets(control: Control) -> Array:
	# Desktop windows report the monitor's menu bar or notch; only phones need insets.
	if not OS.has_feature("mobile"):
		return [0.0, 0.0, 0.0, 0.0]
	var screen = Vector2(DisplayServer.screen_get_size())
	var safe = DisplayServer.get_display_safe_area()
	if screen.x <= 0 or screen.y <= 0 or safe.size.x <= 0:
		return [0.0, 0.0, 0.0, 0.0]
	var scale = control.size / screen
	return [maxf(0.0, safe.position.x * scale.x), maxf(0.0, safe.position.y * scale.y), maxf(0.0, (screen.x - safe.end.x) * scale.x), maxf(0.0, (screen.y - safe.end.y) * scale.y)]

func layout() -> void:
	var inset = safe_insets(self)
	var left = inset[0]
	var right = size.x - inset[2]
	var top = inset[1]
	var bottom = size.y - inset[3]
	# FIRE takes the spot SWAP used to hold; DASH stays in the lower cluster.
	fire_button = [Vector2(right - 210, bottom - 330), 36.0, "FIRE"]
	buttons = {
		"dash": [Vector2(right - 90, bottom - 290), 44.0, "DASH"],
		"view": [Vector2(left + 150, bottom - 310), 30.0, "VIEW"],
		# SWAP sits up by the pause button for now; it is slated to be deprecated.
		"swap": [Vector2(right - 112, top + 46), 28.0, "SWAP"],
		"pause": [Vector2(right - 46, top + 46), 28.0, "II"] }

func rest(side: int) -> Vector2:
	var inset = safe_insets(self)
	return Vector2(inset[0] + 160, size.y - inset[3] - 150) if side == 0 else Vector2(size.x - inset[2] - 190, size.y - inset[3] - 140)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		layout()
		if event.pressed:
			_press(event)
		else:
			if event.index == fire_finger:
				fire_finger = -1
				fire_drag = 0.0
			var action: String = held.get(event.index, "")
			held.erase(event.index)
			if action != "" and not held.values().has(action):
				Input.action_release(action)
			for stick in sticks:
				if stick.finger == event.index:
					stick.finger = -1
			_read()
	elif event is InputEventScreenDrag:
		if event.index == fire_finger:
			_drag_fire(event.position)
		for stick in sticks:
			if stick.finger == event.index:
				stick.thumb = stick.origin + ((event.position - stick.origin) / RADIUS).limit_length() * RADIUS
		_read()

func _press(event: InputEventScreenTouch) -> void:
	if event.position.distance_to(fire_button[0]) < fire_button[1] + 10:
		fire_finger = event.index
		fire_origin = event.position
		fire_drag = 0.0
		_read()
		return
	for action in buttons:
		if event.position.distance_to(buttons[action][0]) < buttons[action][1] + 10:
			held[event.index] = action
			Input.action_press(action)
			return
	var side = 0 if event.position.x < size.x * 0.5 else 1
	if sticks[side].finger < 0:
		sticks[side].finger = event.index
		sticks[side].origin = event.position
		sticks[side].thumb = event.position

# Dragging FIRE up locks auto-fire; dragging it down unlocks to manual.
func _drag_fire(at: Vector2) -> void:
	var up = fire_origin.y - at.y
	fire_drag = clampf(up / LOCK_DIST, -1.0, 1.0)
	if up > LOCK_DIST and not auto_fire:
		_set_auto(true)
	elif up < -LOCK_DIST and auto_fire:
		_set_auto(false)

func _set_auto(value: bool) -> void:
	auto_fire = value
	if save_auto.is_valid():
		save_auto.call(value)
	_read()

func _read() -> void:
	var values = []
	for stick in sticks:
		values.append((stick.thumb - stick.origin) / RADIUS if stick.finger >= 0 else Vector2.ZERO)
	move = values[0]
	aim_raw = values[1]
	if values[1].length() > 0.12:
		aim = values[1].normalized()
	elif sticks[1].finger < 0:
		aim = Vector2.ZERO
	# Auto: the right stick fires. Manual: the FIRE button fires.
	if auto_fire:
		firing = values[1].length() > FIRE_AT
	else:
		firing = fire_finger >= 0

func reset() -> void:
	for action in held.values():
		Input.action_release(action)
	held.clear()
	for stick in sticks:
		stick.finger = -1
	fire_finger = -1
	fire_drag = 0.0
	_read()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	layout()
	var pack = Dimensions.hub.active
	var line = Color(pack.color("ui_fg"), 0.8)
	var fill = Color(pack.color("ui_bg"), 0.35)
	var accent = pack.color("ui_accent")
	var font = pack.font if pack.font != null else get_theme_default_font()
	for side in 2:
		var stick: Dictionary = sticks[side]
		var center: Vector2 = stick.origin if stick.finger >= 0 else rest(side)
		var knob: Vector2 = stick.thumb if stick.finger >= 0 else center
		var lit = side == 1 and firing
		var tone = Color(accent, 0.9) if lit else line
		draw_circle(center, RADIUS, fill)
		draw_arc(center, RADIUS, 0, TAU, 48, tone, 3.0, true)
		draw_circle(knob, RADIUS * 0.4, Color(tone, 0.45))
		draw_arc(knob, RADIUS * 0.4, 0, TAU, 32, tone, 3.0, true)
	for action in buttons:
		var button: Array = buttons[action]
		draw_circle(button[0], button[1], Color(accent, 0.5) if held.values().has(action) else fill)
		draw_arc(button[0], button[1], 0, TAU, 32, line, 3.0, true)
		_icon(action, button[0], button[1] * 0.55, line)
	_draw_fire(font, pack, line, fill, accent)

# Line-art icons per action, drawn in the world's own colour. A size, not text,
# so the controls read the same in every language and match each dimension.
func _icon(name: String, at: Vector2, r: float, col: Color) -> void:
	match name:
		"fire":
			draw_arc(at, r * 0.75, 0, TAU, 20, col, 3.0, true)
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_line(at + d * r * 0.45, at + d * r * 1.05, col, 3.0, true)
			draw_circle(at, r * 0.14, col)
		"dash":
			for ox in [-0.28, 0.34]:
				var b = at + Vector2(ox * r, 0)
				draw_polyline(PackedVector2Array([b + Vector2(-r * 0.3, -r * 0.55), b + Vector2(r * 0.32, 0), b + Vector2(-r * 0.3, r * 0.55)]), col, 3.0, true)
		"view":
			draw_arc(at, r * 0.95, deg_to_rad(205), deg_to_rad(335), 14, col, 3.0, true)
			draw_arc(at, r * 0.95, deg_to_rad(25), deg_to_rad(155), 14, col, 3.0, true)
			draw_circle(at, r * 0.32, col)
		"swap":
			draw_arc(at, r * 0.62, deg_to_rad(300), deg_to_rad(560), 22, col, 3.0, true)
			var tip = at + Vector2(cos(deg_to_rad(300)), sin(deg_to_rad(300))) * r * 0.62
			draw_line(tip, tip + Vector2(-r * 0.3, -r * 0.05), col, 3.0, true)
			draw_line(tip, tip + Vector2(0.0, -r * 0.32), col, 3.0, true)
		"pause":
			for sx in [-1.0, 1.0]:
				draw_rect(Rect2(at + Vector2(sx * r * 0.32 - r * 0.11, -r * 0.5), Vector2(r * 0.22, r)), col)

# FIRE button: filled when firing or locked, with a lock badge in auto mode and
# a lock hint sliding up while the player drags toward the lock.
func _draw_fire(font: Font, pack: DimensionPack, line: Color, fill: Color, accent: Color) -> void:
	var at: Vector2 = fire_button[0]
	var r: float = fire_button[1]
	var down = firing or auto_fire or fire_finger >= 0
	draw_circle(at, r, Color(accent, 0.55) if down else fill)
	draw_arc(at, r, 0, TAU, 40, accent if (firing or auto_fire) else line, 4.0, true)
	if auto_fire:
		_padlock(at, r * 0.5, Color(pack.color("ui_fg"), 0.95), true)
	else:
		_icon("fire", at, r * 0.55, line)
		# While dragging up, a lock hint fills in above the button.
		if fire_drag > 0.05:
			var hint = at + Vector2(0, -r - 34.0)
			draw_line(at + Vector2(0, -r), hint + Vector2(0, 14), Color(accent, fire_drag), 3.0)
			_padlock(hint, 16.0, Color(accent, 0.3 + 0.7 * fire_drag), fire_drag >= 1.0)

func _padlock(at: Vector2, r: float, col: Color, closed: bool) -> void:
	var shackle = at + Vector2(0, -r * 0.4)
	draw_arc(shackle, r * 0.5, PI, TAU, 16, col, 3.0, true)
	if not closed:
		draw_line(shackle + Vector2(r * 0.5, 0), shackle + Vector2(r * 0.5, r * 0.4), col, 3.0)
	draw_rect(Rect2(at - Vector2(r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.8)), col, true)

func _label(font: Font, at: Vector2, text: String, text_size: int, tone: Color) -> void:
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	draw_string(font, at + Vector2(-width * 0.5, text_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, tone)
