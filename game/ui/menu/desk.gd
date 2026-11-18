class_name MenuDesk
extends Node3D
## The 3D half of the main menu: an artist's desk with one object per
## dimension pack. The desk itself is restyled with the picked pack, each
## object keeps its own pack's materials. One camera, one light.

const SPACING = 2.5
const PITCH = 50.0
const FOV = 38.0
const NEAR = 8.6
const FAR = 13.0

var packs: Array = []
var objects: Array[MenuDeskObject] = []
var forced: Array = []
var selected = 0
var hovered = -1
# Modes that visit every dimension nudge the other objects up too.
var all_worlds = false
var camera: Camera3D
var sun: DirectionalLight3D
var sky: Environment
var ring: MeshInstance3D
var glow: StandardMaterial3D
var dressed: Array = []
var clock = 0.0
var view = Vector2(1280, 720)
var open_area = Rect2(0, 0, 860, 720)
var settled = false
var mood: DimensionPack

func setup(all_packs: Array, forced_kinds: Array = []) -> void:
	packs = all_packs
	forced = forced_kinds

func slot(index: int) -> Vector3:
	return Vector3((index - (packs.size() - 1) * 0.5) * SPACING, 0.03, 0)

func _ready() -> void:
	sky = Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera = Camera3D.new()
	camera.fov = FOV
	camera.environment = sky
	add_child(camera)
	camera.make_current()
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56, -32, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	var span = maxf(packs.size(), 3) * SPACING
	# Desk top, cutting mat and a little clutter, all in the picked dimension.
	_dress(MenuDeskObject.slab(span + 60.0, 0.5, 18.0), "prop", "wall", Vector3(0, -0.25, 5.4))
	_dress(MenuDeskObject.slab(span + 60.0, 2.6, 0.3), "prop", "weapon", Vector3(0, -1.5, -3.75))
	_dress(MenuDeskObject.slab(span + 1.3, 0.03, 4.3), "floor", "floor", Vector3(0, 0.015, 0.25))
	var left = -span * 0.5 - 1.5
	var right = span * 0.5 + 1.5
	_dress(MenuDeskObject.tube(0.36, 0.7, 0.4), "prop", "wall", Vector3(right, 0.35, -2.0))
	var tints = ["prop", "bot", "runner"]
	for i in 3:
		_dress(MenuDeskObject.tube(0.035, 1.3), "prop", tints[i], Vector3(right - 0.14 + i * 0.14, 0.95, -2.0 + (i % 2) * 0.1), Vector3(8 - i * 9, 0, 10 - i * 11))
		_dress(MenuDeskObject.tube(0.05, 1.7), "prop", ["player_accent", "bullet_enemy", "pickup_ammo"][i], Vector3(left - i * 0.22, 0.05, 1.2 + i * 0.25), Vector3(90, 14 + i * 9, 0))
	_dress(MenuDeskObject.slab(0.6, 0.22, 0.34), "prop", "ui_danger", Vector3(left + 0.5, 0.11, -1.6), Vector3(0, 24, 0))
	_dress(MenuDeskObject.slab(1.5, 0.012, 2.0), "prop", "flash", Vector3(right + 0.5, 0.006, 1.4), Vector3(0, -18, 0))
	_dress(MenuDeskObject.slab(1.5, 0.012, 2.0), "prop", "floor_alt", Vector3(left - 1.6, 0.006, -1.5), Vector3(0, 12, 0))
	# Coaster of light under the picked object.
	glow = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring = MeshInstance3D.new()
	var disc = TorusMesh.new()
	disc.inner_radius = 0.98
	disc.outer_radius = 1.1
	disc.rings = 40
	disc.ring_segments = 4
	ring.mesh = disc
	ring.scale = Vector3(1, 0.05, 1)
	ring.material_override = glow
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	var nth = {}
	for i in packs.size():
		var pack: DimensionPack = packs[i]
		var fallback = MenuDeskObject.default_kind(pack.family, nth.get(pack.family, 0))
		nth[pack.family] = nth.get(pack.family, 0) + 1
		var made = MenuDeskObject.make(pack, fallback, forced[i] if i < forced.size() else "")
		made.position = slot(i)
		add_child(made)
		objects.append(made)
	select(selected)

func _dress(mesh: Mesh, role: String, key: String, at: Vector3, turn: Vector3 = Vector3.ZERO) -> void:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.rotation_degrees = turn
	add_child(part)
	dressed.append([part, role, key])

