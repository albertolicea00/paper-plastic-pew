extends DimensionBuilder
## Plastic Blocks shapes: everything is built from interlocking studded toy
## bricks. Figures are stacks of moulded bricks with cylinder stud-topped heads,
## C-grip claw hands and boxy feet; walls and props are courses of studded
## bricks and plates; scenery is a toybox of brick towers and loose pieces.
## Most shapes fuse several primitives into one mesh per colour, so a character
## stays around a dozen draws. Part names matter to animator.gd: the word before
## the first "_" picks how an extra part jolts, scatters and rides (stud, plate,
## visor, antenna, eye).

const X90 = Vector3(PI * 0.5, 0, 0)
const SIDES = [-1.0, 1.0]
# One stud: radius, height and the usual top-plate rise above a brick.
const STUD_R = 0.12
const STUD_H = 0.07

# ------------------------------------------------------------------ pieces ---

func _x(at: Vector3, size: Vector3 = Vector3.ONE, euler: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(euler) * Basis.from_scale(size), at)

func _v(size) -> Vector3:
	return size if size is Vector3 else Vector3.ONE * float(size)

# Pieces for fuse(): [mesh, transform]. `size` is the full extent.
func slab(at: Vector3, size: Vector3, euler: Vector3 = Vector3.ZERO) -> Array:
	return [box(Vector3.ONE), _x(at, size, euler)]

func ball(at: Vector3, size, euler: Vector3 = Vector3.ZERO) -> Array:
	return [sphere(0.5), _x(at, _v(size), euler)]

## Cylinder along Y before `euler`; `top` < 0 keeps it straight, 0 makes a cone.
func tube(at: Vector3, radius: float, height: float, euler: Vector3 = Vector3.ZERO, top: float = -1.0, size: Vector3 = Vector3.ONE) -> Array:
	return [cylinder(radius, height, top, 14), _x(at, size, euler)]

## Torus around Y before `euler`.
func ring(at: Vector3, radius: float, thick: float, euler: Vector3 = Vector3.ZERO) -> Array:
	var mesh = shared("torus%f/%f" % [radius, thick], func():
		var made = TorusMesh.new()
		made.inner_radius = radius - thick
		made.outer_radius = radius + thick
		made.rings = 16
		made.ring_segments = 8
		return made)
	return [mesh, _x(at, Vector3.ONE, euler)]

## A single stud standing on `at` (its base).
func stud(at: Vector3, radius: float = STUD_R, height: float = STUD_H) -> Array:
	return [cylinder(radius, height, -1.0, 12), _x(at + Vector3(0, height * 0.5, 0))]

## Studs laid out across the top face of a brick of `size`, centred on `top_y`.
func studs(into: Array, size: Vector3, top_y: float, radius: float = STUD_R, gap: float = 0.0) -> void:
	var pitch = (radius + 0.05) * 2.0
	var nx = maxi(1, floori((size.x - 0.04) / pitch))
	var nz = maxi(1, floori((size.z - 0.04) / pitch))
	for i in nx:
		for j in nz:
			var x = (i - (nx - 1) * 0.5) * (size.x - 0.06) / maxf(nx, 1.0)
			var z = (j - (nz - 1) * 0.5) * (size.z - 0.06) / maxf(nz, 1.0)
			into.append(stud(Vector3(x, top_y + gap, z), radius))

## Studs across the top face of a brick, returned as a fresh pieces array (for
## single-expression fuse closures).
func studs_arr(size: Vector3, top_y: float, radius: float = STUD_R) -> Array:
	var p: Array = []
	studs(p, size, top_y, radius)
	return p

## One mesh out of many pieces; runs once per key and is cached.
func fuse(key: String, pieces: Callable) -> Mesh:
	return shared("fuse:" + key, func():
		var points = PackedVector3Array()
		var normals = PackedVector3Array()
		var indices = PackedInt32Array()
		for piece in pieces.call():
			var source: Mesh = piece[0]
			var xform: Transform3D = piece[1]
			var arrays: Array = source.surface_get_arrays(0)
			var from: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var facing: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var slant = xform.basis.inverse().transposed()
			var first = points.size()
			for i in from.size():
				points.append(xform * from[i])
				normals.append((slant * facing[i]).normalized())
			# A mirrored transform flips winding: swap each triangle back.
			var flipped = xform.basis.determinant() < 0.0
			for i in range(0, order.size(), 3):
				indices.append(first + order[i])
				indices.append(first + order[i + (2 if flipped else 1)])
				indices.append(first + order[i + (1 if flipped else 2)])
		var data = []
		data.resize(Mesh.ARRAY_MAX)
		data[Mesh.ARRAY_VERTEX] = points
		data[Mesh.ARRAY_NORMAL] = normals
		data[Mesh.ARRAY_INDEX] = indices
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		return mesh)

