class_name GameMatch
extends Node3D
## One play session: arena, actors, camera and the systems around them.
## config: {mode, dimension, arena, bots, difficulty, touch, autopilot}

const PLAYER_TEAM = 1
const ENEMY_TEAM = 2
const CAMERA_OFFSET = Vector3(0, 21, 12)
# Camera views, chosen in the options: from above, behind the character, from the weapon.
const VIEWS = ["top", "shoulder", "weapon"]
const VIEW_NAMES = {"top": "Top-down", "shoulder": "Behind", "weapon": "Weapon"}
const VIEW_FOV = {"top": 45.0, "shoulder": 62.0, "weapon": 74.0}
const WARM_ROLES = ["floor", "wall", "prop", "character", "weapon", "bullet", "pickup", "flash"]
const DATA = "res://core/data/"

var main: Node
var config: Dictionary = {}
var dimensions: Dimensions
var sfx: Sfx
var weapons: Dictionary = {}
var kinds: Dictionary = {}
var playing = false
var paused = false
var over = false
var victory = false
var autopilot = false
var shifting = false
var time_scale = 1.0
var score = 0
var arena: Arena
var player: Player
var projectiles: Projectiles
var vfx: Vfx
var director: Director
var camera: Camera3D
var input: TwinInput
var touch: TouchSticks
var hud: Hud
var world: WorldEnvironment
var sun: DirectionalLight3D
var actors: Array[Actor] = []
var pickups: Array[Node3D] = []
var view = "top"
var focus = Vector3.ZERO

static func read(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA + file))

func setup(owner_main: Node, match_config: Dictionary) -> void:
	main = owner_main
	config = match_config
	dimensions = main.dimensions
	sfx = main.sfx
	autopilot = config.get("autopilot", false)
	shifting = config.get("mode", "survival") == "shift"

func _ready() -> void:
	weapons = read("weapons.json")
	kinds = read("enemies.json")
	var arenas = read("arenas.json")
	dimensions.shift_to(config.get("dimension", dimensions.active.id))
	world = WorldEnvironment.new()
	world.environment = Environment.new()
	add_child(world)
	sun = DirectionalLight3D.new()
	add_child(sun)
	arena = Arena.new()
	add_child(arena)
	# A dimension's own arenas are used when the whole match stays in it.
	var own: Dictionary = dimensions.active.arenas
	var pool = own if not own.is_empty() and not shifting and config.get("mode", "") != "campaign" else arenas
	var wanted: String = config.get("arena", "")
	arena.build(own.get(wanted, arenas.get(wanted, pool[pool.keys().pick_random()])))
	projectiles = Projectiles.new()
	vfx = Vfx.new()
	camera = Camera3D.new()
	camera.near = 0.1
	camera.far = 150.0
	camera.position = CAMERA_OFFSET
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	player = spawn("player", arena.player_start, PLAYER_TEAM) as Player
	player.persistent = true
	add_child(projectiles)
	add_child(vfx)
	focus = player.position
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	touch = TouchSticks.new()
	touch.visible = config.get("touch", false)
	layer.add_child(touch)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	input = TwinInput.new()
	input.game = self
	input.touch = touch
	if touch.visible:
		input.device = "touch"
	add_child(input)
	director = Director.new()
	director.game = self
	add_child(director)
	dimensions.shifted.connect(_on_shift)
	_apply_environment(dimensions.active)
	_warm_up()
	sfx.music()
	Input.emulate_mouse_from_touch = false
	playing = true
	set_view(config.get("view", main.settings.get("view", "top")))
	director.start()

func spawn(kind: String, at: Vector3, team: int) -> Actor:
	var actor: Actor = Player.new() if kind == "player" else Enemy.new()
	actor.setup(self, kind, team)
	actor.position = at
	add_child(actor)
	actor.died.connect(_on_died)
	actors.append(actor)
	return actor

func nearest_hostile(actor: Actor) -> Actor:
	var best: Actor = null
	var best_gap = INF
	for other in actors:
		if other.alive and other.team != actor.team:
			var gap = other.global_position.distance_squared_to(actor.global_position)
			if gap < best_gap:
				best_gap = gap
				best = other
	return best

## True when no world geometry blocks the straight line between two points.
func clear_line(from: Vector3, to: Vector3) -> bool:
	var lift = Vector3(0, Actor.MUZZLE_HEIGHT, 0)
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from + lift, to + lift, 1)).is_empty()

func on_hit(actor: Actor, _amount: float, _from: Actor) -> void:
	if actor == player:
		vfx.shake(0.35)
		vfx.impact(0.6)
		sfx.play("hurt")
	else:
		sfx.play("hit", actor.global_position)

func _on_died(actor: Actor, killer: Actor) -> void:
	if not actor.persistent:
		actors.erase(actor)
	vfx.burst(actor.global_position + Vector3(0, 0.8, 0), actor.spec.look.get("color", "grunt"), 18 if actor.kind != "boss" else 60, 8.0)
	sfx.play("die", actor.global_position)
	if killer == player and actor != player:
		score += int(actor.spec.get("score", 0)) * (2 if shifting else 1)
		vfx.hitstop(3.0 if actor.kind == "boss" else 1.0)
		vfx.impact(0.5)
		var roll = randf()
		if actor.team == ENEMY_TEAM and roll < 0.2:
			drop(actor.global_position, "health" if roll < 0.09 else ["scatter", "rapid", "launcher"].pick_random())
	director.on_death(actor, killer)

func set_view(next: String) -> void:
	view = next if next in VIEWS else "top"
	camera.fov = VIEW_FOV[view]
	player.rig.set_first_person(view == "weapon")
	_update_mouse()