func select(index: int) -> void:
	selected = clampi(index, 0, packs.size() - 1)
	mood = packs[selected]
	for entry in dressed:
		entry[0].material_override = mood.material(entry[1], entry[2])

## view: menu size in canvas units; open: the part of it not covered by UI.
func frame(view_size: Vector2, open: Rect2) -> void:
	view = view_size
	open_area = open

func _aim() -> Transform3D:
	var tan_half = tan(deg_to_rad(FOV * 0.5))
	# Pull back on narrow screens until three objects fit in the open area.
	var need = SPACING * 2.0 + 3.4
	var distance = clampf(need * view.y / (maxf(open_area.size.x, 200.0) * 2.0 * tan_half), NEAR, FAR)
	var per_pixel = 2.0 * distance * tan_half / view.y
	# The carousel keeps the selected object centred, so the camera stays put.
	var target = Vector3(0.0, 0.5, 0.0)
	var pitch = deg_to_rad(PITCH)
	var look = Basis(Vector3.RIGHT, -pitch)
	var off = open_area.get_center() - view * 0.5
	var origin = target + Vector3(0, sin(pitch), cos(pitch)) * distance - look.x * off.x * per_pixel + look.y * off.y * per_pixel
	return Transform3D(look, origin)

func _process(delta: float) -> void:
	clock += delta
	var goal = _aim()
	var blend = 1.0 if not settled else 1.0 - exp(-delta * 7.0)
	camera.transform = Transform3D(goal.basis, camera.position.lerp(goal.origin, blend))
	var env: Dictionary = mood.environment
	sky.background_color = sky.background_color.lerp(mood.color("bg"), blend)
	sky.ambient_light_color = sky.ambient_light_color.lerp(Color.html(str(env.ambient)), blend)
	sky.ambient_light_energy = lerpf(sky.ambient_light_energy, float(env.ambient_energy), blend)
	sun.light_color = sun.light_color.lerp(Color.html(str(env.light)), blend)
	sun.light_energy = lerpf(sun.light_energy, float(env.light_energy), blend)
	glow.albedo_color = glow.albedo_color.lerp(mood.color("ui_accent"), blend)
	ring.position = ring.position.lerp(Vector3(0, 0.04, 0.1), blend)
	var pulse = 1.0 + sin(clock * 2.4) * 0.03
	ring.scale = Vector3(pulse, 0.05, pulse)
	# Carousel: each object slides to its circular offset from the selected one,
	# teleporting only when it wraps around the far side (off-screen).
	for i in objects.size():
		var target_x = _slot_x(i)
		var current_x = objects[i].position.x
		if not settled or absf(current_x - target_x) > SPACING * 1.6:
			objects[i].position.x = target_x
		else:
			objects[i].position.x = lerpf(current_x, target_x, 1.0 - exp(-delta * 8.0))
		objects[i].pose(delta if settled else 10.0, i == selected, i == hovered, 0.16 if all_worlds else 0.0, clock)
	settled = true

# Signed shortest number of steps from the selected object to object i, as an x.
func _slot_x(i: int) -> float:
	var n = objects.size()
	var d = (i - selected) % n
	if d < 0:
		d += n
	if float(d) > n * 0.5:
		d -= n
	return d * SPACING

## Where an object sits on screen, in menu (canvas) coordinates.
func screen_point(index: int, height: float = 0.4) -> Vector2:
	return _to_canvas(objects[index].global_position + objects[index].body.position + Vector3(0, height, 0))

func _to_canvas(point: Vector3) -> Vector2:
	var port = camera.get_viewport().get_visible_rect().size
	return camera.unproject_position(point) * (view / port)

## Spot on the desk just in front of an object, for its name tag.
func tag_point(index: int) -> Vector2:
	return _to_canvas(slot(index) + Vector3(0, 0, 1.25))

## Index of the object under a menu-space position, or -1.
func pick(at: Vector2) -> int:
	var best = -1
	var best_gap = 1e9
	for i in objects.size():
		var centre = screen_point(i)
		var reach = _to_canvas(objects[i].global_position + objects[i].body.position + Vector3(0, 0.4, 0) + camera.global_basis.x * MenuDeskObject.REACH).distance_to(centre)
		var gap = at.distance_to(centre) / maxf(reach * 1.15, 44.0)
		if gap < 1.0 and gap < best_gap:
			best = i
			best_gap = gap
	return best
