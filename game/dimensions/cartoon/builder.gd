extends DimensionBuilder
## Cartoon / Comic shapes: rubber-hose characters (pear bodies, big heads,
## white gloves, bulbous shoes, noodle limbs) and a toon-town world of
## mushrooms, crates, barrels and lollipop trees.
## Most shapes are several primitives fused into one mesh per colour, so a
## character stays around 15 draws. Fused meshes carry their outline push in
## the vertex colour (see outline.gdshader): the stock corner heuristic only
## works for shapes centred on the mesh origin.
## Parts tagged with meta "on" ride another part, and limbs tagged with "to"
## are re-spanned every frame by the pack's animator.

const X90 = Vector3(PI * 0.5, 0, 0)
const SIDES = [-1.0, 1.0]

# ---------------------------------------------------------------- meshes ---

func _x(at: Vector3, size: Vector3 = Vector3.ONE, euler: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(euler) * Basis.from_scale(size), at)

func _v(size) -> Vector3:
	return size if size is Vector3 else Vector3.ONE * float(size)

# Pieces for fuse(): [mesh, transform, outline weight]. `size` is the full
# extent (a number makes a round ball).
func ball(at: Vector3, size, euler: Vector3 = Vector3.ZERO, line: float = 1.0) -> Array:
	return [sphere(0.5), _x(at, _v(size), euler), line]

func slab(at: Vector3, size: Vector3, euler: Vector3 = Vector3.ZERO, line: float = 1.0) -> Array:
	return [box(Vector3.ONE), _x(at, size, euler), line]

## Cylinder along Y before `euler`; `top` < 0 keeps it straight, 0 makes a cone.
func tube(at: Vector3, radius: float, height: float, euler: Vector3 = Vector3.ZERO, top: float = -1.0, line: float = 1.0, size: Vector3 = Vector3.ONE) -> Array:
	return [cylinder(radius, height, top, 14), _x(at, size, euler), line]

func pill(at: Vector3, radius: float, height: float, euler: Vector3 = Vector3.ZERO, line: float = 1.0) -> Array:
	return [capsule(radius, height), _x(at, Vector3.ONE, euler), line]

## Torus around Y before `euler`.
func ring(at: Vector3, radius: float, thick: float, euler: Vector3 = Vector3.ZERO, line: float = 1.0) -> Array:
	var mesh = shared("torus%f/%f" % [radius, thick], func():
		var made = TorusMesh.new()
		made.inner_radius = radius - thick
		made.outer_radius = radius + thick
		made.rings = 18
		made.ring_segments = 8
		return made)
	return [mesh, _x(at, Vector3.ONE, euler), line]

## One mesh out of many pieces. `pieces` returns an array of the entries above
## and runs once per key.
func fuse(key: String, pieces: Callable) -> Mesh:
	return shared("fuse:" + key, func():
		var points = PackedVector3Array()
		var normals = PackedVector3Array()
		var pushes = PackedColorArray()
		var indices = PackedInt32Array()
		for piece in pieces.call():
			var source = piece[0]
			var xform: Transform3D = piece[1]
			var line: float = piece[2]
			var arrays: Array = source.surface_get_arrays(0)
			var from: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var facing: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var slant = xform.basis.inverse().transposed()
			var spin = xform.basis.orthonormalized()
			var first = points.size()
			for i in from.size():
				var normal: Vector3 = (slant * facing[i]).normalized()
				# Outline push: boxes and cylinder ends move diagonally so the
				# hull closes at the edges, everything else along the normal.
				var push = normal
				if source is BoxMesh:
					push = spin * from[i].sign()
				elif source is CylinderMesh and absf(from[i].y) > source.height * 0.499:
					var end: float = source.top_radius if from[i].y > 0.0 else source.bottom_radius
					if end > 0.001:
						push = spin * (Vector3(from[i].x, 0, from[i].z) / end + Vector3(0, signf(from[i].y), 0))
				push = push * line * 0.25 + Vector3.ONE * 0.5
				points.append(xform * from[i])
				normals.append(normal)
				# Alpha 0 tells the outline shader the colour is a push vector.
				pushes.append(Color(push.x, push.y, push.z, 0.0))
			var flipped = xform.basis.determinant() < 0.0
			for i in range(0, order.size(), 3):
				indices.append(first + order[i])
				indices.append(first + order[i + (2 if flipped else 1)])
				indices.append(first + order[i + (1 if flipped else 2)])
		var data = []
		data.resize(Mesh.ARRAY_MAX)
		data[Mesh.ARRAY_VERTEX] = points
		data[Mesh.ARRAY_NORMAL] = normals
		data[Mesh.ARRAY_COLOR] = pushes
		data[Mesh.ARRAY_INDEX] = indices
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		return mesh)

## Puffy star in the XZ plane, one tip towards -Z, 1 unit across.
## `depth` squeezes it along Z, `bulge` is the half thickness at the centre.
func star(tips: int, inner: float, bulge: float, depth: float = 1.0) -> Mesh:
	return shared("star%d/%f/%f/%f" % [tips, inner, bulge, depth], func():
		var points = PackedVector3Array([Vector3(0, bulge, 0), Vector3(0, -bulge, 0)])
		var count = tips * 2
		for i in count:
			var angle = TAU * i / count
			var reach = 0.5 if i % 2 == 0 else inner
			points.append(Vector3(sin(angle) * reach, 0, -cos(angle) * reach * depth))
		var normals = PackedVector3Array()
		normals.resize(points.size())
		var indices = PackedInt32Array()
		for i in count:
			for hub in 2:
				var a = hub
				var b = 2 + i
				var c = 2 + (i + 1) % count
				# Godot's front faces are clockwise: flip to face outwards.
				var normal = (points[c] - points[a]).cross(points[b] - points[a])
				if normal.dot(points[a] + points[b] + points[c]) < 0.0:
					var swap = b
					b = c
					c = swap
					normal = -normal
				for index in [a, b, c]:
					indices.append(index)
					normals[index] += normal.normalized()
		for i in normals.size():
			normals[i] = normals[i].normalized()
		var data = []
		data.resize(Mesh.ARRAY_MAX)
		data[Mesh.ARRAY_VERTEX] = points
		data[Mesh.ARRAY_NORMAL] = normals
		data[Mesh.ARRAY_INDEX] = indices
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		return mesh)

## Stretch a unit-high limb between two points; the animator calls this too.
static func span(node: Node3D, from: Vector3, to: Vector3) -> void:
	var along = to - from
	var length = maxf(along.length(), 0.01)
	var up = along / length
	var side = up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	node.transform = Transform3D(Basis(side, up * length, side.cross(up)), (from + to) * 0.5)

# ------------------------------------------------------------ characters ---

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "ink")
	var armed: bool = look.get("weapon", true)
	match kind:
		"player": _hero(rig, tone, accent, armed)
		"bot": _robot(rig, tone, accent, armed)
		"runner": _bird(rig, tone, accent, armed)
		"tank": _bulldog(rig, tone, accent, armed)
		"boss": _villain(rig, tone, accent, armed)
		_: _goon(rig, tone, accent, armed)