# -------------------------------------------------------------- characters ---

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "player_accent")
	var armed: bool = look.get("weapon", true)
	match kind:
		"player": _hero(rig, tone, accent, armed)
		"bot": _windup(rig, tone, accent, armed)
		"runner": _scout(rig, tone, accent)
		"tank": _brute(rig, tone, accent, armed)
		"boss": _titan(rig, tone, accent, armed)
		_: _goon(rig, tone, accent, armed)

func _part(rig: CharacterRig, part: String, key: String, pieces: Callable, at: Vector3, tone: String, euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return rig.add_part(part, fuse(key, pieces), at, tone, "character", euler)

# Rigid detail glued to a part (faces, plates, trim); comes along when it moves.
func _detail(parent: Node3D, key: String, pieces: Callable, tone: String, role: String = "character") -> MeshInstance3D:
	return add(parent, fuse(key, pieces), Vector3.ZERO, role, tone)

# A C-grip claw hand on a forearm; origin at the shoulder, built downward so the
# animator swings the whole arm about the shoulder. The right hand grips a gun.
func _arm(rig: CharacterRig, tag: String, key: String, at: Vector3, length: float, girth: float, tone: String) -> void:
	_part(rig, "hand_" + tag, key, func(): return [
		slab(Vector3(0, -length * 0.5, 0), Vector3(girth, length, girth)),
		ring(Vector3(0, -length - girth * 0.2, -girth * 0.1), girth * 0.42, girth * 0.16, X90)], at, tone)

# Boxy leg + foot; origin at the hip, built downward so it swings about the hip.
func _leg(rig: CharacterRig, tag: String, key: String, at: Vector3, length: float, girth: float, tone: String, footKey: String) -> void:
	var node = _part(rig, "foot_" + tag, key, func(): return [
		slab(Vector3(0, -length * 0.5, 0), Vector3(girth, length, girth))], at, tone)
	_detail(node, key + "_foot", func(): return [
		slab(Vector3(0, -length, girth * 0.2), Vector3(girth * 1.1, girth * 0.7, girth * 1.5)),
		stud(Vector3(0, -length + girth * 0.35, girth * 0.2))], footKey)

# Stud-topped cylinder head with a printed visor band; `plate` is the brow/eyes.
func _head(rig: CharacterRig, at: Vector3, radius: float, height: float, tone: String, visor: String) -> MeshInstance3D:
	var head = _part(rig, "head", "head%f/%f" % [radius, height], func(): return [
		tube(Vector3.ZERO, radius, height),
		stud(Vector3(0, height * 0.5, 0))], at, tone)
	_detail(head, "visor%f" % radius, func(): return [
		tube(Vector3(0, 0.02, -radius * 0.78), radius * 0.62, radius * 0.5, X90, -1.0, Vector3(1.4, 1.0, 1.0))], visor, "character")
	_detail(head, "eyes%f" % radius, func(): return [
		ball(Vector3(-radius * 0.4, 0.04, -radius * 0.92), radius * 0.22),
		ball(Vector3(radius * 0.4, 0.04, -radius * 0.92), radius * 0.22)], "flash")
	return head

# The brick blaster: a stud-barrel pointing -Z with a boxy receiver and grip.
# The right hand holds it, so the weapon view shows barrel + claw bottom-right.
func _blaster(rig: CharacterRig, at: Vector3, size: float, trim: String, ammo: String) -> void:
	var gun = rig.add_part("weapon", fuse("blaster%f" % size, func(): return [
		slab(Vector3(0, 0, -0.1 * size), Vector3(0.22, 0.2, 0.5) * size),       # receiver
		slab(Vector3(0, -0.22 * size, 0.08 * size), Vector3(0.16, 0.26, 0.18) * size, Vector3(0.25, 0, 0)),  # grip
		tube(Vector3(0, 0.02 * size, -0.45 * size), 0.07 * size, 0.42 * size, X90)]), at, "weapon", "weapon")
	gun.scale = Vector3.ONE * size
	# Barrel muzzle stud, a sight stud on top and a loaded pellet.
	_detail(gun, "blaster_trim%f" % size, func(): return [
		tube(Vector3(0, 0.02, -0.68), 0.1, 0.1, X90),
		stud(Vector3(0, 0.12, -0.05)),
		slab(Vector3(0, 0.12, 0.18), Vector3(0.1, 0.1, 0.14))], trim, "weapon")
	_detail(gun, "blaster_bolt%f" % size, func(): return [
		tube(Vector3(0, 0.02, -0.72), 0.055, 0.12, X90)], ammo, "weapon")

# Classic minifig hero: blue brick body, yellow chest plate, visor face.
func _hero(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "hero_body", func(): return [
		slab(Vector3(0, 0.78, 0), Vector3(0.6, 0.56, 0.4)),
		slab(Vector3(0, 0.52, 0), Vector3(0.5, 0.18, 0.4)),
		slab(Vector3(0, 1.06, 0), Vector3(0.24, 0.1, 0.24))] + studs_arr(Vector3(0.5, 0, 0.4), 1.1), Vector3.ZERO, tone)
	_detail(body, "hero_chest", func(): return [
		slab(Vector3(0, 0.82, -0.205), Vector3(0.42, 0.34, 0.03))], accent)
	_detail(body, "hero_studs", func(): return studs_arr(Vector3(0.5, 0, 0.4), 1.06), "character")
	_head(rig, Vector3(0, 1.3, 0), 0.2, 0.34, tone, "ink")
	_detail(rig.parts["head"], "hero_hair", func(): return [
		slab(Vector3(0, 0.22, 0.02), Vector3(0.44, 0.14, 0.46))], accent)
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		_arm(rig, tag, "hero_arm", Vector3(side * 0.33, 0.96, 0), 0.4, 0.16, tone)
		_leg(rig, tag, "hero_leg", Vector3(side * 0.14, 0.5, 0), 0.5, 0.2, accent, tone)
	if armed:
		rig.parts["hand_r"].position = Vector3(0.36, 0.98, -0.08)
		_blaster(rig, Vector3(0.4, 0.74, -0.34), 1.0, "player_accent", "bullet_player")

# Wind-up brick-bot: short two-brick body, single-eye visor, antenna, back key.
func _windup(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "bot_body", func(): return [
		tube(Vector3(0, 0.74, 0), 0.32, 0.5),
		slab(Vector3(0, 0.46, 0), Vector3(0.42, 0.16, 0.42)),
		stud(Vector3(0, 1.0, 0), 0.16)], Vector3.ZERO, tone)
	_detail(body, "bot_belt", func(): return [
		ring(Vector3(0, 0.6, 0), 0.32, 0.05)], accent)
	_part(rig, "key_back", "bot_key", func(): return [
		tube(Vector3(0, 0, 0.1), 0.03, 0.2, X90),
		ring(Vector3(-0.1, 0, 0.22), 0.08, 0.03, X90),
		ring(Vector3(0.1, 0, 0.22), 0.08, 0.03, X90)], Vector3(0, 0.78, 0.3), accent)
	var head = _part(rig, "head", "bot_head", func(): return [
		slab(Vector3(0, 0, 0), Vector3(0.4, 0.34, 0.38)),
		stud(Vector3(0, 0.17, 0), 0.1)], Vector3(0, 1.22, 0), tone)
	_detail(head, "bot_visor", func(): return [
		slab(Vector3(0, 0.02, -0.2), Vector3(0.3, 0.16, 0.04))], "ink")
	_detail(head, "bot_eye", func(): return [
		tube(Vector3(0, 0.02, -0.22), 0.06, 0.04, X90)], "bullet_enemy")
	_part(rig, "antenna", "bot_antenna", func(): return [
		tube(Vector3(0, 0.1, 0), 0.02, 0.2),
		stud(Vector3(0, 0.2, 0), 0.05)], Vector3(0, 1.4, 0.08), accent)
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		_arm(rig, tag, "bot_arm", Vector3(side * 0.3, 0.86, 0), 0.34, 0.13, accent)
		_leg(rig, tag, "bot_leg", Vector3(side * 0.14, 0.46, 0), 0.46, 0.17, tone, accent)
	if armed:
		rig.parts["hand_r"].position = Vector3(0.32, 0.88, -0.08)
		_blaster(rig, Vector3(0.36, 0.66, -0.32), 0.85, "flash", "bullet_enemy")

# Brick goon: stock grunt, chunky torso, blaster. The skirmish default.
func _goon(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "goon_body", func(): return [
		slab(Vector3(0, 0.78, 0), Vector3(0.64, 0.58, 0.44)),
		slab(Vector3(0, 0.5, 0), Vector3(0.52, 0.2, 0.44)),
		slab(Vector3(0, 1.08, 0), Vector3(0.24, 0.1, 0.24))], Vector3.ZERO, tone)
	_detail(body, "goon_studs", func(): return studs_arr(Vector3(0.54, 0, 0.44), 1.08), "character")
	_detail(body, "goon_belt", func(): return [
		slab(Vector3(0, 0.6, 0), Vector3(0.66, 0.1, 0.46))], "ink")
	_head(rig, Vector3(0, 1.32, 0), 0.21, 0.34, tone, "ink")
	_detail(rig.parts["head"], "goon_cap", func(): return [
		slab(Vector3(0, 0.22, 0), Vector3(0.46, 0.12, 0.48)),
		slab(Vector3(0, 0.18, -0.3), Vector3(0.4, 0.06, 0.18))], accent)
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		_arm(rig, tag, "goon_arm", Vector3(side * 0.35, 0.98, 0), 0.42, 0.17, tone)
		_leg(rig, tag, "goon_leg", Vector3(side * 0.15, 0.5, 0), 0.5, 0.21, "ink", tone)
	if armed:
		rig.parts["hand_r"].position = Vector3(0.38, 1.0, -0.08)
		_blaster(rig, Vector3(0.42, 0.76, -0.34), 1.0, accent, "bullet_enemy")

# Scout runner: lean, forward-tilted single brick on long legs, big visor, claws
# out front. No weapon (melee).
func _scout(rig: CharacterRig, tone: String, accent: String) -> void:
	var body = _part(rig, "body", "scout_body", func(): return [
		slab(Vector3(0, 0.76, -0.04), Vector3(0.44, 0.6, 0.4), Vector3(0.35, 0, 0)),
		stud(Vector3(0, 1.04, -0.22), 0.1)], Vector3.ZERO, tone)
	_detail(body, "scout_fin", func(): return [
		slab(Vector3(0, 0.86, 0.18), Vector3(0.1, 0.4, 0.22), Vector3(0.5, 0, 0))], accent)
	var head = _part(rig, "head", "scout_head", func(): return [
		slab(Vector3(0, 0, 0), Vector3(0.38, 0.3, 0.42)),
		stud(Vector3(0, 0.15, 0), 0.09)], Vector3(0, 1.24, -0.16), tone)
	_detail(head, "scout_visor", func(): return [
		slab(Vector3(0, 0, -0.22), Vector3(0.34, 0.2, 0.05))], accent)
	_detail(head, "scout_eye", func(): return [
		slab(Vector3(0, 0, -0.25), Vector3(0.22, 0.06, 0.03))], "bullet_enemy")
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		# Claws reach forward: this is what the runner hits with.
		_part(rig, "hand_" + tag, "scout_claw", func(): return [
			slab(Vector3(0, 0, -0.18), Vector3(0.1, 0.1, 0.36)),
			ball(Vector3(0, 0, -0.38), 0.12),
			tube(Vector3(0.04, 0.02, -0.46), 0.03, 0.14, Vector3(-PI * 0.5, 0, 0), 0.0),
			tube(Vector3(-0.04, 0.02, -0.46), 0.03, 0.14, Vector3(-PI * 0.5, 0, 0), 0.0)], Vector3(side * 0.26, 0.82, -0.2), accent)
		_leg(rig, tag, "scout_leg", Vector3(side * 0.13, 0.56, 0.04), 0.58, 0.14, accent, tone)

# Brick brute tank: wide double-stud torso, huge fists, stubby legs, big cannon.
func _brute(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "brute_body", func(): return [
		slab(Vector3(0, 0.74, 0), Vector3(0.95, 0.66, 0.6)),
		slab(Vector3(0, 0.42, 0), Vector3(0.8, 0.22, 0.56)),
		slab(Vector3(0, 1.07, 0), Vector3(0.3, 0.1, 0.3))], Vector3.ZERO, tone)
	_detail(body, "brute_studs", func(): return studs_arr(Vector3(0.9, 0, 0.6), 1.07, 0.15), "character")
	_detail(body, "brute_plate", func(): return [
		slab(Vector3(0, 0.8, -0.31), Vector3(0.7, 0.4, 0.03)),
		slab(Vector3(0, 0.5, 0), Vector3(0.96, 0.1, 0.58))], accent)
	_head(rig, Vector3(0, 1.3, 0), 0.24, 0.3, tone, "ink")
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		# Oversized block fists.
		_part(rig, "hand_" + tag, "brute_fist", func(): return [
			slab(Vector3(0, -0.34, 0), Vector3(0.2, 0.5, 0.2)),
			slab(Vector3(0, -0.6, -0.02), Vector3(0.34, 0.3, 0.34)),
			stud(Vector3(0, -0.44, 0), 0.07)], Vector3(side * 0.52, 1.0, 0), tone)
		_leg(rig, tag, "brute_leg", Vector3(side * 0.22, 0.42, 0), 0.42, 0.28, "ink", tone)
	if armed:
		rig.parts["hand_r"].position = Vector3(0.56, 1.02, -0.1)
		_blaster(rig, Vector3(0.6, 0.6, -0.34), 1.5, accent, "bullet_enemy")

# Brick titan boss: a tower of stacked bricks, broad shoulders, a crown of
# studs, twin claw arms and a heavy twin-barrel cannon.
func _titan(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", "titan_body", func(): return [
		slab(Vector3(0, 0.5, 0), Vector3(0.78, 0.4, 0.6)),
		slab(Vector3(0, 0.86, 0), Vector3(0.96, 0.36, 0.64)),
		slab(Vector3(0, 1.16, 0), Vector3(0.72, 0.28, 0.5)),
		slab(Vector3(0, 1.36, 0), Vector3(0.34, 0.12, 0.34))], Vector3.ZERO, tone)
	_detail(body, "titan_shoulders", func(): return [
		slab(Vector3(-0.52, 1.0, 0), Vector3(0.24, 0.26, 0.58)),
		slab(Vector3(0.52, 1.0, 0), Vector3(0.24, 0.26, 0.58))], accent)
	_detail(body, "titan_plate", func(): return [
		slab(Vector3(0, 0.88, -0.33), Vector3(0.6, 0.5, 0.03)),
		slab(Vector3(0, 0.5, 0), Vector3(0.8, 0.12, 0.62))], accent)
	_detail(body, "titan_studs", func(): return studs_arr(Vector3(0.7, 0, 0.5), 1.5, 0.15), "character")
	var head = _head(rig, Vector3(0, 1.62, 0), 0.26, 0.32, tone, "ink")
	# Crown of studs around the head.
	var crown = func():
		var p = [ring(Vector3(0, 0.16, 0), 0.26, 0.05)]
		for i in 6:
			var a = TAU * i / 6.0
			p.append(stud(Vector3(sin(a) * 0.26, 0.18, cos(a) * 0.26), 0.07, 0.12))
		return p
	_detail(head, "titan_crown", crown, accent)
	for side in SIDES:
		var tag = "l" if side < 0 else "r"
		_part(rig, "hand_" + tag, "titan_arm", func(): return [
			slab(Vector3(0, -0.4, 0), Vector3(0.24, 0.7, 0.24)),
			slab(Vector3(0, -0.84, -0.04), Vector3(0.32, 0.28, 0.4)),
			ring(Vector3(0, -0.98, -0.18), 0.14, 0.05, X90)], Vector3(side * 0.62, 1.34, 0), tone)
		_leg(rig, tag, "titan_leg", Vector3(side * 0.26, 0.5, 0), 0.5, 0.32, "ink", accent)
	if armed:
		rig.parts["hand_r"].position = Vector3(0.66, 1.36, -0.12)
		_blaster(rig, Vector3(0.72, 0.86, -0.4), 1.7, accent, "bullet_enemy")
		# Second barrel on the heavy cannon.
		_detail(rig.parts["weapon"], "titan_barrel", func(): return [
			tube(Vector3(0, -0.14, -0.45), 0.07, 0.42, X90),
			tube(Vector3(0, -0.14, -0.68), 0.1, 0.1, X90)], "weapon", "weapon")

