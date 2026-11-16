class_name MenuDeskObject
extends Node3D
## One tactile object on the menu desk, standing for a dimension pack and
## rendered with that pack's own materials. Built from primitive meshes.
##
## Optional pack.json block (every key optional):
##   "desk": {"object": "sketchbook"|"comic"|"book"|"sheets"|"box"|"figure"|"lump"|"blocks",
##            "cover": "@wall", "pages": "@floor", "art": "@prop", "accent": "@ui_accent", "scale": 1.0}
## Colours are palette keys ("@key" or "key"). Without the block the object
## is chosen from pack.family, see default_kind().

const PAPER = ["sketchbook", "comic", "book", "sheets", "box"]
const PLASTIC = ["figure", "blocks", "lump"]
const OTHER = ["box", "sheets", "blocks"]
const REACH = 0.95

var pack: DimensionPack
var kind = ""
var spec: Dictionary = {}
var body: Node3D
var hinges: Array = []
var tilt = 36.0
var spin = 0.0
var rest_yaw = 0.0
var weight = 0.0
var hover = 0.0

## Packs of one family get different objects in pack order, so a new pack
## without a "desk" block still looks distinct from its siblings.
static func default_kind(family: String, nth: int) -> String:
	var pool = PAPER if family == "Paper" else PLASTIC if family == "Plastic" else OTHER
	return pool[nth % pool.size()]

## forced overrides the pack's own choice (developer argument --menu-objects).
static func make(for_pack: DimensionPack, fallback: String, forced: String = "") -> MenuDeskObject:
	var made = MenuDeskObject.new()
	made.pack = for_pack
	var block = for_pack.data.get("desk", {})
	made.spec = block if block is Dictionary and forced == "" else {}
	made.rest_yaw = float(hash(for_pack.id) % 19 - 9)
	made.body = Node3D.new()
	made.add_child(made.body)
	for wanted in [forced, str(made.spec.get("object", "")), fallback, "box"]:
		if made._build(wanted):
			made.kind = wanted
			break
	return made

func _build(wanted: String) -> bool:
	match wanted:
		"sketchbook": _book(1.7, 1.25, 0.2, "spiral")
		"comic": _book(1.2, 1.7, 0.05, "staple")
		"book": _book(1.25, 1.65, 0.3, "spine")
		"sheets": _sheets()
		"box": _box()
		"figure": _figure()
		"lump": _lump()
		"blocks": _blocks()
		_: return false
	return true

func _key(slot: String, fallback: String) -> String:
	var key = str(spec.get(slot, fallback)).trim_prefix("@")
	return key if DimensionPack.PALETTE.has(key) else fallback

