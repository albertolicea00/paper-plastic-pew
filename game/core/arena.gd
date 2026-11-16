class_name Arena
extends Node3D
## Builds an arena from core/data/arenas.json. Collision and layout are shared
## by every dimension; only the styled materials change on a shift.

const WALL_HEIGHT = 2.6
var size = Vector2(40, 28)
var spawns: Array[Vector3] = []
var player_start = Vector3.ZERO
var title = ""
var blocks: Array[Dictionary] = []
var scenery: Node3D

func build(spec: Dictionary) -> void:
	title = spec.get("name", "Arena")
	size = Vector2(spec.size[0], spec.size[1])
	player_start = Vector3(spec.player[0], 0, spec.player[1])
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
		_block(Vector3(0, 0, side * (size.y * 0.5 + 0.5)), Vector3(size.x + 2, WALL_HEIGHT if side < 0 else 1.2, 1), "wall", "wall", "box")
		_block(Vector3(side * (size.x * 0.5 + 0.5), 0, 0), Vector3(1, WALL_HEIGHT, size.y), "wall", "wall", "box")
	for block in spec.get("blocks", []):
		var role: String = block.get("role", "wall")
		_block(Vector3(block.at[0], 0, block.at[1]), Vector3(block.size[0], block.size[1], block.size[2]), role, block.get("color", role), block.get("shape", "box"), true)
	scenery = Node3D.new()
	add_child(scenery)
	add_to_group(Dimensions.REBUILT)
	rebuild()

## Dress the shared layout in the active dimension's shapes.
func rebuild() -> void:
	var builder = Dimensions.hub.active.builder
	for block in blocks:
		for child in block.holder.get_children():
			child.free()
		builder.block(block.holder, block.extent, block.shape, block.role, block.color)
	for child in scenery.get_children():
		child.free()
	builder.decorate(scenery, self)

func _mesh(mesh: Mesh, at: Vector3, role: String, color_key: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	add_child(node)
	Dimensions.hub.style(node, role, color_key)
	return node

func _block(at: Vector3, extent: Vector3, role: String, color_key: String, shape: String, dressed: bool = false) -> void:
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
		blocks.append({"holder": holder, "extent": extent, "shape": shape, "role": role, "color": color_key})
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = extent
		_mesh(box_mesh, body.position, role, color_key)

func clamp_inside(point: Vector3, margin: float = 1.0) -> Vector3:
	return Vector3(clampf(point.x, -size.x * 0.5 + margin, size.x * 0.5 - margin), 0, clampf(point.z, -size.y * 0.5 + margin, size.y * 0.5 - margin))