# ------------------------------------------------------------------ blocks ---

## Walls and props as courses of studded bricks and plates. Box shapes stack
## bricks; cylinder shapes become round brick tubes. The look is deterministic
## in the block's position, so the same layout always reads the same.
func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	if shape == "cylinder":
		_round_stack(holder, extent, role, color_key)
		return
	# Model along X and turn the whole thing when the block runs along Z.
	var turned = extent.z > extent.x
	var size = Vector3(extent.z, extent.y, extent.x) if turned else extent
	var euler = Vector3(0, PI * 0.5, 0) if turned else Vector3.ZERO
	if role == "wall":
		_brick_wall(holder, size, euler, color_key)
	else:
		_plate_stack(holder, size, euler, color_key)

# A running-bond brick wall fused into one mesh, studs along the top course.
func _brick_wall(holder: Node3D, size: Vector3, euler: Vector3, color_key: String) -> void:
	var courses = maxi(1, roundi(size.y / 0.5))
	var tall = size.y / courses
	var across = maxi(1, roundi(size.x / 1.0))
	var wide = size.x / across
	add(holder, fuse("wall%s/%d/%d" % [size, courses, across], func():
		var p: Array = []
		for row in courses:
			var odd = row % 2 == 1
			var n = across + (1 if odd else 0)
			for i in n:
				var w = wide * (0.5 if odd and (i == 0 or i == across) else 1.0)
				var offset = -size.x * 0.5 + wide * (i + 0.5)
				if odd:
					offset = -size.x * 0.5 + (wide * 0.25 if i == 0 else size.x - wide * 0.25 if i == across else wide * i)
				p.append(slab(Vector3(offset, tall * (row + 0.5), 0), Vector3(w - 0.03, tall - 0.02, size.z - 0.03)))
		return p), Vector3.ZERO, "wall", color_key, euler)
	# Studs along the crown so walls read as stacked brick, not a plain box.
	add(holder, fuse("wall_studs%s/%d" % [size, across], func():
		var p: Array = []
		studs(p, Vector3(size.x - 0.1, 0, size.z - 0.1), size.y, 0.14)
		return p), Vector3.ZERO, "wall", "prop" if color_key != "prop" else "wall", euler)

