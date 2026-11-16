class_name Arena
extends Node3D
## Builds an arena from core/data/arenas.json. Collision and layout are shared
## by every dimension; only the styled materials change on a shift.

const WALL_HEIGHT = 2.6
var size = Vector2(40, 28)
var spawns: Array[Vector3] = []
var player_start = Vector3.ZERO
var title = ""

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
		_block(Vector3(0, 0, side * (size.y * 0.5 + 0.5)), Vector3(size.x + 2, WALL_HEIGHT, 1), "wall", "wall", "box")
		_block(Vector3(side * (size.x * 0.5 + 0.5), 0, 0), Vector3(1, WALL_HEIGHT, size.y), "wall", "wall", "box")
	for block in spec.get("blocks", []):
		var role: String = block.get("role", "wall")
		_block(Vector3(block.at[0], 0, block.at[1]), Vector3(block.size[0], block.size[1], block.size[2]), role, block.get("color", role), block.get("shape", "box"))

func _mesh(mesh: Mesh, at: Vector3, role: String, color_key: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	add_child(node)
	Dimensions.hub.style(node, role, color_key)
	return node

func _block(at: Vector3, extent: Vector3, role: String, color_key: String, shape: String) -> void:
	var body = StaticBody3D.new()
	body.position = at + Vector3(0, extent.y * 0.5, 0)
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var collider = CollisionShape3D.new()
	var mesh: Mesh
	if shape == "cylinder":
		var round_mesh = CylinderMesh.new()
		round_mesh.top_radius = extent.x * 0.5
		round_mesh.bottom_radius = extent.x * 0.5
		round_mesh.height = extent.y
		mesh = round_mesh
		var round_shape = CylinderShape3D.new()
		round_shape.radius = extent.x * 0.5
		round_shape.height = extent.y
		collider.shape = round_shape
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = extent
		mesh = box_mesh
		var box_shape = BoxShape3D.new()
		box_shape.size = extent
		collider.shape = box_shape
	body.add_child(collider)
	var node = MeshInstance3D.new()
	node.mesh = mesh
	body.add_child(node)
	Dimensions.hub.style(node, role, color_key)

func clamp_inside(point: Vector3, margin: float = 1.0) -> Vector3:
	return Vector3(clampf(point.x, -size.x * 0.5 + margin, size.x * 0.5 - margin), 0, clampf(point.z, -size.y * 0.5 + margin, size.y * 0.5 - margin))
