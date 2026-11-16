class_name TouchSticks
extends Control
## Dual floating sticks: the left half of the screen moves, the right half
## aims and fires while pushed. Buttons press normal input actions, so
## gameplay code reads the same actions on every device.

const RADIUS = 80.0
const FIRE_AT = 0.3
var move = Vector2.ZERO
var aim = Vector2.ZERO
var firing = false
# One entry per stick: finger index, where it went down, where the thumb is.
var sticks = [{"finger": -1, "origin": Vector2.ZERO, "thumb": Vector2.ZERO}, {"finger": -1, "origin": Vector2.ZERO, "thumb": Vector2.ZERO}]
var held: Dictionary = {}
var buttons: Dictionary = {}

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
	var right = size.x - inset[2]
	var bottom = size.y - inset[3]
	buttons = {
		"dash": [Vector2(right - 90, bottom - 290), 44.0, "DASH"],
		"swap": [Vector2(right - 210, bottom - 330), 36.0, "SWAP"],
		"pause": [Vector2(right - 46, inset[1] + 46), 28.0, "II"] }

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
			var action: String = held.get(event.index, "")
			held.erase(event.index)
			if action != "" and not held.values().has(action):
				Input.action_release(action)
			for stick in sticks:
				if stick.finger == event.index:
					stick.finger = -1
			_read()
	elif event is InputEventScreenDrag:
		for stick in sticks:
			if stick.finger == event.index:
				stick.thumb = stick.origin + ((event.position - stick.origin) / RADIUS).limit_length() * RADIUS
		_read()

func _press(event: InputEventScreenTouch) -> void:
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

func _read() -> void:
	var values = []
	for stick in sticks:
		values.append((stick.thumb - stick.origin) / RADIUS if stick.finger >= 0 else Vector2.ZERO)
	move = values[0]
	firing = values[1].length() > FIRE_AT
	if values[1].length() > 0.12:
		aim = values[1].normalized()
	elif sticks[1].finger < 0:
		aim = Vector2.ZERO

func reset() -> void:
	for action in held.values():
		Input.action_release(action)
	held.clear()
	for stick in sticks:
		stick.finger = -1
	_read()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	layout()
	var pack = Dimensions.hub.active
	var line = Color(pack.color("ui_fg"), 0.8)
	var fill = Color(pack.color("ui_bg"), 0.35)
	var font = pack.font if pack.font != null else get_theme_default_font()
	for side in 2:
		var stick: Dictionary = sticks[side]
		var center: Vector2 = stick.origin if stick.finger >= 0 else rest(side)
		var knob: Vector2 = stick.thumb if stick.finger >= 0 else center
		var tone = Color(pack.color("ui_accent"), 0.9) if side == 1 and firing else line
		draw_circle(center, RADIUS, fill)
		draw_arc(center, RADIUS, 0, TAU, 48, tone, 3.0, true)
		draw_circle(knob, RADIUS * 0.4, Color(tone, 0.45))
		draw_arc(knob, RADIUS * 0.4, 0, TAU, 32, tone, 3.0, true)
	for action in buttons:
		var button: Array = buttons[action]
		draw_circle(button[0], button[1], Color(pack.color("ui_accent"), 0.5) if held.values().has(action) else fill)
		draw_arc(button[0], button[1], 0, TAU, 32, line, 3.0, true)
		var text_size = int(button[1] * 0.45)
		var width = font.get_string_size(button[2], HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		draw_string(font, button[0] + Vector2(-width * 0.5, text_size * 0.35), button[2], HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, line)