# A low prop built from a couple of stacked plates with a stud top.
func _plate_stack(holder: Node3D, size: Vector3, euler: Vector3, color_key: String) -> void:
	var layers = maxi(1, roundi(size.y / 0.45))
	var tall = size.y / layers
	add(holder, fuse("plate%s/%d" % [size, layers], func():
		var p: Array = []
		for layer in layers:
			var shrink = 0.04 * layer
			p.append(slab(Vector3(0, tall * (layer + 0.5), 0), Vector3(size.x - shrink, tall - 0.02, size.z - shrink)))
		studs(p, Vector3(size.x - 0.1, 0, size.z - 0.1), size.y, 0.14)
		return p), Vector3.ZERO, "prop", color_key, euler)

# Cylinder blocks: a stack of round brick rings (walls) or a studded round brick
# / tube (props), sized to the footprint.
func _round_stack(holder: Node3D, extent: Vector3, role: String, color_key: String) -> void:
	var radius = extent.x * 0.5
	var courses = maxi(1, roundi(extent.y / 0.55))
	var tall = extent.y / courses
	add(holder, fuse("round%f/%f/%d" % [radius, extent.y, courses], func():
		var p: Array = []
		for row in courses:
			p.append(tube(Vector3(0, tall * (row + 0.5), 0), radius - 0.03 - 0.01 * (row % 2), tall - 0.02, Vector3.ZERO, -1.0, Vector3.ONE))
		return p), Vector3.ZERO, role, color_key)
	# A ring of studs around the top edge.
	add(holder, fuse("round_studs%f/%f" % [radius, extent.y], func():
		var p: Array = []
		var n = maxi(4, roundi(radius / 0.22))
		for i in n:
			var a = TAU * i / n
			p.append(stud(Vector3(sin(a) * (radius - 0.16), extent.y, cos(a) * (radius - 0.16)), 0.13))
		return p), Vector3.ZERO, role, "prop" if color_key != "prop" else "wall")