# Fused rig part; `on` names the part it rides (the animator carries it).
func _part(rig: CharacterRig, part: String, key: String, pieces: Callable, at: Vector3, tone: String, on: String = "", euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node = rig.add_part(part, fuse(key, pieces), at, tone, "character", euler)
	if on != "":
		node.set_meta("on", on)
	return node

# Rigid detail glued to a part (faces, buttons, weapon trim).
func _detail(parent: Node3D, key: String, pieces: Callable, tone: String, role: String = "character") -> MeshInstance3D:
	return add(parent, fuse(key, pieces), Vector3.ZERO, role, tone)

# Noodle from a point on `root` to the part `to` (offset by `tip`).
func _limb(rig: CharacterRig, part: String, from: Vector3, to: String, tip: Vector3, thick: float, tone: String = "ink", root: String = "body") -> void:
	var node = rig.add_part(part, cylinder(thick, 1.0, -1.0, 8), from, tone)
	node.set_meta("from", from)
	node.set_meta("to", to)
	node.set_meta("tip", tip)
	node.set_meta("root", root)
	span(node, from, rig.parts[to].position + tip)

# Three-finger toon glove with a rolled cuff, `wide` across.
func _glove(wide: float) -> Mesh:
	return fuse("glove%f" % wide, func(): return [
		ball(Vector3.ZERO, Vector3(wide, wide * 0.92, wide * 1.08)),
		ball(Vector3(0, wide * 0.36, -wide * 0.12), wide * 0.44, Vector3.ZERO, 0.6),
		ring(Vector3(0, 0, wide * 0.46), wide * 0.33, wide * 0.11, X90)])

# Bulbous shoe standing on the part origin.
func _shoe(size: Vector3) -> Mesh:
	return fuse("shoe%s" % size, func(): return [
		ball(Vector3(0, size.y * 0.5, -size.z * 0.16), size),
		ball(Vector3(0, size.y * 0.55, size.z * 0.2), Vector3(size.x * 0.8, size.y * 1.1, size.z * 0.5))])

# Gloves, shoes and the hoses that join them to the body. Positions are for
# the right side and mirrored.
func _limbs(rig: CharacterRig, shoulder: Vector3, hand: Vector3, hip: Vector3, foot: Vector3, glove: float, shoe: Vector3, shoe_key: String, thick: float = 0.03) -> void:
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		var flip = Vector3(side, 1, 1)
		rig.add_part("hand_" + tag, _glove(glove), hand * flip, "flash")
		rig.add_part("foot_" + tag, _shoe(shoe), foot * flip, shoe_key)
		_limb(rig, "arm_" + tag, shoulder * flip, "hand_" + tag, Vector3(0, 0, glove * 0.4), thick)
		_limb(rig, "leg_" + tag, hip * flip, "foot_" + tag, Vector3(0, shoe.y * 0.9, shoe.z * 0.2), thick)

# Plucky hero: round ears, a cap, shorts with buttons, big shoes.
func _hero(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "hero_body", func(): return [
		ball(Vector3(0, -0.08, 0), Vector3(0.6, 0.56, 0.54)),
		ball(Vector3(0, 0.2, 0), Vector3(0.4, 0.38, 0.38))], Vector3(0, 0.62, 0), tone)
	_detail(body, "hero_shorts", func(): return [
		ball(Vector3(0, -0.15, 0), Vector3(0.64, 0.42, 0.58))], accent)
	_detail(body, "hero_buttons", func(): return [
		ball(Vector3(-0.1, -0.12, -0.28), 0.1, Vector3.ZERO, 0.4),
		ball(Vector3(0.1, -0.12, -0.28), 0.1, Vector3.ZERO, 0.4)], "flash")
	var head = rig.add_part("head", sphere(0.36), Vector3(0, 1.3, 0), tone)
	_detail(head, "hero_face", func(): return [
		ball(Vector3(0, -0.11, -0.19), Vector3(0.5, 0.34, 0.36)),
		ball(Vector3(-0.11, 0.08, -0.26), Vector3(0.18, 0.27, 0.14), Vector3.ZERO, 0.5),
		ball(Vector3(0.11, 0.08, -0.26), Vector3(0.18, 0.27, 0.14), Vector3.ZERO, 0.5)], "flash")
	_detail(head, "hero_ink", func(): return [
		ball(Vector3(-0.1, 0.05, -0.325), Vector3(0.07, 0.14, 0.05), Vector3.ZERO, 0.0),
		ball(Vector3(0.1, 0.05, -0.325), Vector3(0.07, 0.14, 0.05), Vector3.ZERO, 0.0),
		ball(Vector3(0, -0.06, -0.39), Vector3(0.14, 0.1, 0.1), Vector3.ZERO, 0.0)], "ink")
	for side in SIDES:
		_part(rig, "ear_l" if side < 0 else "ear_r", "hero_ear", func(): return [
			ball(Vector3(0, 0.14, 0), Vector3(0.3, 0.3, 0.12))], Vector3(side * 0.28, 1.48, 0.06), tone, "head", Vector3(0, 0, -side * 0.6))
	_part(rig, "hat", "hero_cap", func(): return [
		ball(Vector3(0, 0.02, 0.02), Vector3(0.58, 0.36, 0.6)),
		ball(Vector3(0, -0.03, -0.33), Vector3(0.44, 0.08, 0.36)),
		ball(Vector3(0, 0.2, 0.02), 0.1, Vector3.ZERO, 0.5)], Vector3(0, 1.52, 0), accent, "head")
	# The gun arm is held high so the weapon view shows the glove and the gun.
	_limbs(rig, Vector3(0.2, 0.92, 0), Vector3(0.5, 0.8, -0.22), Vector3(0.13, 0.42, 0), Vector3(0.2, 0, -0.04), 0.3, Vector3(0.26, 0.2, 0.42), accent)
	rig.parts["hand_r"].position = Vector3(0.5, 0.84, -0.42)
	if armed:
		_raygun(rig, Vector3(0.5, 0.95, -0.7))

# Tin-toy robot: dome head with goggles, a bobbing antenna and a wind-up key.
func _robot(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "robot_body", func(): return [
		tube(Vector3(0, -0.02, 0), 0.27, 0.5),
		ball(Vector3(0, 0.23, 0), Vector3(0.54, 0.26, 0.54)),
		ball(Vector3(0, -0.27, 0), Vector3(0.54, 0.2, 0.54))], Vector3(0, 0.62, 0), tone)
	_detail(body, "robot_trim", func(): return [
		ring(Vector3(0, -0.2, 0), 0.275, 0.035),
		ring(Vector3(0, 0.02, -0.265), 0.1, 0.025, X90, 0.5)], accent)
	_detail(body, "robot_dial", func(): return [
		ball(Vector3(0, 0.02, -0.25), Vector3(0.18, 0.18, 0.06), Vector3.ZERO, 0.0)], "flash")
	var head = _part(rig, "head", "robot_head", func(): return [
		ball(Vector3(0, 0.04, 0), Vector3(0.6, 0.5, 0.6)),
		tube(Vector3(0, -0.13, 0), 0.3, 0.2)], Vector3(0, 1.24, 0), tone)
	_detail(head, "robot_goggles", func(): return [
		tube(Vector3(-0.12, 0.03, -0.25), 0.115, 0.14, X90),
		tube(Vector3(0.12, 0.03, -0.25), 0.115, 0.14, X90),
		tube(Vector3(-0.32, -0.02, 0), 0.07, 0.08, Vector3(0, 0, PI * 0.5), -1.0, 0.6),
		tube(Vector3(0.32, -0.02, 0), 0.07, 0.08, Vector3(0, 0, PI * 0.5), -1.0, 0.6)], accent)
	_detail(head, "robot_lens", func(): return [
		ball(Vector3(-0.12, 0.03, -0.31), Vector3(0.17, 0.17, 0.06), Vector3.ZERO, 0.0),
		ball(Vector3(0.12, 0.03, -0.31), Vector3(0.17, 0.17, 0.06), Vector3.ZERO, 0.0)], "flash")
	_detail(head, "robot_ink", func(): return [
		ball(Vector3(-0.11, 0.03, -0.335), Vector3(0.07, 0.09, 0.03), Vector3.ZERO, 0.0),
		ball(Vector3(0.11, 0.03, -0.335), Vector3(0.07, 0.09, 0.03), Vector3.ZERO, 0.0),
		slab(Vector3(0, -0.15, -0.29), Vector3(0.2, 0.05, 0.04), Vector3.ZERO, 0.0)], "ink")
	_part(rig, "antenna", "robot_antenna", func(): return [
		tube(Vector3(0, 0.12, 0), 0.02, 0.24, Vector3.ZERO, -1.0, 0.4),
		ball(Vector3(0, 0.28, 0), 0.14)], Vector3(0, 1.5, 0), accent, "head")
	_part(rig, "key", "robot_key", func(): return [
		tube(Vector3(0, 0, 0.08), 0.03, 0.2, X90, -1.0, 0.5),
		ring(Vector3(-0.1, 0, 0.2), 0.08, 0.03, X90),
		ring(Vector3(0.1, 0, 0.2), 0.08, 0.03, X90)], Vector3(0, 0.68, 0.26), accent, "body")
	_limbs(rig, Vector3(0.24, 0.84, 0), Vector3(0.5, 0.78, -0.22), Vector3(0.13, 0.4, 0), Vector3(0.2, 0, -0.04), 0.28, Vector3(0.26, 0.2, 0.4), "weapon")
	if armed:
		_raygun(rig, Vector3(0.5, 0.88, -0.5))

# Bowling-pin goon: fat bottom, tiny head, derby hat, unibrow.
func _goon(rig: CharacterRig, tone: String, _accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "goon_body", func(): return [
		ball(Vector3(0, -0.12, 0), Vector3(0.7, 0.66, 0.64)),
		ball(Vector3(0, 0.22, 0), Vector3(0.44, 0.46, 0.42)),
		ball(Vector3(0, 0.46, 0), Vector3(0.3, 0.3, 0.3))], Vector3(0, 0.6, 0), tone)
	_detail(body, "goon_stripes", func(): return [
		ring(Vector3(0, 0.36, 0), 0.19, 0.03, Vector3.ZERO, 0.3),
		ring(Vector3(0, 0.46, 0), 0.15, 0.03, Vector3.ZERO, 0.3)], "flash")
	var head = rig.add_part("head", sphere(0.25), Vector3(0, 1.3, 0), tone)
	_detail(head, "goon_face", func(): return [
		ball(Vector3(0, -0.1, -0.11), Vector3(0.44, 0.26, 0.32)),
		ball(Vector3(-0.08, 0.06, -0.18), Vector3(0.14, 0.18, 0.12), Vector3.ZERO, 0.5),
		ball(Vector3(0.08, 0.06, -0.18), Vector3(0.14, 0.18, 0.12), Vector3.ZERO, 0.5)], "flash")
	_detail(head, "goon_ink", func(): return [
		ball(Vector3(-0.06, 0.05, -0.235), Vector3(0.05, 0.08, 0.04), Vector3.ZERO, 0.0),
		ball(Vector3(0.06, 0.05, -0.235), Vector3(0.05, 0.08, 0.04), Vector3.ZERO, 0.0),
		slab(Vector3(-0.08, 0.16, -0.2), Vector3(0.17, 0.05, 0.08), Vector3(0, 0, -0.35), 0.0),
		slab(Vector3(0.08, 0.16, -0.2), Vector3(0.17, 0.05, 0.08), Vector3(0, 0, 0.35), 0.0),
		ball(Vector3(0, -0.03, -0.27), 0.12, Vector3.ZERO, 0.0)], "ink")
	_part(rig, "hat", "goon_derby", func(): return [
		ball(Vector3(0, 0.05, 0), Vector3(0.36, 0.32, 0.36)),
		tube(Vector3(0, 0.0, 0), 0.27, 0.04)], Vector3(0, 1.49, 0), "ink", "head")
	_limbs(rig, Vector3(0.17, 0.98, 0), Vector3(0.48, 0.74, -0.2), Vector3(0.15, 0.34, 0), Vector3(0.2, 0, -0.04), 0.26, Vector3(0.24, 0.17, 0.38), "ink")
	if armed:
		_plunger(rig, Vector3(0.48, 0.84, -0.48))

# Road-running bird: egg body on stilts, long beak, crest and tail feathers.
func _bird(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "bird_body", func(): return [
		ball(Vector3.ZERO, Vector3(0.54, 0.52, 0.72), Vector3(0.3, 0, 0))], Vector3(0, 0.88, 0.05), tone)
	_detail(body, "bird_belly", func(): return [
		ball(Vector3(0, -0.06, -0.12), Vector3(0.42, 0.4, 0.5), Vector3(0.3, 0, 0), 0.0)], "flash")
	var head = rig.add_part("head", sphere(0.2), Vector3(0, 1.5, -0.2), tone)
	_detail(head, "bird_eyes", func(): return [
		ball(Vector3(-0.09, 0.07, -0.12), Vector3(0.18, 0.22, 0.14), Vector3.ZERO, 0.5),
		ball(Vector3(0.09, 0.07, -0.12), Vector3(0.18, 0.22, 0.14), Vector3.ZERO, 0.5)], "flash")
	_detail(head, "bird_ink", func(): return [
		ball(Vector3(-0.08, 0.06, -0.185), Vector3(0.07, 0.1, 0.04), Vector3.ZERO, 0.0),
		ball(Vector3(0.08, 0.06, -0.185), Vector3(0.07, 0.1, 0.04), Vector3.ZERO, 0.0)], "ink")
	_detail(head, "bird_beak", func(): return [
		tube(Vector3(0, -0.05, -0.33), 0.09, 0.36, -X90, 0.0, 0.6)], "prop")
	_limb(rig, "neck", Vector3(0, 1.06, -0.1), "head", Vector3(0, -0.14, 0.04), 0.045, tone)
	_part(rig, "crest", "bird_crest", func(): return [
		ball(Vector3(0, 0.12, 0.0), Vector3(0.08, 0.3, 0.12), Vector3(0.2, 0, 0), 0.6),
		ball(Vector3(0, 0.1, 0.08), Vector3(0.08, 0.28, 0.12), Vector3(0.75, 0, 0), 0.6),
		ball(Vector3(0, 0.05, 0.14), Vector3(0.08, 0.24, 0.12), Vector3(1.3, 0, 0), 0.6)], Vector3(0, 1.66, -0.18), accent, "head")
	_part(rig, "tail", "bird_tail", func(): return [
		ball(Vector3(0, 0.16, 0.12), Vector3(0.1, 0.46, 0.16), Vector3(0.6, 0, 0), 0.7),
		ball(Vector3(-0.1, 0.12, 0.12), Vector3(0.1, 0.38, 0.16), Vector3(0.7, 0, 0.5), 0.7),
		ball(Vector3(0.1, 0.12, 0.12), Vector3(0.1, 0.38, 0.16), Vector3(0.7, 0, -0.5), 0.7)], Vector3(0, 0.98, 0.3), tone, "body")
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		_part(rig, "hand_" + tag, "bird_wing", func(): return [
			ball(Vector3(0, 0, 0.06), Vector3(0.1, 0.24, 0.36), Vector3(0.3, 0, 0))], Vector3(side * 0.31, 0.9, 0.04), tone)
		_part(rig, "foot_" + tag, "bird_foot", func(): return [
			ball(Vector3(0, 0.04, -0.12), Vector3(0.09, 0.08, 0.32), Vector3.ZERO, 0.6),
			ball(Vector3(-0.07, 0.04, -0.1), Vector3(0.09, 0.08, 0.28), Vector3(0, 0.6, 0), 0.6),
			ball(Vector3(0.07, 0.04, -0.1), Vector3(0.09, 0.08, 0.28), Vector3(0, -0.6, 0), 0.6),
			ball(Vector3(0, 0.05, 0.03), 0.11, Vector3.ZERO, 0.6)], Vector3(side * 0.15, 0, -0.02), "prop")
		_limb(rig, "leg_" + tag, Vector3(side * 0.1, 0.72, 0.06), "foot_" + tag, Vector3(0, 0.06, 0.03), 0.022, "prop")
	if armed:
		_plunger(rig, Vector3(0.36, 0.9, -0.4))

# Barrel-chested bulldog: huge chest and fists, jowls, underbite, spiked collar.
func _bulldog(rig: CharacterRig, tone: String, _accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "dog_body", func(): return [
		ball(Vector3(0, 0.12, -0.02), Vector3(0.88, 0.7, 0.74)),
		ball(Vector3(0, -0.22, 0.04), Vector3(0.56, 0.46, 0.5))], Vector3(0, 0.72, 0), tone)
	_detail(body, "dog_bib", func(): return [
		ball(Vector3(0, 0.06, -0.2), Vector3(0.6, 0.5, 0.42), Vector3.ZERO, 0.0)], "flash")
	_detail(body, "dog_collar", func(): return [
		ring(Vector3(0, 0.43, -0.06), 0.25, 0.06)], "ink")
	_detail(body, "dog_studs", func():
		var studs = []
		for i in 7:
			var angle = PI * (0.5 + (i - 3) * 0.26)
			var out = Vector3(cos(angle), 0, -sin(angle))
			studs.append(tube(Vector3(0, 0.43, -0.06) + out * 0.34, 0.045, 0.12, Vector3(0, atan2(-out.x, -out.z), 0) - X90, 0.0, 0.4))
		return studs, "flash")
	var head = rig.add_part("head", sphere(0.26), Vector3(0, 1.32, -0.1), tone)
	_detail(head, "dog_face", func(): return [
		ball(Vector3(-0.12, -0.11, -0.15), Vector3(0.28, 0.26, 0.28)),
		ball(Vector3(0.12, -0.11, -0.15), Vector3(0.28, 0.26, 0.28)),
		ball(Vector3(-0.09, 0.08, -0.2), Vector3(0.12, 0.12, 0.1), Vector3.ZERO, 0.5),
		ball(Vector3(0.09, 0.08, -0.2), Vector3(0.12, 0.12, 0.1), Vector3.ZERO, 0.5)], "flash")
	_detail(head, "dog_ink", func(): return [
		ball(Vector3(-0.08, 0.07, -0.245), Vector3(0.05, 0.06, 0.03), Vector3.ZERO, 0.0),
		ball(Vector3(0.08, 0.07, -0.245), Vector3(0.05, 0.06, 0.03), Vector3.ZERO, 0.0),
		slab(Vector3(-0.1, 0.16, -0.2), Vector3(0.16, 0.05, 0.08), Vector3(0, 0, -0.5), 0.0),
		slab(Vector3(0.1, 0.16, -0.2), Vector3(0.16, 0.05, 0.08), Vector3(0, 0, 0.5), 0.0),
		ball(Vector3(0, -0.02, -0.3), Vector3(0.14, 0.1, 0.1), Vector3.ZERO, 0.0)], "ink")
	var jaw = _part(rig, "jaw", "dog_jaw", func(): return [
		ball(Vector3(0, 0, 0), Vector3(0.42, 0.17, 0.36))], Vector3(0, 1.1, -0.24), tone, "head")
	_detail(jaw, "dog_teeth", func(): return [
		tube(Vector3(-0.1, 0.1, -0.1), 0.04, 0.12, Vector3.ZERO, 0.0, 0.4),
		tube(Vector3(0.1, 0.1, -0.1), 0.04, 0.12, Vector3.ZERO, 0.0, 0.4)], "flash")
	for side in SIDES:
		_part(rig, "ear_l" if side < 0 else "ear_r", "dog_ear", func(): return [
			ball(Vector3(0, -0.13, 0), Vector3(0.12, 0.32, 0.22))], Vector3(side * 0.25, 1.48, -0.06), "ink", "head", Vector3(0, 0, side * 0.25))
	_part(rig, "tail", "dog_tail", func(): return [
		ball(Vector3(0, 0.04, 0.06), Vector3(0.12, 0.14, 0.2), Vector3(0.6, 0, 0))], Vector3(0, 0.56, 0.26), tone, "body")
	_limbs(rig, Vector3(0.36, 1.0, 0), Vector3(0.62, 0.62, -0.2), Vector3(0.18, 0.36, 0.04), Vector3(0.24, 0, -0.02), 0.38, Vector3(0.3, 0.2, 0.42), "ink", 0.045)
	if armed:
		_puncher(rig, Vector3(0.62, 0.74, -0.5))

# Top-hat villain: lantern jaw, curled moustache, monocle, cape and collar.
func _villain(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "boss_body", func(): return [
		ball(Vector3(0, -0.1, 0), Vector3(0.84, 0.74, 0.76)),
		ball(Vector3(0, 0.3, 0), Vector3(0.56, 0.46, 0.5))], Vector3(0, 0.66, 0), tone)
	_detail(body, "boss_trim", func(): return [
		ball(Vector3(0, 0.1, -0.33), 0.09, Vector3.ZERO, 0.4),
		ball(Vector3(0, -0.08, -0.38), 0.09, Vector3.ZERO, 0.4),
		ball(Vector3(0, -0.26, -0.34), 0.09, Vector3.ZERO, 0.4),
		ball(Vector3(-0.1, 0.4, -0.2), Vector3(0.2, 0.14, 0.08), Vector3.ZERO, 0.5),
		ball(Vector3(0.1, 0.4, -0.2), Vector3(0.2, 0.14, 0.08), Vector3.ZERO, 0.5)], accent)
	_part(rig, "cape", "boss_cape", func(): return [
		ball(Vector3(0, -0.44, 0.1), Vector3(0.9, 0.92, 0.2), Vector3(-0.16, 0, 0)),
		tube(Vector3(-0.2, 0.08, 0.0), 0.11, 0.34, Vector3(0, 0, 0.35), 0.0),
		tube(Vector3(0.2, 0.08, 0.0), 0.11, 0.34, Vector3(0, 0, -0.35), 0.0)], Vector3(0, 1.1, 0.2), "ink", "body")
	var head = rig.add_part("head", sphere(0.27), Vector3(0, 1.34, -0.04), tone)
	_detail(head, "boss_eyes", func(): return [
		ball(Vector3(-0.1, 0.06, -0.2), Vector3(0.15, 0.11, 0.12), Vector3.ZERO, 0.5),
		ball(Vector3(0.1, 0.06, -0.2), Vector3(0.15, 0.11, 0.12), Vector3.ZERO, 0.5)], "flash")
	_detail(head, "boss_ink", func(): return [
		ball(Vector3(-0.09, 0.055, -0.255), Vector3(0.05, 0.06, 0.03), Vector3.ZERO, 0.0),
		ball(Vector3(0.09, 0.055, -0.255), Vector3(0.05, 0.06, 0.03), Vector3.ZERO, 0.0),
		slab(Vector3(-0.1, 0.14, -0.22), Vector3(0.18, 0.06, 0.08), Vector3(0, 0, -0.45), 0.0),
		slab(Vector3(0.1, 0.14, -0.22), Vector3(0.18, 0.06, 0.08), Vector3(0, 0, 0.45), 0.0),
		tube(Vector3(-0.17, -0.1, -0.25), 0.05, 0.3, Vector3(0, 0, 1.2), 0.0, 0.0),
		tube(Vector3(0.17, -0.1, -0.25), 0.05, 0.3, Vector3(0, 0, -1.2), 0.0, 0.0)], "ink")
	_detail(head, "boss_nose", func(): return [
		ball(Vector3(0, -0.03, -0.28), Vector3(0.12, 0.15, 0.16), Vector3.ZERO, 0.5)], tone)
	_detail(head, "boss_monocle", func(): return [
		ring(Vector3(0.1, 0.06, -0.265), 0.085, 0.018, X90, 0.3)], accent)
	var jaw = _part(rig, "jaw", "boss_jaw", func(): return [
		ball(Vector3(0, 0, 0), Vector3(0.68, 0.3, 0.56))], Vector3(0, 1.13, -0.08), tone, "head")
	_detail(jaw, "boss_teeth", func(): return [
		slab(Vector3(0, 0.07, -0.25), Vector3(0.38, 0.08, 0.06), Vector3.ZERO, 0.5)], "flash")
	var hat = _part(rig, "hat", "boss_hat", func(): return [
		tube(Vector3(0, 0.02, 0), 0.31, 0.04),
		tube(Vector3(0, 0.26, 0), 0.19, 0.46, Vector3.ZERO, 0.23)], Vector3(0, 1.56, -0.04), "ink", "head")
	_detail(hat, "boss_band", func(): return [
		tube(Vector3(0, 0.1, 0), 0.2, 0.1, Vector3.ZERO, 0.205, 0.0)], accent)
	_limbs(rig, Vector3(0.26, 1.0, 0), Vector3(0.6, 0.7, -0.22), Vector3(0.2, 0.38, 0), Vector3(0.26, 0, -0.04), 0.34, Vector3(0.3, 0.2, 0.46), "ink", 0.04)
	if armed:
		_blunderbuss(rig, Vector3(0.6, 0.8, -0.52))

# --------------------------------------------------------------- weapons ---
# The weapon is one part plus glued trim: the weapon view draws only the
# parts "weapon" and "hand_r", and children come along.

func _gun(rig: CharacterRig, key: String, at: Vector3, pieces: Callable) -> MeshInstance3D:
	return rig.add_part("weapon", fuse(key, pieces), at, "weapon", "weapon")

# Retro ray gun: fat body, ringed barrel, glowing bulb, tail fin.
func _raygun(rig: CharacterRig, at: Vector3) -> void:
	var gun = _gun(rig, "raygun", at, func(): return [
		ball(Vector3(0, 0, 0.06), Vector3(0.26, 0.26, 0.44)),
		slab(Vector3(0, -0.15, 0.17), Vector3(0.09, 0.2, 0.12), Vector3(0.3, 0, 0)),
		tube(Vector3(0, 0, -0.28), 0.045, 0.34, X90)])
	_detail(gun, "raygun_rings", func(): return [
		ring(Vector3(0, 0, -0.16), 0.11, 0.028, X90, 0.5),
		ring(Vector3(0, 0, -0.26), 0.085, 0.026, X90, 0.5),
		ring(Vector3(0, 0, -0.35), 0.065, 0.024, X90, 0.5),
		ring(Vector3(0, 0, 0.1), 0.135, 0.022, X90, 0.5)], "player_accent", "weapon")
	_detail(gun, "raygun_bulbs", func(): return [
		ball(Vector3(0, 0, -0.47), 0.13, Vector3.ZERO, 0.5),
		ball(Vector3(0, 0, 0.27), Vector3(0.17, 0.17, 0.14), Vector3.ZERO, 0.5),
		slab(Vector3(0, 0.15, 0.12), Vector3(0.03, 0.09, 0.2), Vector3(0.25, 0, 0), 0.5)], "runner", "weapon")

# Plunger blaster: stubby pipe with a funnel hopper and a rubber plunger.
func _plunger(rig: CharacterRig, at: Vector3) -> void:
	var gun = _gun(rig, "plunger", at, func(): return [
		tube(Vector3(0, 0, 0.06), 0.09, 0.4, X90),
		slab(Vector3(0, -0.15, 0.16), Vector3(0.08, 0.2, 0.11), Vector3(0.3, 0, 0))])
	_detail(gun, "plunger_stick", func(): return [
		tube(Vector3(0, 0, -0.26), 0.028, 0.28, X90, -1.0, 0.5),
		tube(Vector3(0, 0.15, 0.1), 0.11, 0.13, Vector3(PI, 0, 0), 0.04, 0.5)], "player_accent", "weapon")
	_detail(gun, "plunger_cup", func(): return [
		tube(Vector3(0, 0, -0.42), 0.15, 0.15, X90, 0.05, 0.6),
		ring(Vector3(0, 0, 0.2), 0.095, 0.03, X90, 0.5)], "grunt", "weapon")

# Boxing-glove cannon: wide barrel, spring coils and a glove ready to pop.
func _puncher(rig: CharacterRig, at: Vector3) -> void:
	var gun = _gun(rig, "puncher", at, func(): return [
		tube(Vector3(0, 0, 0.1), 0.14, 0.44, X90),
		tube(Vector3(0, 0, 0.34), 0.1, 0.08, X90),
		slab(Vector3(0, -0.2, 0.18), Vector3(0.1, 0.2, 0.12), Vector3(0.3, 0, 0))])
	_detail(gun, "puncher_spring", func(): return [
		ring(Vector3(0, 0, -0.15), 0.1, 0.03, X90, 0.4),
		ring(Vector3(0, 0, -0.22), 0.1, 0.03, X90, 0.4),
		ring(Vector3(0, 0, -0.29), 0.1, 0.03, X90, 0.4),
		ring(Vector3(0, 0, 0.26), 0.15, 0.03, X90, 0.4)], "flash", "weapon")
	_detail(gun, "puncher_glove", func(): return [
		ball(Vector3(0, 0, -0.46), Vector3(0.32, 0.32, 0.34)),
		ball(Vector3(-0.14, 0.0, -0.4), Vector3(0.14, 0.16, 0.22), Vector3.ZERO, 0.6)], "grunt", "weapon")

# Blunderbuss: brass bell muzzle with a bomb loaded in it.
func _blunderbuss(rig: CharacterRig, at: Vector3) -> void:
	var gun = _gun(rig, "blunderbuss", at, func(): return [
		tube(Vector3(0, 0, 0.04), 0.08, 0.5, X90),
		slab(Vector3(0, -0.1, 0.32), Vector3(0.1, 0.22, 0.2), Vector3(0.5, 0, 0)),
		ball(Vector3(0, 0, -0.38), 0.24)])
	_detail(gun, "blunderbuss_bell", func(): return [
		tube(Vector3(0, 0, -0.28), 0.2, 0.2, X90, 0.085),
		ring(Vector3(0, 0, 0.1), 0.085, 0.025, X90, 0.5),
		ring(Vector3(0, 0, 0.24), 0.085, 0.025, X90, 0.5)], "player_accent", "weapon")
	_detail(gun, "blunderbuss_fuse", func(): return [
		tube(Vector3(0, 0.08, -0.48), 0.02, 0.12, Vector3(-0.6, 0, 0), -1.0, 0.4),
		ball(Vector3(0, 0.14, -0.53), 0.07, Vector3.ZERO, 0.4)], "flash", "weapon")

# ---------------------------------------------------------------- blocks ---

func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	# Same block, same look: variety comes from where and how big it is.
	var pick = int(absf(holder.position.x * 3.0 + holder.position.z * 7.0)) % 3
	if shape == "cylinder":
		var radius = extent.x * 0.5
		if role == "wall":
			if extent.y >= 2.6:
				_mushroom(holder, radius, extent.y, color_key)
			else:
				_boulder(holder, radius, extent.y, color_key)
		elif extent.y >= 2.0:
			_cactus(holder, radius, extent.y, color_key)
		elif extent.x <= 1.5:
			_hydrant(holder, radius, extent.y, color_key)
		else:
			_barrel(holder, radius, extent.y, color_key)
		return
	# Boxes are modelled along X and turned when the block runs along Z.
	var turned = extent.z > extent.x
	var size = Vector3(extent.z, extent.y, extent.x) if turned else extent
	var euler = Vector3(0, PI * 0.5, 0) if turned else Vector3.ZERO
	if role == "wall":
		if extent.y >= 2.0:
			_bricks(holder, size, euler, color_key)
		else:
			_hedge(holder, size, euler, color_key)
	elif size.x <= 3.6 and size.x >= size.z * 2.0:
		_anvil(holder, size, euler)
	else:
		_crates(holder, size, euler, color_key, pick)

# Wobbly brick wall: loose bricks stick out, round coping stones on top.
func _bricks(holder: Node3D, size: Vector3, euler: Vector3, color_key: String) -> void:
	add(holder, fuse("bricks%s" % size, func():
		var pieces = [slab(Vector3(0, (size.y - 0.25) * 0.5, 0), Vector3(size.x - 0.2, size.y - 0.25, size.z - 0.2))]
		var stones = maxi(1, roundi(size.x / 1.1))
		var wide = size.x / stones
		for i in stones:
			pieces.append(ball(Vector3(-size.x * 0.5 + (i + 0.5) * wide, size.y - 0.3, 0), Vector3(wide * 1.04, 0.6, size.z)))
		var rows = int((size.y - 0.6) / 0.42)
		var columns = int((size.x - 0.3) / 0.8)
		for row in rows:
			var height = 0.28 + row * 0.42
			for column in columns:
				if (row * 7 + column * 13) % 3 != 0:
					continue
				var along = (column + 0.5 + (0.25 if row % 2 == 0 else -0.25) - columns * 0.5) * 0.8
				for side in SIDES:
					if side > 0 or (row + column) % 2 == 0:
						pieces.append(slab(Vector3(along, height, side * (size.z * 0.5 - 0.07)), Vector3(0.64, 0.3, 0.14)))
			if row % 2 == 1:
				for side in SIDES:
					pieces.append(slab(Vector3(side * (size.x * 0.5 - 0.07), height, 0), Vector3(0.14, 0.3, minf(0.64, size.z - 0.5))))
		return pieces), Vector3.ZERO, "wall", color_key, euler)

# Low wall: a planter box with a row of puffy bushes and a few flowers.
func _hedge(holder: Node3D, size: Vector3, euler: Vector3, color_key: String) -> void:
	add(holder, fuse("planter%s" % size, func(): return [
		slab(Vector3(0, 0.2, 0), Vector3(size.x - 0.12, 0.4, size.z - 0.12)),
		slab(Vector3(0, 0.38, 0), Vector3(size.x, 0.14, size.z))]), Vector3.ZERO, "wall", "prop", euler)
	var bushes = maxi(2, roundi(size.x / 1.0))
	var wide = minf(size.x / bushes * 1.3, size.x)
	add(holder, fuse("hedge%s" % size, func():
		var pieces = []
		for i in bushes:
			var along = lerpf(-size.x * 0.5 + wide * 0.5, size.x * 0.5 - wide * 0.5, i / float(bushes - 1))
			var tall = (size.y - 0.3) * (1.0 if i % 2 == 0 else 0.82)
			pieces.append(ball(Vector3(along, 0.3 + tall * 0.5, 0), Vector3(wide, tall, size.z * 0.96)))
		return pieces), Vector3.ZERO, "wall", color_key, euler)
	add(holder, fuse("flowers%s" % size, func():
		var pieces = []
		for i in bushes:
			var along = lerpf(-size.x * 0.5 + wide * 0.5, size.x * 0.5 - wide * 0.5, i / float(bushes - 1))
			var tall = (size.y - 0.3) * (1.0 if i % 2 == 0 else 0.82)
			var drift = size.z * (0.2 if i % 2 == 0 else -0.22)
			pieces.append(ball(Vector3(along + 0.1, 0.27 + tall * 0.93, drift), 0.22, Vector3.ZERO, 0.5))
		return pieces), Vector3.ZERO, "wall", "runner", euler)

# Giant spotted mushroom; the cap covers the whole footprint.
func _mushroom(holder: Node3D, radius: float, tall: float, color_key: String) -> void:
	add(holder, fuse("stem%f/%f" % [radius, tall], func(): return [
		tube(Vector3(0, tall * 0.3, 0), radius * 0.62, tall * 0.6, Vector3.ZERO, radius * 0.45),
		ball(Vector3(0, 0.14, 0), Vector3(radius * 1.6, 0.42, radius * 1.6)),
		ring(Vector3(0, tall * 0.5, 0), radius * 0.56, 0.07)]), Vector3.ZERO, "wall", "flash")
	add(holder, fuse("cap%f/%f" % [radius, tall], func(): return [
		ball(Vector3(0, tall * 0.72, 0), Vector3(radius * 2.0, tall * 0.56, radius * 2.0))]), Vector3.ZERO, "wall", color_key)
	add(holder, fuse("spots%f/%f" % [radius, tall], func():
		var pieces = [ball(Vector3(0, tall * 0.985, 0), Vector3(radius * 0.6, 0.12, radius * 0.6), Vector3.ZERO, 0.3)]
		for i in 5:
			var angle = TAU * i / 5.0 + 0.4
			var out = Vector3(cos(angle), 0, sin(angle))
			# A point on the cap ellipsoid 50 degrees down from the top.
			var at = Vector3(0, tall * 0.72 + tall * 0.28 * 0.62, 0) + out * radius * 0.76
			pieces.append(ball(at, Vector3(radius * 0.42, 0.16, radius * 0.42), Vector3(0, -angle, -0.75), 0.3))
		return pieces), Vector3.ZERO, "wall", "flash")

# Pile of round rocks.
func _boulder(holder: Node3D, radius: float, tall: float, color_key: String) -> void:
	add(holder, fuse("boulder%f/%f" % [radius, tall], func(): return [
		ball(Vector3(-radius * 0.08, tall * 0.5, -radius * 0.06), Vector3(radius * 1.8, tall, radius * 1.8)),
		ball(Vector3(radius * 0.42, tall * 0.28, radius * 0.4), Vector3(radius * 0.86, tall * 0.56, radius * 0.86)),
		ball(Vector3(-radius * 0.5, tall * 0.2, radius * 0.42), Vector3(radius * 0.66, tall * 0.4, radius * 0.66))]), Vector3.ZERO, "wall", color_key)
	add(holder, fuse("pebbles%f/%f" % [radius, tall], func(): return [
		ball(Vector3(radius * 0.25, tall * 0.9, -radius * 0.2), Vector3(radius * 0.5, 0.14, radius * 0.4), Vector3(0, 0.5, -0.4), 0.0),
		ball(Vector3(-radius * 0.45, tall * 0.74, 0.1), Vector3(radius * 0.3, 0.12, radius * 0.3), Vector3(0, 0, 0.7), 0.0)]), Vector3.ZERO, "wall", "flash")

# Bulging barrel with hoops.
func _barrel(holder: Node3D, radius: float, tall: float, color_key: String) -> void:
	add(holder, fuse("barrel%f/%f" % [radius, tall], func(): return [
		tube(Vector3(0, tall * 0.25, 0), radius * 0.8, tall * 0.5, Vector3.ZERO, radius * 0.97),
		tube(Vector3(0, tall * 0.75, 0), radius * 0.97, tall * 0.5, Vector3.ZERO, radius * 0.8)]), Vector3.ZERO, "prop", color_key)
	add(holder, fuse("hoops%f/%f" % [radius, tall], func(): return [
		ring(Vector3(0, tall * 0.16, 0), radius * 0.86, 0.05, Vector3.ZERO, 0.5),
		ring(Vector3(0, tall * 0.84, 0), radius * 0.86, 0.05, Vector3.ZERO, 0.5),
		tube(Vector3(0, tall, 0), radius * 0.6, 0.05, Vector3.ZERO, -1.0, 0.0),
		ball(Vector3(radius * 0.3, tall + 0.04, 0), 0.16, Vector3.ZERO, 0.5)]), Vector3.ZERO, "prop", "weapon")

# Fire hydrant with a dome and side caps.
func _hydrant(holder: Node3D, radius: float, tall: float, color_key: String) -> void:
	add(holder, fuse("hydrant%f/%f" % [radius, tall], func(): return [
		tube(Vector3(0, tall * 0.07, 0), radius * 0.9, tall * 0.14),
		tube(Vector3(0, tall * 0.42, 0), radius * 0.6, tall * 0.6),
		tube(Vector3(0, tall * 0.7, 0), radius * 0.78, tall * 0.08),
		ball(Vector3(0, tall * 0.74, 0), Vector3(radius * 1.2, tall * 0.44, radius * 1.2))]), Vector3.ZERO, "prop", color_key)
	add(holder, fuse("hydrant_caps%f/%f" % [radius, tall], func(): return [
		tube(Vector3(0, tall * 0.96, 0), radius * 0.22, tall * 0.1, Vector3.ZERO, -1.0, 0.5),
		tube(Vector3(-radius * 0.72, tall * 0.46, 0), radius * 0.3, radius * 0.36, Vector3(0, 0, PI * 0.5), -1.0, 0.5),
		tube(Vector3(radius * 0.72, tall * 0.46, 0), radius * 0.3, radius * 0.36, Vector3(0, 0, PI * 0.5), -1.0, 0.5),
		tube(Vector3(0, tall * 0.46, radius * 0.72), radius * 0.36, radius * 0.36, X90, -1.0, 0.5)]), Vector3.ZERO, "prop", "flash")

# Potted cactus with two arms and a flower.
func _cactus(holder: Node3D, radius: float, tall: float, color_key: String) -> void:
	add(holder, fuse("pot%f" % radius, func(): return [
		tube(Vector3(0, 0.25, 0), radius * 0.7, 0.5, Vector3.ZERO, radius * 0.95),
		ring(Vector3(0, 0.5, 0), radius * 0.86, 0.07)]), Vector3.ZERO, "prop", color_key)
	var girth = radius * 0.46
	add(holder, fuse("cactus%f/%f" % [radius, tall], func(): return [
		pill(Vector3(0, 0.4 + (tall - 0.4) * 0.5, 0), girth, tall - 0.4),
		pill(Vector3(-radius * 0.5, tall * 0.5, 0), girth * 0.5, radius * 0.9, Vector3(0, 0, PI * 0.5)),
		pill(Vector3(-radius * 0.74, tall * 0.62, 0), girth * 0.55, tall * 0.34),
		pill(Vector3(radius * 0.5, tall * 0.62, 0), girth * 0.5, radius * 0.9, Vector3(0, 0, PI * 0.5)),
		pill(Vector3(radius * 0.74, tall * 0.72, 0), girth * 0.55, tall * 0.3)]), Vector3.ZERO, "prop", "wall")
	add(holder, fuse("bloom%f/%f" % [radius, tall], func(): return [
		ball(Vector3(0, tall, 0), Vector3(0.34, 0.2, 0.34), Vector3.ZERO, 0.6),
		ball(Vector3(-radius * 0.74, tall * 0.8, 0), 0.18, Vector3.ZERO, 0.5)]), Vector3.ZERO, "prop", "runner")

# Giant anvil with its horn along the block.
func _anvil(holder: Node3D, size: Vector3, euler: Vector3) -> void:
	add(holder, fuse("anvil%s" % size, func(): return [
		slab(Vector3(0, size.y * 0.1, 0), Vector3(size.x * 0.56, size.y * 0.2, size.z)),
		slab(Vector3(0, size.y * 0.4, 0), Vector3(size.x * 0.3, size.y * 0.4, size.z * 0.6)),
		slab(Vector3(-size.x * 0.1, size.y * 0.8, 0), Vector3(size.x * 0.6, size.y * 0.4, size.z)),
		tube(Vector3(size.x * 0.35, size.y * 0.82, 0), size.y * 0.17, size.x * 0.3, Vector3(0, 0, -PI * 0.5), 0.02, 1.0, Vector3(1, 1, size.z / (size.y * 0.42)))]), Vector3.ZERO, "prop", "weapon", euler)

# Shipping crates with pale frames; a lone crate may be a jack-in-the-box.
func _crates(holder: Node3D, size: Vector3, euler: Vector3, color_key: String, pick: int) -> void:
	var across = maxi(1, roundi(size.x / 1.6))
	var deep = maxi(1, roundi(size.z / 1.6))
	var cell = Vector3(size.x / across, size.y, size.z / deep)
	var centres: Array[Vector3] = []
	for i in across:
		for j in deep:
			centres.append(Vector3(-size.x * 0.5 + (i + 0.5) * cell.x, 0, -size.z * 0.5 + (j + 0.5) * cell.z))
	add(holder, fuse("crates%s" % size, func():
		var pieces = []
		for centre in centres:
			pieces.append(slab(centre + Vector3(0, (cell.y - 0.07) * 0.5, 0), cell - Vector3(0.14, 0.07, 0.14)))
		return pieces), Vector3.ZERO, "prop", color_key, euler)
	add(holder, fuse("frames%s" % size, func():
		var pieces = []
		var beam = 0.16
		for centre in centres:
			for side in SIDES:
				for level in [beam * 0.5, cell.y - beam * 0.5]:
					pieces.append(slab(centre + Vector3(0, level, side * (cell.z - beam) * 0.5), Vector3(cell.x, beam, beam), Vector3.ZERO, 0.5))
					pieces.append(slab(centre + Vector3(side * (cell.x - beam) * 0.5, level, 0), Vector3(beam, beam, cell.z - beam * 2.0), Vector3.ZERO, 0.5))
				for other in SIDES:
					pieces.append(slab(centre + Vector3(side * (cell.x - beam) * 0.5, cell.y * 0.5, other * (cell.z - beam) * 0.5), Vector3(beam, cell.y - beam * 2.0, beam), Vector3.ZERO, 0.5))
				var slope = atan2(cell.y - beam * 2.0, cell.x - beam * 2.0)
				pieces.append(slab(centre + Vector3(0, cell.y * 0.5, side * (cell.z * 0.5 - 0.06)), Vector3(Vector2(cell.x - beam * 2.0, cell.y - beam * 2.0).length(), 0.13, 0.08), Vector3(0, 0, side * slope), 0.0))
			pieces.append(slab(centre + Vector3(0, cell.y - 0.05, 0), Vector3(Vector2(cell.x - beam * 2.0, cell.z - beam * 2.0).length(), 0.08, 0.14), Vector3(0, atan2(cell.z, cell.x), 0), 0.0))
		return pieces), Vector3.ZERO, "prop", "floor_alt", euler)
	if centres.size() == 1 and pick == 0:
		# Jack-in-the-box: an oversized spring with a boxing glove on it.
		var reach = minf(cell.x, cell.z) * 0.5
		add(holder, fuse("spring%s" % size, func():
			var pieces = []
			for i in 4:
				pieces.append(ring(Vector3(0, size.y + 0.1 + i * 0.17, 0), reach * (0.5 - i * 0.04), 0.06, Vector3(0.12 if i % 2 == 0 else -0.12, 0, 0), 0.6))
			return pieces), Vector3.ZERO, "prop", "flash", euler)
		add(holder, fuse("spring_glove%s" % size, func(): return [
			ball(Vector3(0, size.y + 1.0, 0), Vector3(reach * 1.3, reach * 1.2, reach * 1.4)),
			ball(Vector3(-reach * 0.55, size.y + 0.94, -reach * 0.1), Vector3(reach * 0.5, reach * 0.6, reach * 0.8), Vector3.ZERO, 0.6),
			tube(Vector3(0, size.y + 0.74, 0), reach * 0.4, 0.14)]), Vector3.ZERO, "prop", "grunt", euler)

# --------------------------------------------------------------- pickups ---

func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			# A big heart with a shine.
			add(holder, fuse("heart", func(): return [
				ball(Vector3(-0.14, 0.09, 0), Vector3(0.36, 0.36, 0.26)),
				ball(Vector3(0.14, 0.09, 0), Vector3(0.36, 0.36, 0.26)),
				tube(Vector3(0, -0.13, 0), 0.27, 0.36, Vector3(PI, 0, 0), 0.0, 1.0, Vector3(1, 1, 0.45))]), Vector3.ZERO, "pickup", "pickup_health")
			add(holder, fuse("heart_shine", func(): return [
				ball(Vector3(-0.17, 0.15, -0.11), Vector3(0.12, 0.09, 0.06), Vector3(0, 0, 0.5), 0.0),
				ball(Vector3(-0.17, 0.15, 0.11), Vector3(0.12, 0.09, 0.06), Vector3(0, 0, 0.5), 0.0)]), Vector3.ZERO, "pickup", "flash")
		"scatter":
			# Cream pie with a cherry, tipped towards the camera.
			var tip = Vector3(0.45, 0, 0)
			add(holder, fuse("pie_tin", func(): return [
				tube(Vector3(0, -0.1, 0), 0.2, 0.14, Vector3.ZERO, 0.32)]), Vector3.ZERO, "pickup", "pickup_ammo", tip)
			add(holder, fuse("pie_cream", func():
				var pieces = [ball(Vector3(0, 0.0, 0), Vector3(0.56, 0.22, 0.56)), ball(Vector3(0, 0.1, 0), Vector3(0.3, 0.2, 0.3))]
				for i in 6:
					pieces.append(ball(Vector3(cos(i * TAU / 6.0) * 0.23, 0.0, sin(i * TAU / 6.0) * 0.23), 0.16, Vector3.ZERO, 0.6))
				return pieces), Vector3.ZERO, "pickup", "flash", tip)
			add(holder, fuse("pie_cherry", func(): return [
				ball(Vector3(0, 0.23, 0), 0.14, Vector3.ZERO, 0.6)]), Vector3.ZERO, "pickup", "grunt", tip)
		"rapid":
			# Seltzer bottle with a siphon head.
			add(holder, fuse("seltzer", func(): return [
				tube(Vector3(0, -0.1, 0), 0.16, 0.36),
				ball(Vector3(0, 0.08, 0), Vector3(0.32, 0.24, 0.32)),
				tube(Vector3(0, 0.22, 0), 0.05, 0.14)]), Vector3.ZERO, "pickup", "pickup_ammo")
			add(holder, fuse("seltzer_label", func(): return [
				tube(Vector3(0, -0.1, 0), 0.165, 0.16, Vector3.ZERO, -1.0, 0.0)]), Vector3.ZERO, "pickup", "flash")
			add(holder, fuse("seltzer_head", func(): return [
				tube(Vector3(0, 0.31, 0), 0.08, 0.08, Vector3.ZERO, -1.0, 0.6),
				tube(Vector3(0.12, 0.31, 0), 0.03, 0.18, Vector3(0, 0, PI * 0.5), -1.0, 0.6),
				slab(Vector3(-0.1, 0.36, 0), Vector3(0.2, 0.04, 0.07), Vector3(0, 0, -0.3), 0.6)]), Vector3.ZERO, "pickup", "weapon")
		_:
			# Round bomb with a lit fuse.
			add(holder, fuse("bomb", func(): return [
				ball(Vector3(0, -0.05, 0), 0.48),
				tube(Vector3(0, 0.2, 0), 0.09, 0.1)]), Vector3.ZERO, "pickup", "weapon")
			add(holder, fuse("bomb_band", func(): return [
				ring(Vector3(0, -0.05, 0), 0.235, 0.035, Vector3.ZERO, 0.4),
				tube(Vector3(0.04, 0.3, 0), 0.022, 0.14, Vector3(0, 0, -0.5), -1.0, 0.4)]), Vector3.ZERO, "pickup", "pickup_ammo")
			var spark = add(holder, star(5, 0.22, 0.12), Vector3(0.1, 0.4, 0), "pickup", "player_accent", X90)
			spark.scale = Vector3.ONE * 0.26

## Chunky star; squeezed along Z because the core stretches bullets 2.4x.
func bullet_mesh() -> Mesh:
	return star(5, 0.27, 0.32, 0.45)

# --------------------------------------------------------------- scenery ---

func decorate(holder: Node3D, arena: Arena) -> void:
	var half = arena.size * 0.5
	var dice = RandomNumberGenerator.new()
	dice.seed = hash(arena.title)
	# Rolling hills: tall behind the far wall, low towards the camera.
	var greens = ["bot", "pickup_health"]
	for i in 4:
		var wide = [18.0, 24.0][i % 2]
		_hill(holder, Vector3((i - 1.5) * half.x * 0.75 + dice.randf_range(-2, 2), 0, -half.y - 9.0 - (i % 2) * 5.0), wide, 7.0 + (i % 2) * 3.0, greens[i % 2])
	for side in SIDES:
		_hill(holder, Vector3(side * (half.x + 11.0), 0, -half.y * 0.4), 18.0, 8.0, greens[0])
		_hill(holder, Vector3(side * (half.x + 9.0), 0, half.y * 0.7), 14.0, 5.0, greens[1])
		_hill(holder, Vector3(side * half.x * 0.5, 0, half.y + 8.0), 18.0, 2.4, greens[0 if side < 0 else 1])
	# Lollipop trees along the far wall and the sides.
	var candy = ["runner", "prop", "player_accent", "tank"]
	var spots: Array[Vector3] = []
	for i in 5:
		spots.append(Vector3(lerpf(-half.x, half.x, (i + 0.5) / 5.0) + dice.randf_range(-1.5, 1.5), 0, -half.y - dice.randf_range(3.0, 5.5)))
	for side in SIDES:
		for i in 2:
			spots.append(Vector3(side * (half.x + dice.randf_range(3.0, 5.0)), 0, lerpf(-half.y * 0.6, half.y * 0.5, i) + dice.randf_range(-1.5, 1.5)))
	for i in spots.size():
		_lollipop(holder, spots[i], 3.4 + (i % 3) * 0.8, candy[i % candy.size()])
	# Puffy clouds, high and far enough to never cover the playfield.
	for i in 7:
		var angle = lerpf(-PI * 1.08, PI * 0.08, i / 6.0)
		var at = Vector3(cos(angle) * (half.x + 12.0), dice.randf_range(7.0, 11.0), sin(angle) * (half.y + 13.0))
		add(holder, _cloud(i % 2), at, "prop", "flash", Vector3(0, dice.randf_range(-0.4, 0.4), 0))
	# A big smiling sun behind the far wall.
	var sun = Vector3(half.x * 0.55, 13.0, -half.y - 24.0)
	add(holder, fuse("sun", func():
		var pieces = [[shared("dome", _dome), _x(Vector3.ZERO, Vector3.ONE * 6.0), 1.0]]
		for i in 12:
			var angle = TAU * i / 12.0
			pieces.append(tube(Vector3(sin(angle), cos(angle), 0) * 4.1, 0.55, 1.5, Vector3(0, 0, -angle), 0.0))
		return pieces), sun, "flash", "player_accent")
	# The sun is unshaded so it always glows; a dark copy behind it is its outline.
	add(holder, fuse("sun_back", func():
		var pieces = [[shared("dome", _dome), _x(Vector3(0, 0, -1.6), Vector3(6.5, 6.5, 1.0)), 0.0]]
		for i in 12:
			var angle = TAU * i / 12.0
			pieces.append(tube(Vector3(sin(angle) * 4.1, cos(angle) * 4.1, -1.6), 0.8, 2.0, Vector3(0, 0, -angle), 0.0, 0.0))
		return pieces), sun, "flash", "ink")
	add(holder, fuse("sun_face", func(): return [
		ball(Vector3(-1.0, 0.7, 2.75), Vector3(0.55, 1.0, 0.3), Vector3.ZERO, 0.0),
		ball(Vector3(1.0, 0.7, 2.75), Vector3(0.55, 1.0, 0.3), Vector3.ZERO, 0.0),
		ring(Vector3(0, 0.1, 2.3), 1.5, 0.13, Vector3(PI * 0.5 - 0.5, 0, 0), 0.0)]), sun, "fx", "ink")
	add(holder, fuse("sun_cheeks", func(): return [
		ball(Vector3(-1.8, -0.4, 2.35), Vector3(0.9, 0.6, 0.3), Vector3(0, -0.6, 0), 0.0),
		ball(Vector3(1.8, -0.4, 2.35), Vector3(0.9, 0.6, 0.3), Vector3(0, 0.6, 0), 0.0)]), sun, "fx", "runner")
	# Comic signposts leaning over the walls.
	_sign(holder, Vector3(-half.x * 0.5, 0, -half.y - 2.6), 0.0, "POW!", "player_accent")
	_sign(holder, Vector3(half.x + 2.6, 0, -half.y * 0.15), -PI * 0.5, "ZAP!", "runner")
	_sign(holder, Vector3(-half.x - 2.6, 0, half.y * 0.2), PI * 0.5, "BAM!", "prop")

func _dome() -> Mesh:
	# Smoother than the shared sphere: these are many units across.
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 40
	mesh.rings = 20
	return mesh

func _hill(holder: Node3D, at: Vector3, wide: float, tall: float, color_key: String) -> void:
	add(holder, fuse("hill%f/%f" % [wide, tall], func(): return [
		[shared("dome", _dome), _x(Vector3.ZERO, Vector3(wide, tall * 2.0, wide * 0.6)), 1.0]]), at, "prop", color_key)

func _lollipop(holder: Node3D, at: Vector3, tall: float, color_key: String) -> void:
	add(holder, fuse("stick%f" % tall, func(): return [
		tube(Vector3(0, tall * 0.5, 0), 0.12, tall)]), at, "prop", "flash")
	add(holder, fuse("candy%f" % tall, func(): return [
		ball(Vector3(0, tall + 0.6, 0), Vector3(2.3, 2.3, 0.8)),
		ball(Vector3(0, tall + 0.6, 0), Vector3(1.3, 1.3, 1.0), Vector3.ZERO, 0.5)]), at, "prop", color_key)

func _cloud(variant: int) -> Mesh:
	return fuse("cloud%d" % variant, func():
		if variant == 0:
			return [ball(Vector3(0, 0, 0), Vector3(4.0, 2.4, 2.4)), ball(Vector3(-2.0, -0.3, 0), Vector3(2.6, 1.7, 2.0)), ball(Vector3(2.1, -0.2, 0), Vector3(3.0, 1.9, 2.0)), ball(Vector3(0.8, 0.9, 0), Vector3(2.2, 1.8, 1.8))]
		return [ball(Vector3(0, 0, 0), Vector3(3.0, 2.0, 2.0)), ball(Vector3(-1.6, -0.2, 0), Vector3(2.2, 1.4, 1.7)), ball(Vector3(1.6, -0.3, 0), Vector3(2.0, 1.3, 1.7))])

# Post with a spiky burst and a shout on it, facing `yaw` and tipped up so
# the top-down camera reads it too.
func _sign(holder: Node3D, at: Vector3, yaw: float, shout: String, color_key: String) -> void:
	add(holder, fuse("sign_post", func(): return [
		tube(Vector3(0, 1.7, 0), 0.14, 3.4)]), at, "prop", "prop")
	var face = Basis.from_euler(Vector3(-0.55, yaw, 0))
	var board = add(holder, star(12, 0.36, 0.2), at + Vector3(0, 3.7, 0), "prop", color_key)
	board.transform = Transform3D(face * Basis.from_euler(X90) * Basis.from_scale(Vector3(4.2, 1.0, 3.0)), at + Vector3(0, 3.7, 0))
	var text = add(holder, shared("text:" + shout, func():
		var mesh = TextMesh.new()
		mesh.text = shout
		mesh.font = Dimensions.hub.active.font
		mesh.font_size = 96
		mesh.pixel_size = 0.0125
		mesh.depth = 0.06
		return mesh), Vector3.ZERO, "fx", "ink")
	text.transform = Transform3D(face, at + Vector3(0, 3.7, 0) + face * Vector3(0, -0.1, 0.24))
