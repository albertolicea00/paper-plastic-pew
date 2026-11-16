class_name DimensionBuilder
extends RefCounted
## Shapes of a dimension: what characters, props, pickups, bullets and scenery
## are made of. Packs extend this ("builder" in pack.json) and override what
## they want their own; anything left alone uses these plain shapes.
## Everything built here is visual only. Collision and hitboxes are shared, so
## stay inside the footprint given to each function.
## A shift rebuilds every shape on the same frame: cache meshes with shared().

# No reference back to the pack (it would be a cycle); use Dimensions.hub.active.
var _meshes: Dictionary = {}

## Build a character into `rig` with rig.add_part(). Required part names:
## body, head, hand_l, hand_r, foot_l, foot_r, and weapon when look.weapon is
## not false (the weapon points along -Z from the right hand). Any extra parts
## are welcome. `kind` is player, grunt, runner, tank, boss or bot; `look` has
## color, accent, build and scale. Unscaled, a character fits a capsule of
## radius 0.45 and height 1.8; the rig applies look.scale itself.
func character(rig: CharacterRig, look: Dictionary, _kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "ink")
	var shape: String = look.get("build", "biped")
	var girth: float = {"biped": 0.32, "runner": 0.25, "tank": 0.5, "boss": 0.46}.get(shape, 0.32)
	rig.add_part("body", capsule(girth, 0.85 if shape == "runner" else 0.95), Vector3(0, 0.72, 0), tone)
	var skull = 0.34 if shape == "runner" else 0.24 if shape == "tank" else 0.29
	rig.add_part("head", sphere(skull), Vector3(0, 1.22 + skull, 0), tone)
	rig.add_part("visor", box(Vector3(skull * 1.3, skull * 0.42, skull * 0.5)), Vector3(0, 1.24 + skull, -skull * 0.8), accent)
	for side in [-1, 1]:
		var tag = "l" if side < 0 else "r"
		var reach = Vector3(side * (girth + 0.14), 0.82, -0.22)
		if shape == "runner":
			rig.add_part("hand_" + tag, cone(0.1, 0.5), reach, accent, "character", Vector3(-PI * 0.5, 0, 0))
		else:
			rig.add_part("hand_" + tag, sphere(0.18 if shape == "tank" else 0.12), reach, tone)
		rig.add_part("foot_" + tag, box(Vector3(0.2, 0.14, 0.34)), Vector3(side * girth * 0.6, 0.07, -0.03), "ink")
		if shape == "boss":
			rig.add_part("horn_" + tag, cone(0.09, 0.4), Vector3(side * 0.2, 1.72, 0), accent, "character", Vector3(0, 0, -side * 0.5))
	if look.get("weapon", true):
		var heavy = 1.5 if shape in ["tank", "boss"] else 1.0
		rig.add_part("weapon", box(Vector3(0.14, 0.16, 0.7) * heavy), Vector3(girth + 0.14, 0.86, -0.5), "weapon", "weapon")

## Build the look of one arena block under `holder`, whose origin is the
## centre of the block's floor footprint. `extent` is the collision size
## (width, height, depth); `shape` is "box" or "cylinder" (diameter extent.x).
## `role` is "wall" or "prop". Stay inside the footprint; height is free.
func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	var mesh = cylinder(extent.x * 0.5, extent.y) if shape == "cylinder" else box(extent)
	add(holder, mesh, Vector3(0, extent.y * 0.5, 0), role, color_key)

## Build a pickup under `holder` (it spins and bobs by itself), about 0.6 wide.
## `what` is "health" or a weapon id (scatter, rapid, launcher).
func pickup(holder: Node3D, what: String) -> void:
	add(holder, box(Vector3.ONE * 0.55), Vector3.ZERO, "pickup", "pickup_health" if what == "health" else "pickup_ammo")

## Mesh for bullets: fits a unit cube, travels along -Z. It is stretched 2.4x
## along Z and scaled to about 0.26 by the core.
func bullet_mesh() -> Mesh:
	return shared("bullet", func():
		var ball = SphereMesh.new()
		ball.radius = 0.5
		ball.height = 1.0
		ball.radial_segments = 10
		ball.rings = 5
		return ball)

## Scenery without collision, under `holder` at the arena centre. Keep it
## outside the playfield (beyond arena.size / 2 + 1.5) or flat on the floor.
func decorate(_holder: Node3D, _arena: Arena) -> void:
	pass

## Add a styled mesh under a parent; the standard way to build anything here.
func add(parent: Node3D, mesh: Mesh, at: Vector3, role: String, color_key: String, euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.rotation = euler
	parent.add_child(node)
	Dimensions.hub.style(node, role, color_key)
	return node

## Cached mesh: `make` runs once per key for the life of the pack.
func shared(key: String, make: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = make.call()
	return _meshes[key]

func box(extent: Vector3) -> Mesh:
	return shared("box%s" % extent, func():
		var mesh = BoxMesh.new()
		mesh.size = extent
		return mesh)

func sphere(radius: float, squash: float = 1.0) -> Mesh:
	return shared("sphere%f/%f" % [radius, squash], func():
		var mesh = SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0 * squash
		mesh.radial_segments = 20
		mesh.rings = 10
		return mesh)

func capsule(radius: float, height: float) -> Mesh:
	return shared("capsule%f/%f" % [radius, height], func():
		var mesh = CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = maxf(height, radius * 2.0)
		mesh.radial_segments = 20
		mesh.rings = 6
		return mesh)

## Cylinder, or a cone / tapered post when `top` differs from `radius`.
func cylinder(radius: float, height: float, top: float = -1.0, sides: int = 20) -> Mesh:
	return shared("cylinder%f/%f/%f/%d" % [radius, height, top, sides], func():
		var mesh = CylinderMesh.new()
		mesh.bottom_radius = radius
		mesh.top_radius = radius if top < 0.0 else top
		mesh.height = height
		mesh.radial_segments = sides
		return mesh)

func cone(radius: float, height: float) -> Mesh:
	return cylinder(radius, height, 0.0)