# ------------------------------------------------------------------ border ---

## The arena boundary: a brick kerb wall running the whole perimeter, fused into
## a single mesh so the four runs stay cheap.
func border(holder: Node3D, extent: Vector3) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var courses = maxi(1, roundi(extent.y / 0.5))
	var tall = extent.y / courses
	var count = maxi(1, roundi(length / 1.1))
	var wide = length / count
	var euler = Vector3.ZERO if along_x else Vector3(0, PI * 0.5, 0)
	add(holder, fuse("border%f/%f/%d/%d" % [length, extent.y, courses, count], func():
		var p: Array = []
		for row in courses:
			var shift = wide * 0.5 if row % 2 == 1 else 0.0
			var n = count + (1 if row % 2 == 1 else 0)
			for i in n:
				var offset = clampf(-length * 0.5 + wide * (i + 0.5) - shift, -length * 0.5 + wide * 0.25, length * 0.5 - wide * 0.25)
				p.append(slab(Vector3(offset, tall * (row + 0.5), 0), Vector3(wide - 0.03, tall - 0.02, minf(extent.z, extent.x) - 0.03 if along_x else extent.x - 0.03)))
		return p), Vector3.ZERO, "wall", "wall", euler)
	# One row of studs along the top of the kerb.
	add(holder, fuse("border_studs%f/%f" % [length, extent.y], func():
		var p: Array = []
		var n = maxi(1, roundi(length / 0.34))
		var band = (minf(extent.z, extent.x) if along_x else extent.x) - 0.12
		var rows = maxi(1, roundi(band / 0.34))
		for i in n:
			for j in rows:
				p.append(stud(Vector3(-length * 0.5 + (i + 0.5) * length / n, extent.y, (j - (rows - 1) * 0.5) * 0.3), 0.12))
		return p), Vector3.ZERO, "wall", "prop", euler)

