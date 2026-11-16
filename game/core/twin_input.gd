class_name TwinInput
extends Node
## One twin-stick reading from whichever device was used last:
## mouse + keyboard, gamepad, or the touch sticks.
## `move` and `aim` are screen-plane vectors (x right, y down = world +Z).

const ACTIONS = {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"dash": [KEY_SPACE, KEY_SHIFT], "swap": [KEY_Q, KEY_E], "pause": [KEY_ESCAPE, KEY_P], "view": [KEY_V], "fire": [] }
const AXES = {
	"move_left": [JOY_AXIS_LEFT_X, -1], "move_right": [JOY_AXIS_LEFT_X, 1], "move_up": [JOY_AXIS_LEFT_Y, -1], "move_down": [JOY_AXIS_LEFT_Y, 1],
	"aim_left": [JOY_AXIS_RIGHT_X, -1], "aim_right": [JOY_AXIS_RIGHT_X, 1], "aim_up": [JOY_AXIS_RIGHT_Y, -1], "aim_down": [JOY_AXIS_RIGHT_Y, 1],
	"fire": [JOY_AXIS_TRIGGER_RIGHT, 1] }
const BUTTONS = {"dash": [JOY_BUTTON_A, JOY_BUTTON_LEFT_SHOULDER], "swap": [JOY_BUTTON_Y, JOY_BUTTON_RIGHT_SHOULDER], "pause": [JOY_BUTTON_START], "view": [JOY_BUTTON_BACK]}
const MOUSE_TURN = 0.0028
const STICK_TURN = 2.8

var game: GameMatch
var touch: TouchSticks
var device = "mouse"
var move = Vector2.ZERO
var aim = Vector2.ZERO
var firing = false
# Turn in radians gathered since the player last took it (behind and weapon views).
var look = 0.0

static func register_actions() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "aim_left", "aim_right", "aim_up", "aim_down", "fire", "dash", "swap", "pause", "view"]:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.25)
		for key in ACTIONS.get(action, []):
			var press = InputEventKey.new()
			press.physical_keycode = key
			InputMap.action_add_event(action, press)
		if AXES.has(action):
			var tilt = InputEventJoypadMotion.new()
			tilt.axis = AXES[action][0]
			tilt.axis_value = AXES[action][1]
			InputMap.action_add_event(action, tilt)
		for button in BUTTONS.get(action, []):
			var pad = InputEventJoypadButton.new()
			pad.button_index = button
			InputMap.action_add_event(action, pad)
		if action == "fire":
			var click = InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			InputMap.action_add_event(action, click)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		device = "touch"
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		device = "pad"
	elif (event is InputEventMouse or event is InputEventKey) and event.device != InputEvent.DEVICE_ID_EMULATION:
		device = "mouse"
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look += event.relative.x * MOUSE_TURN
	if touch != null:
		touch.visible = device == "touch" or game.config.get("touch", false)

func take_look() -> float:
	var turned = look
	look = 0.0
	return turned

func _process(delta: float) -> void:
	move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if game.view != "top":
		# The camera follows the facing, so the second stick turns instead of pointing.
		aim = Vector2.ZERO
		match device:
			"touch":
				move = touch.move
				look += touch.aim_raw.x * STICK_TURN * delta
				firing = touch.firing
			"pad":
				look += Input.get_axis("aim_left", "aim_right") * STICK_TURN * delta
				firing = Input.is_action_pressed("fire")
			_:
				firing = Input.is_action_pressed("fire")
		return
	match device:
		"touch":
			move = touch.move
			aim = touch.aim
			firing = touch.firing
		"pad":
			aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.3)
			firing = aim.length() > 0.5 or Input.is_action_pressed("fire")
		_:
			# Aim at the point under the cursor on the muzzle-height plane.
			var camera = game.camera
			var mouse = get_viewport().get_mouse_position()
			var hit = Plane(Vector3.UP, Actor.MUZZLE_HEIGHT).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
			if hit != null and is_instance_valid(game.player):
				var to: Vector3 = hit - game.player.global_position
				aim = Vector2(to.x, to.z).normalized()
			firing = Input.is_action_pressed("fire")
