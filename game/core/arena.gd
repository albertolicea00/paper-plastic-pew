class_name Arena
extends Node3D
## Builds an arena from core/data/arenas.json. Collision and layout are shared
## by every dimension; only the styled materials change on a shift.

const WALL_HEIGHT = 2.6
# Endless map: props are streamed in cells around the player, no boundary walls.
const CELL = 14.0
const CELL_RADIUS = 3
const CLEAR_RADIUS = 11.0
var size = Vector2(40, 28)
var spawns: Array[Vector3] = []
var player_start = Vector3.ZERO
var title = ""
var blocks: Array[Dictionary] = []
var borders: Array[Dictionary] = []
var scenery: Node3D
var endless = false
var ground: Node3D
var chunks: Dictionary = {}
# A fresh world every match, so the endless map is never the same layout twice.
var world_seed = 0

func build(spec: Dictionary) -> void:
	title = spec.get("name", "Arena")
	size = Vector2(spec.size[0], spec.size[1])
	player_start = Vector3(spec.player[0], 0, spec.player[1])
	if spec.get("endless", false):
		_build_endless()
		return
	for point in spec.spawns:
		spawns.append(Vector3(point[0], 0, point[1]))
	var ground = PlaneMesh.new()
	ground.size = size
	_mesh(ground, Vector3.ZERO, "floor", "floor")
	# Checker tiles break up the floor so movement reads at a glance.
	var tile = PlaneMesh.new()
	tile.size = Vector2(4, 4)
	for x in int(size.x / 4):
		for z in int(size.y / 4):
			if (x + z) % 2 == 0:
				_mesh(tile, Vector3(-size.x * 0.5 + 2 + x * 4, 0.01, -size.y * 0.5 + 2 + z * 4), "floor", "floor_alt")
	for side in [-1, 1]:
		# The wall nearest the camera stays low so it never hides the player.
		_border(Vector3(0, 0, side * (size.y * 0.5 + 0.5)), Vector3(size.x + 2, WALL_HEIGHT if side < 0 else 1.2, 1))
		_border(Vector3(side * (size.x * 0.5 + 0.5), 0, 0), Vector3(1, WALL_HEIGHT, size.y))
	for block in spec.get("blocks", []):
		var role: String = block.get("role", "wall")
		_block(Vector3(block.at[0], 0, block.at[1]), Vector3(block.size[0], block.size[1], block.size[2]), role, block.get("color", role), block.get("shape", "box"), true)
	scenery = Node3D.new()
	add_child(scenery)
	add_to_group(Dimensions.REBUILT)
	rebuild()

# An endless page: a floor plane that follows the player, props streamed in
# cells, no boundary. The dimension's own floor/props/scenery still apply.
func _build_endless() -> void:
	endless = true
	title = "Endless " + Dimensions.hub.active.family
	player_start = Vector3.ZERO
	world_seed = randi()
	ground = Node3D.new()
	add_child(ground)
	var span = CELL * (CELL_RADIUS * 2 + 3)
	var plane = PlaneMesh.new()
	plane.size = Vector2(span, span)
	var floor_node = MeshInstance3D.new()
	floor_node.mesh = plane
	ground.add_child(floor_node)
	Dimensions.hub.style(floor_node, "floor", "floor")
	scenery = Node3D.new()
	add_child(scenery)
	add_to_group(Dimensions.REBUILT)
	stream(Vector3.ZERO)

# Keep a ring of prop cells around `center` (the player), dropping far ones.
func stream(center: Vector3) -> void:
	if not endless:
		return
	ground.position = Vector3(snappedf(center.x, CELL), 0, snappedf(center.z, CELL))
	var here = Vector2i(floori(center.x / CELL), floori(center.z / CELL))
	for dx in range(-CELL_RADIUS, CELL_RADIUS + 1):
		for dz in range(-CELL_RADIUS, CELL_RADIUS + 1):
			var cell = here + Vector2i(dx, dz)
			if not chunks.has(cell):
				_make_chunk(cell)
	for cell in chunks.keys():
		if absi(cell.x - here.x) > CELL_RADIUS + 1 or absi(cell.y - here.y) > CELL_RADIUS + 1:
			_drop_chunk(cell)