# ------------------------------------------------------------------ pickup ---

## Health is a red heart-stud tile; weapons are little brick ammo packs, each a
## distinct silhouette: a scatter of round studs, a long ratchet brick, a fat
## launcher block.
func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			add(holder, fuse("heart_tile", func(): return [
				slab(Vector3(0, -0.14, 0), Vector3(0.5, 0.12, 0.5))]), Vector3.ZERO, "pickup", "pickup_ammo")
			add(holder, fuse("heart", func(): return [
				tube(Vector3(-0.11, 0, 0), 0.11, 0.12),
				tube(Vector3(0.11, 0, 0), 0.11, 0.12),
				slab(Vector3(0, -0.12, 0), Vector3(0.3, 0.12, 0.22), Vector3(0, PI * 0.25, 0)),
				slab(Vector3(0, -0.12, 0), Vector3(0.3, 0.12, 0.22), Vector3(0, -PI * 0.25, 0))]), Vector3.ZERO, "pickup", "pickup_health")
		"scatter":
			add(holder, fuse("scatter_tile", func(): return [
				slab(Vector3(0, -0.16, 0), Vector3(0.5, 0.1, 0.5))]), Vector3.ZERO, "pickup", "weapon")
			add(holder, fuse("scatter_studs", func():
				var p: Array = []
				for i in 5:
					var a = TAU * i / 5.0
					p.append(stud(Vector3(sin(a) * 0.17, -0.1 + (0.0 if i % 2 == 0 else 0.1), cos(a) * 0.17), 0.1, 0.16))
				p.append(stud(Vector3(0, -0.1, 0), 0.1, 0.2))
				return p), Vector3.ZERO, "pickup", "pickup_ammo")
		"rapid":
			add(holder, fuse("rapid_brick", func():
				var p = [slab(Vector3(0, -0.08, 0), Vector3(0.6, 0.2, 0.26))]
				for i in 4:
					p.append(stud(Vector3(-0.21 + i * 0.14, 0.02, 0), 0.08, 0.1))
				return p), Vector3.ZERO, "pickup", "pickup_ammo")
			add(holder, fuse("rapid_grip", func(): return [
				slab(Vector3(0, -0.24, 0.0), Vector3(0.14, 0.2, 0.2))]), Vector3.ZERO, "pickup", "weapon")
		_:
			add(holder, fuse("launcher_brick", func(): return [
				slab(Vector3(0, -0.06, 0), Vector3(0.44, 0.34, 0.4)),
				stud(Vector3(-0.1, 0.12, 0.1), 0.1, 0.12),
				stud(Vector3(0.1, 0.12, 0.1), 0.1, 0.12),
				tube(Vector3(0, 0.0, -0.28), 0.12, 0.2, X90)]), Vector3.ZERO, "pickup", "weapon")
			add(holder, fuse("launcher_mouth", func(): return [
				tube(Vector3(0, 0, -0.34), 0.14, 0.08, X90)]), Vector3.ZERO, "pickup", "pickup_ammo")