func _part(mesh: Mesh, role: String, key: String, at: Vector3, turn: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var part = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = pack.material(role, key)
	part.position = at
	part.rotation_degrees = turn
	(parent if parent != null else body).add_child(part)
	return part

static func slab(x: float, y: float, z: float) -> BoxMesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(x, y, z)
	return mesh

static func ball(radius: float, squash: float = 1.0) -> SphereMesh:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 20
	mesh.rings = 10
	return mesh

static func tube(radius: float, height: float, top: float = -1.0) -> CylinderMesh:
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0.0 else top
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	return mesh

func _hinge(at: Vector3, axis: Vector3, degrees: float, rest: float = 0.0) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = at
	body.add_child(pivot)
	hinges.append([pivot, axis, rest, degrees])
	return pivot

# Closed book lying on the desk, spine on the left; the cover lifts when picked.
func _book(width: float, depth: float, thick: float, binding: String) -> void:
	var cover = _key("cover", "wall" if binding == "spiral" else "prop")
	var pages = _key("pages", "floor")
	var art = _key("art", "prop" if binding == "spiral" else "player")
	var accent = _key("accent", "ui_accent")
	if binding == "staple":
		# A second issue underneath sells "a pile of comics".
		var under = _part(slab(width, 0.04, depth), "prop", _key("art", "bot"), Vector3(0.1, 0.02, -0.06), Vector3(0, -14, 0))
		_part(slab(width * 0.8, 0.012, depth * 0.2), "prop", pages, Vector3(0, 0.024, -depth * 0.3), Vector3.ZERO, under)
	var base = 0.05 if binding == "staple" else 0.0
	_part(slab(width, 0.03, depth), "prop", cover, Vector3(0, base + 0.015, 0))
	_part(slab(width - 0.07, thick, depth - 0.07), "prop", pages, Vector3(0.01, base + 0.03 + thick * 0.5, 0))
	var top = base + 0.03 + thick
	# Ink on the first page, seen when the cover lifts.
	for row in 3:
		_part(slab(width * (0.62 - row * 0.12), 0.006, 0.05), "prop", "ink", Vector3(0.06 - row * width * 0.06, top + 0.002, -depth * 0.22 + row * depth * 0.2))
	var lid = _hinge(Vector3(-width * 0.5, top, 0), Vector3(0, 0, 1), 26.0)
	_part(slab(width, 0.03, depth), "prop", cover, Vector3(width * 0.5, 0.016, 0), Vector3.ZERO, lid)
	if binding == "staple":
		# Comic cover: masthead and a three panel page.
		_part(slab(width * 0.84, 0.012, depth * 0.16), "prop", accent, Vector3(width * 0.5, 0.036, -depth * 0.37), Vector3.ZERO, lid)
		_part(slab(width * 0.84, 0.012, depth * 0.34), "prop", art, Vector3(width * 0.5, 0.036, -depth * 0.09), Vector3.ZERO, lid)
		_part(slab(width * 0.4, 0.012, depth * 0.3), "prop", "bot", Vector3(width * 0.28, 0.036, depth * 0.27), Vector3.ZERO, lid)
		_part(slab(width * 0.4, 0.012, depth * 0.3), "prop", "runner", Vector3(width * 0.72, 0.036, depth * 0.27), Vector3.ZERO, lid)
	else:
		_part(slab(width * 0.7, 0.012, depth * 0.48), "prop", art, Vector3(width * 0.53, 0.036, -depth * 0.1), Vector3.ZERO, lid)
		_part(slab(width * 0.7, 0.012, depth * 0.12), "prop", accent, Vector3(width * 0.53, 0.036, depth * 0.32), Vector3.ZERO, lid)
	if binding == "spine":
		_part(slab(0.05, thick + 0.06, depth), "prop", cover, Vector3(-width * 0.5 - 0.01, (thick + 0.06) * 0.5, 0))
		# Ribbon bookmark.
		_part(slab(0.07, 0.01, 0.5), "prop", accent, Vector3(width * 0.2, 0.012, depth * 0.5 + 0.18))
	elif binding == "spiral":
		var ring = TorusMesh.new()
		ring.inner_radius = thick * 0.5 + 0.015
		ring.outer_radius = thick * 0.5 + 0.055
		ring.rings = 12
		ring.ring_segments = 6
		for i in 7:
			_part(ring, "prop", "weapon", Vector3(-width * 0.5 + 0.02, 0.03 + thick * 0.5, lerpf(-depth * 0.5 + 0.14, depth * 0.5 - 0.14, i / 6.0)), Vector3(90, 0, 0))
		# A pencil kept in the spiral.
		_part(tube(0.035, depth * 0.8), "prop", accent, Vector3(width * 0.5 + 0.12, 0.04, 0.05), Vector3(90, 6, 0))

# Loose sheets with a standing paper cutout.
func _sheets() -> void:
	var pages = _key("pages", "floor")
	for i in 4:
		_part(slab(1.2, 0.012, 1.55), "prop", pages if i % 2 == 0 else "floor_alt", Vector3(0, 0.008 + i * 0.014, 0), Vector3(0, -16 + i * 11, 0))
	var stand = _hinge(Vector3(0, 0.06, 0.1), Vector3(1, 0, 0), -12.0)
	var art = _key("art", "player")
	_part(slab(0.5, 0.62, 0.02), "character", art, Vector3(0, 0.36, 0), Vector3.ZERO, stand)
	_part(tube(0.24, 0.02), "character", art, Vector3(0, 0.86, 0), Vector3(90, 0, 0), stand)
	_part(slab(0.34, 0.1, 0.03), "character", _key("accent", "player_accent"), Vector3(0, 0.88, 0.012), Vector3.ZERO, stand)
	_part(slab(0.6, 0.02, 0.3), "prop", _key("cover", "prop"), Vector3(0, 0.0, 0), Vector3.ZERO, stand)
	tilt = 22.0

# Cardboard box of props; the flaps open when picked.
func _box() -> void:
	var cover = _key("cover", "prop")
	_part(slab(1.3, 0.04, 1.1), "prop", cover, Vector3(0, 0.02, 0))
	for side in [-1.0, 1.0]:
		_part(slab(0.04, 0.7, 1.1), "prop", cover, Vector3(side * 0.63, 0.37, 0))
		_part(slab(1.3, 0.7, 0.04), "prop", cover, Vector3(0, 0.37, side * 0.53))
		var flap = _hinge(Vector3(side * 0.65, 0.72, 0), Vector3(0, 0, 1), side * -200.0, side * -35.0)
		_part(slab(0.62, 0.03, 1.1), "prop", cover, Vector3(-side * 0.31, 0, 0), Vector3.ZERO, flap)
	# What is inside.
	_part(ball(0.3), "character", _key("art", "player"), Vector3(-0.2, 0.55, 0.05))
	_part(slab(0.34, 0.5, 0.34), "prop", _key("accent", "player_accent"), Vector3(0.28, 0.5, -0.12), Vector3(0, 25, 12))
	_part(slab(1.1, 0.01, 0.14), "prop", _key("pages", "floor"), Vector3(0, 0.37, 0.556))
	tilt = 24.0

# The hero as a hand-made figurine on a turntable.
func _figure() -> void:
	var skin = _key("art", "player")
	var accent = _key("accent", "player_accent")
	_part(tube(0.62, 0.09, 0.56), "prop", _key("cover", "prop"), Vector3(0, 0.045, 0))
	for side in [-1.0, 1.0]:
		_part(ball(0.15, 0.7), "character", "weapon", Vector3(side * 0.2, 0.18, 0.04))
		_part(ball(0.13), "character", skin, Vector3(side * 0.47, 0.6 + side * 0.06, 0.1))
	_part(ball(0.37, 1.15), "character", skin, Vector3(0, 0.56, 0))
	_part(ball(0.29), "character", skin, Vector3(0, 1.08, 0))
	_part(ball(0.16, 0.55), "character", accent, Vector3(0, 1.1, 0.2), Vector3(12, 0, 0))
	_part(slab(0.12, 0.14, 0.5), "weapon", "weapon", Vector3(0.47, 0.7, 0.3))
	tilt = 14.0
	spin = 0.5

# Raw material: a worked lump with a sculpting tool stuck in it.
func _lump() -> void:
	_part(tube(0.7, 0.04), "prop", _key("pages", "floor_alt"), Vector3(0, 0.02, 0))
	_part(ball(0.52, 0.72), "prop", _key("cover", "prop"), Vector3(0, 0.36, 0), Vector3(0, 0, 8))
	_part(ball(0.3, 0.8), "prop", _key("art", "player"), Vector3(0.42, 0.24, 0.26))
	_part(ball(0.22, 0.85), "prop", _key("accent", "player_accent"), Vector3(-0.45, 0.19, 0.2))
	_part(tube(0.16, 0.5), "prop", "tank", Vector3(-0.2, 0.14, -0.42), Vector3(0, 30, 90))
	_part(tube(0.035, 0.9), "prop", "weapon", Vector3(0.12, 0.85, -0.05), Vector3(0, 0, -24))
	tilt = 20.0
	spin = 0.35

# Stacked studded bricks.
func _blocks() -> void:
	var tones = [_key("cover", "prop"), _key("art", "player"), _key("accent", "player_accent"), "bot"]
	var bricks = [[Vector3(-0.2, 0.17, 0.0), 0.0, 4], [Vector3(0.3, 0.17, 0.5), 28.0, 2], [Vector3(0.0, 0.51, 0.0), 0.0, 2], [Vector3(-0.42, 0.51, 0.0), 0.0, 1]]
	for i in bricks.size():
		var studs: int = bricks[i][2]
		var brick = _part(slab(studs * 0.34, 0.34, 0.68), "prop", tones[i], bricks[i][0], Vector3(0, bricks[i][1], 0))
		for n in studs * 2:
			_part(tube(0.1, 0.08), "prop", tones[i], Vector3((n / 2 - (studs - 1) * 0.5) * 0.34, 0.2, (n % 2 - 0.5) * 0.34), Vector3.ZERO, brick)
	tilt = 22.0
	spin = 0.35

## weight: 0 resting on the desk, 1 held up to the camera.
func pose(delta: float, picked: bool, hovered: bool, nudge: float, clock: float) -> void:
	weight = lerpf(weight, 1.0 if picked else nudge, 1.0 - exp(-delta * 9.0))
	hover = lerpf(hover, 1.0 if hovered and not picked else 0.0, 1.0 - exp(-delta * 14.0))
	var eased = weight * weight * (3.0 - 2.0 * weight)
	var bob = sin(clock * 1.7 + position.x) * 0.04 * eased
	body.position = Vector3(0, eased * 0.95 + hover * 0.14 + bob, eased * 0.55)
	var yaw = deg_to_rad(rest_yaw) * (1.0 - eased)
	if spin > 0.0:
		yaw += sin(clock * spin) * 0.6 * eased
	# Tilt first, then yaw, so a spinning figure turns on its own axis.
	body.basis = Basis(Vector3.RIGHT, deg_to_rad(tilt) * eased + hover * 0.06) * Basis(Vector3.UP, yaw)
	body.scale = Vector3.ONE * clampf(float(spec.get("scale", 1.0)), 0.5, 1.5) * (1.0 + 0.12 * eased + 0.04 * hover)
	for hinge in hinges:
		hinge[0].basis = Basis(hinge[1], deg_to_rad(lerpf(hinge[2], hinge[3], eased)))