# Views that turn with the mouse need it captured while the fight is on.
func _update_mouse() -> void:
	var grab = playing and view != "top" and not autopilot and input.device == "mouse"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if grab else Input.MOUSE_MODE_VISIBLE

func _place_camera() -> void:
	var at = player.global_position
	var aim = player.aim
	match view:
		"shoulder":
			var head = at + Vector3(0, 1.5, 0)
			var seat = head - aim * 5.0 + Vector3(0, 1.7, 0) + aim.rotated(Vector3.UP, -PI * 0.5) * 0.7
			# Walls push the camera in instead of hiding the character.
			var hit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(head, seat, 1))
			if not hit.is_empty():
				seat = hit.position + (head - seat).normalized() * 0.3
			camera.position = seat
			camera.look_at(at + aim * 6.0 + Vector3(0, 1.0, 0))
		"weapon":
			camera.position = at + Vector3(0, 1.3, 0) - aim * 0.25
			camera.look_at(camera.position + aim)
		_:
			camera.position = focus + CAMERA_OFFSET
			camera.look_at(focus)
	camera.position += vfx.camera_offset() * (0.25 if view != "top" else 1.0)

func drop(at: Vector3, what: String) -> void:
	var node = Node3D.new()
	dimensions.active.builder.pickup(node, what)
	node.position = arena.clamp_inside(at) + Vector3(0, 0.6, 0)
	node.set_meta("what", what)
	node.set_meta("life", 14.0)
	add_child(node)
	pickups.append(node)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not over:
		set_paused(not paused)
	if Input.is_action_just_pressed("view") and playing:
		set_view(VIEWS[(VIEWS.find(view) + 1) % VIEWS.size()])
		main.set_setting("view", view)
		hud.announce(VIEW_NAMES[view], "", 1.0)
	if not playing:
		return
	_update_mouse()
	var lead = player.aim * 2.0 if player.alive else Vector3.ZERO
	focus = focus.lerp(arena.clamp_inside(player.global_position + lead, 3.0), 1.0 - exp(-delta * 6.0))
	_place_camera()
	for node in pickups.duplicate():
		node.rotation.y += delta * 2.5
		node.position.y = 0.6 + sin(node.rotation.y * 1.3) * 0.12
		var life: float = node.get_meta("life") - delta
		node.set_meta("life", life)
		node.visible = life > 3.0 or fmod(life, 0.3) > 0.12
		var taken = player.alive and node.position.distance_to(player.global_position + Vector3(0, 0.6, 0)) < 1.3
		if taken:
			var what: String = node.get_meta("what")
			if what == "health":
				player.heal(30.0)
			else:
				player.grant(what)
				hud.announce(dimensions.active.label(what, weapons[what].name), "", 1.0)
			sfx.play("pickup")
			vfx.burst(node.position, "pickup_health" if what == "health" else "pickup_ammo", 10, 5.0)
		if taken or life <= 0.0:
			pickups.erase(node)
			node.queue_free()

func set_paused(value: bool) -> void:
	paused = value
	playing = not value
	touch.reset()
	Input.emulate_mouse_from_touch = value
	_update_mouse()
	hud.show_sheet("Paused" if value else "", "")

func end(won: bool) -> void:
	if over:
		return
	over = true
	victory = won
	playing = false
	touch.reset()
	Engine.time_scale = time_scale
	Input.emulate_mouse_from_touch = true
	_update_mouse()
	sfx.play("win" if won else "lose")
	main.record(config.get("mode", "survival"), score)
	hud.show_sheet("Victory!" if won else "Game over", director.summary())

func _on_shift(pack: DimensionPack) -> void:
	_apply_environment(pack)
	vfx.shift_flash(pack)
	sfx.play("shift")
	sfx.music()
	hud.announce(pack.title, pack.tagline, 2.2)
	for node in pickups:
		for child in node.get_children():
			child.free()
		pack.builder.pickup(node, node.get_meta("what"))

func _apply_environment(pack: DimensionPack) -> void:
	var settings = pack.environment
	var environment = world.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = pack.color("bg")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.html(settings.ambient)
	environment.ambient_light_energy = float(settings.ambient_energy)
	sun.light_color = Color.html(settings.light)
	sun.light_energy = float(settings.light_energy)
	sun.rotation_degrees = Vector3(float(settings.light_pitch), float(settings.light_yaw), 0)
	sun.shadow_enabled = bool(settings.shadows)

# Draw one tiny mesh per shader of every pack for a few frames so the first
# real dimension shift does not stall on shader compilation.
func _warm_up() -> void:
	var holder = Node3D.new()
	holder.position = Vector3(focus.x, -0.6, focus.z)
	add_child(holder)
	var quad = QuadMesh.new()
	quad.size = Vector2.ONE * 0.05
	var swarm = MultiMesh.new()
	swarm.transform_format = MultiMesh.TRANSFORM_3D
	swarm.mesh = quad
	swarm.instance_count = 1
	swarm.set_instance_transform(0, Transform3D.IDENTITY)
	for pack in dimensions.packs:
		for role in WARM_ROLES:
			var node: GeometryInstance3D
			if role == "bullet":
				node = MultiMeshInstance3D.new()
				node.multimesh = swarm
			else:
				node = MeshInstance3D.new()
				node.mesh = quad
			node.material_override = pack.material(role, "flash")
			holder.add_child(node)
		if pack.overlay != null:
			var dot = ColorRect.new()
			dot.size = Vector2(2, 2)
			dot.material = pack.overlay
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vfx.layer.add_child(dot)
			get_tree().create_timer(0.5).timeout.connect(dot.queue_free)
	get_tree().create_timer(0.5).timeout.connect(holder.queue_free)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Input.emulate_mouse_from_touch = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