## A round brick pellet: a stud-shaped cylinder flying nose-first along -Z.
func bullet_mesh() -> Mesh:
	return fuse("pellet", func(): return [
		[cylinder(0.4, 1.0, -1.0, 12), _x(Vector3.ZERO, Vector3.ONE, X90)],
		stud(Vector3(0, 0, -0.5), 0.22)])

# ----------------------------------------------------------------- scenery ---

## A toybox around the playfield: a baseplate horizon, brick towers in the
## corners, a few giant loose bricks and an open toy box. Everything is kept
## beyond the walls (size / 2 + 1.5) and fused to stay well under 80 draws.
func decorate(holder: Node3D, arena: Arena) -> void:
	var half = Vector3(arena.size.x * 0.5, 0, arena.size.y * 0.5)
	var salt = arena.size.x * 3.1 + arena.size.y * 1.7
	# Baseplate the whole set sits on, with a stud lip you glimpse past the wall.
	add(holder, box(Vector3(arena.size.x + 60.0, 0.4, arena.size.y + 50.0)), Vector3(0, -0.4, 0), "prop", "floor_alt")
	# Brick towers of different heights behind each wall.
	var hues = ["wall", "prop", "player", "runner", "tank", "bot"]
	var towers = [Vector3(-half.x - 5.0, 0, -half.z - 6.0), Vector3(half.x * 0.2, 0, -half.z - 7.0), Vector3(half.x + 6.0, 0, -half.z - 4.0),
		Vector3(half.x + 5.5, 0, half.z * 0.2), Vector3(-half.x - 6.0, 0, half.z * 0.3), Vector3(-half.x * 0.3, 0, half.z + 6.0)]
	for i in towers.size():
		_tower(holder, towers[i], 6.0 + _noise(salt + i) * 3.0 + i, hues[i % hues.size()], hues[(i + 2) % hues.size()])
	# Giant loose bricks scattered outside the sides.
	var bricks = [Vector3(-half.x - 10.0, 0, -half.z * 0.3), Vector3(half.x + 11.0, 0, half.z * 0.5), Vector3(-half.x - 9.0, 0, half.z * 0.8), Vector3(half.x + 9.0, 0, -half.z * 0.7)]
	var brick_hues = ["prop", "player", "runner", "wall"]
	for i in bricks.size():
		_loose(holder, bricks[i], brick_hues[i], 2 + i % 3, 2, _noise(salt + i * 2.0))
	# An open toy box tipped behind the far corner, spilling a couple of bricks.
	var box_at = Vector3(-half.x - 11.0, 0, -half.z - 10.0)
	add(holder, fuse("toybox", func(): return [
		slab(Vector3(0, 2.0, -3.0), Vector3(8.0, 4.0, 0.5)),
		slab(Vector3(-4.0, 2.0, 0), Vector3(0.5, 4.0, 6.0)),
		slab(Vector3(4.0, 2.0, 0), Vector3(0.5, 4.0, 6.0)),
		slab(Vector3(0, 0.25, 0), Vector3(8.0, 0.5, 6.0))]), box_at, "prop", "wall")
	add(holder, fuse("toybox_lid", func(): return [
		slab(Vector3(0, 0, 0), Vector3(8.0, 0.5, 6.0))]), box_at + Vector3(2.0, 4.0, 4.0), "prop", "player", Vector3(0.3, 0.4, 0))
	_loose(holder, box_at + Vector3(2.0, 0, 5.5), "prop", 2, 2, 0.4)