# Props and a 7-unit checker for one cell. Seeded by cell AND the match's
# world_seed, so the same spot differs every match. 7 divides CELL, so the
# checker stays aligned as the follow-floor jumps in CELL steps.
func _make_chunk(cell: Vector2i) -> void:
	var chunk = {"props": [], "tiles": []}
	chunks[cell] = chunk
	# Checker tiles (floor_alt), two sub-tiles of the cell on average.
	for sx in 2:
		for sz in 2:
			if (cell.x * 2 + sx + cell.y * 2 + sz) % 2 == 0:
				var tile = PlaneMesh.new()
				tile.size = Vector2(CELL * 0.5, CELL * 0.5)
				var at = Vector3((cell.x + 0.25 + sx * 0.5) * CELL, 0.02, (cell.y + 0.25 + sz * 0.5) * CELL)
				chunk.tiles.append(_mesh(tile, at, "floor", "floor_alt"))
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(cell) ^ world_seed
	for i in rng.randi_range(0, 2):
		var at = Vector3((cell.x + rng.randf()) * CELL, 0, (cell.y + rng.randf()) * CELL)
		if at.length() < CLEAR_RADIUS:
			continue
		var wall = rng.randf() < 0.4
		var shape = "cylinder" if rng.randf() < 0.4 else "box"
		var extent: Vector3
		if wall:
			extent = Vector3(rng.randf_range(2, 5), rng.randf_range(1.6, 2.6), rng.randf_range(2, 5))
		else:
			extent = Vector3(rng.randf_range(1.2, 2.2), rng.randf_range(1.0, 1.6), rng.randf_range(1.2, 2.2))
		if shape == "cylinder":
			extent.z = extent.x
		chunk.props.append(_block(at, extent, "wall" if wall else "prop", "wall" if wall else "prop", shape, true))

func _drop_chunk(cell: Vector2i) -> void:
	for prop in chunks[cell].props:
		blocks.erase(prop.entry)
		prop.holder.queue_free()
		prop.body.queue_free()
	for tile in chunks[cell].tiles:
		tile.queue_free()
	chunks.erase(cell)

## A spawn point on a ring around the player, for endless waves. When the
## player is fleeing (`heading` set), most spawns land ahead of them and a bit
## closer, so running away just runs you into more enemies instead of escaping.
func ring_spawn(from: Vector3, heading: Vector3 = Vector3.ZERO) -> Vector3:
	var angle = randf() * TAU
	var dist = randf_range(17.0, 24.0)
	if heading.length() > 0.5 and randf() < 0.65:
		angle = atan2(heading.x, heading.z) + randf_range(-1.1, 1.1)
		dist = randf_range(14.0, 20.0)
	return from + Vector3(sin(angle), 0, cos(angle)) * dist

## Dress the shared layout in the active dimension's shapes.
func rebuild() -> void:
	var builder = Dimensions.hub.active.builder
	for block in blocks:
		for child in block.holder.get_children():
			child.free()
		builder.block(block.holder, block.extent, block.shape, block.role, block.color)
	for border in borders:
		for child in border.holder.get_children():
			child.free()
		builder.border(border.holder, border.extent)
	for child in scenery.get_children():
		child.free()
	builder.decorate(scenery, self)

# A boundary wall: collision box plus a holder the builder dresses.
func _border(at: Vector3, extent: Vector3) -> void:
	var body = StaticBody3D.new()
	body.position = at + Vector3(0, extent.y * 0.5, 0)
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = extent
	collider.shape = shape
	body.add_child(collider)
	var holder = Node3D.new()
	holder.position = at
	add_child(holder)
	borders.append({"holder": holder, "extent": extent})

func _mesh(mesh: Mesh, at: Vector3, role: String, color_key: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	add_child(node)
	Dimensions.hub.style(node, role, color_key)
	return node

func _block(at: Vector3, extent: Vector3, role: String, color_key: String, shape: String, dressed: bool = false) -> Dictionary:
	var body = StaticBody3D.new()
	body.position = at + Vector3(0, extent.y * 0.5, 0)
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collider = CollisionShape3D.new()
	if shape == "cylinder":
		var round_shape = CylinderShape3D.new()
		round_shape.radius = extent.x * 0.5
		round_shape.height = extent.y
		collider.shape = round_shape
	else:
		var box_shape = BoxShape3D.new()
		box_shape.size = extent
		collider.shape = box_shape
	body.add_child(collider)
	if dressed:
		# Layout blocks get their look from the dimension builder.
		var holder = Node3D.new()
		holder.position = at
		add_child(holder)
		var entry = {"holder": holder, "extent": extent, "shape": shape, "role": role, "color": color_key}
		blocks.append(entry)
		Dimensions.hub.active.builder.block(holder, extent, shape, role, color_key)
		return {"body": body, "holder": holder, "entry": entry}
	var box_mesh = BoxMesh.new()
	box_mesh.size = extent
	_mesh(box_mesh, body.position, role, color_key)
	return {}

func clamp_inside(point: Vector3, margin: float = 1.0) -> Vector3:
	if endless:
		return Vector3(point.x, 0, point.z)
	return Vector3(clampf(point.x, -size.x * 0.5 + margin, size.x * 0.5 - margin), 0, clampf(point.z, -size.y * 0.5 + margin, size.y * 0.5 - margin))