# A stacked brick tower of `height` metres in two alternating colours.
func _tower(holder: Node3D, at: Vector3, height: float, a: String, b: String) -> void:
	var courses = maxi(2, roundi(height / 1.2))
	var tall = height / courses
	var wide = 3.4
	for row in courses:
		add(holder, fuse("towerbrick%f" % tall, func():
			var p = [slab(Vector3(0, tall * 0.5, 0), Vector3(wide, tall, wide))]
			studs(p, Vector3(wide, 0, wide), tall, 0.28)
			return p), at + Vector3(0, tall * row, 0), "prop", a if row % 2 == 0 else b, Vector3(0, _noise(at.x + row) * 0.3, 0))

# One oversized loose brick, `nx` by `nz` studs, lying on the baseplate.
func _loose(holder: Node3D, at: Vector3, color_key: String, nx: int, nz: int, spin: float) -> void:
	var w = nx * 1.4
	var d = nz * 1.4
	add(holder, fuse("loose%d/%d" % [nx, nz], func():
		var p = [slab(Vector3(0, 0.7, 0), Vector3(w, 1.4, d))]
		for i in nx:
			for j in nz:
				p.append(stud(Vector3((i - (nx - 1) * 0.5) * 1.4, 1.4, (j - (nz - 1) * 0.5) * 1.4), 0.42, 0.35))
		return p), at, "prop", color_key, Vector3(0, spin, 0))

# Blocks vary by where they stand; the same layout always looks the same.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
