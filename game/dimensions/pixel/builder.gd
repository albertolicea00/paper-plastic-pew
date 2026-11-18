extends DimensionBuilder
## Pixel Art shapes: blocky "voxel-sprite" figures, walls, props and scenery
## built almost entirely from cubes and stepped boxes, so everything reads as a
## chunky 3D pixel sprite. Characters stack boxes into a classic 8/16-bit cast;
## blocks are brick/crate/barrel tiles; scenery is a tiled retro backdrop of
## trees, clouds, a big pixel sun and a score marquee. Part names matter to
## animator.gd: the word before the first "_" picks how an extra part rides and
## reacts (visor, eye, ear, cap, horn, crown, antenna, shoulder, pack, fin).

const SIDES = [-1.0, 1.0]
const X90 = Vector3(PI * 0.5, 0, 0)

# ----------------------------------------------------------------- pieces -----

func _tag(side: float) -> String:
	return "l" if side < 0 else "r"

# A cube part on the rig; the main named joints of a figure.
func _part(rig: CharacterRig, part: String, size: Vector3, at: Vector3, key: String, euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return rig.add_part(part, box(size), at, key, "character", euler)

# A cube glued to a part (face pixels, trim); it rides when the part moves.
func _glue(parent: Node3D, size: Vector3, at: Vector3, key: String, euler: Vector3 = Vector3.ZERO, role: String = "character") -> MeshInstance3D:
	return add(parent, box(size), at, role, key, euler)

# Merge several [mesh, transform] pieces into one cached ArrayMesh, so a bullet
# or a heart is a single draw even though it is a cluster of cubes.
func merge(key: String, pieces: Callable) -> Mesh:
	return shared("merge:" + key, func():
		var verts = PackedVector3Array()
		var norms = PackedVector3Array()
		var index = PackedInt32Array()
		for piece in pieces.call():
			var src: Mesh = piece[0]
			var xf: Transform3D = piece[1]
			var arr: Array = src.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var o: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var basis = xf.basis.inverse().transposed()
			var first = verts.size()
			for i in v.size():
				verts.append(xf * v[i])
				norms.append((basis * n[i]).normalized())
			for i in o.size():
				index.append(first + o[i])
		var data = []
		data.resize(Mesh.ARRAY_MAX)
		data[Mesh.ARRAY_VERTEX] = verts
		data[Mesh.ARRAY_NORMAL] = norms
		data[Mesh.ARRAY_INDEX] = index
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		return mesh)

func cube(at: Vector3, size: Vector3) -> Array:
	return [box(size), Transform3D(Basis(), at)]

# ------------------------------------------------------------- characters -----

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "player_accent")
	var armed: bool = look.get("weapon", true)
	match kind:
		"player": _hero(rig, tone, accent, armed)
		"bot": _droid(rig, tone, accent, armed)
		"runner": _imp(rig, tone, accent)
		"tank": _brute(rig, tone, accent, armed)
		"boss": _titan(rig, tone, accent, armed)
		_: _grunt(rig, tone, accent, armed)

# The retro ray gun: a chunky arm cannon pointing -Z from the right hand, with
# a glowing muzzle bolt. Sized up for heavies. The weapon view shows only this
# and hand_r, so it is built to read big bottom-right.
func _raygun(rig: CharacterRig, at: Vector3, size: float, trim: String, ammo: String) -> void:
	var gun = rig.add_part("weapon", box(Vector3(0.2, 0.22, 0.56) * size), at, "weapon", "weapon")
	# Fat barrel, a top sight block, an under-grip and a glowing muzzle pixel.
	_glue(gun, Vector3(0.14, 0.14, 0.42) * size, Vector3(0, 0.02, -0.42) * size, "weapon", Vector3.ZERO, "weapon")
	_glue(gun, Vector3(0.1, 0.1, 0.16) * size, Vector3(0, 0.16, -0.12) * size, trim, Vector3.ZERO, "weapon")
	_glue(gun, Vector3(0.14, 0.2, 0.16) * size, Vector3(0, -0.2, 0.1) * size, "weapon", Vector3.ZERO, "weapon")
	_glue(gun, Vector3(0.2, 0.2, 0.1) * size, Vector3(0, 0.02, -0.62) * size, ammo, Vector3.ZERO, "pickup")

# Classic hero sprite: square head with a visor, a short cap, boxy torso with a
# chest plate, stubby arms and legs, ray gun.
func _hero(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", Vector3(0.62, 0.62, 0.42), Vector3(0, 0.74, 0), tone)
	_glue(body, Vector3(0.44, 0.3, 0.04), Vector3(0, 0.78, -0.22), accent)       # chest plate
	_glue(body, Vector3(0.64, 0.12, 0.44), Vector3(0, 0.46, 0), "ink")            # belt
	var head = _part(rig, "head", Vector3(0.5, 0.46, 0.46), Vector3(0, 1.33, 0), tone)
	_glue(head, Vector3(0.54, 0.16, 0.5), Vector3(0, 0.26, 0.02), accent)         # cap
	_glue(head, Vector3(0.44, 0.14, 0.04), Vector3(0, 0.02, -0.24), "ink")        # visor band
	_eyes(head, 0.13, 0.08, -0.25, 0.04)
	for side in SIDES:
		var t = _tag(side)
		_part(rig, "hand_" + t, Vector3(0.18, 0.5, 0.2), Vector3(side * 0.42, 0.86, -0.04), tone)
		_part(rig, "foot_" + t, Vector3(0.22, 0.34, 0.3), Vector3(side * 0.17, 0.17, -0.02), "ink")
	if armed:
		rig.parts["hand_r"].position = Vector3(0.42, 0.9, -0.1)
		_raygun(rig, Vector3(0.44, 0.78, -0.42), 1.0, accent, "bullet_player")

# Skirmish droid: a boxy robot, single round eye, antenna, shoulder tabs. A
# clear read apart from the hero from every angle.
func _droid(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", Vector3(0.56, 0.6, 0.44), Vector3(0, 0.72, 0), tone)
	_glue(body, Vector3(0.6, 0.14, 0.48), Vector3(0, 0.82, 0), accent)            # collar
	for side in SIDES:
		_glue(body, Vector3(0.16, 0.18, 0.46), Vector3(side * 0.36, 0.86, 0), accent)  # shoulder_tab
	var head = _part(rig, "head", Vector3(0.44, 0.4, 0.42), Vector3(0, 1.28, 0), tone)
	_glue(head, Vector3(0.32, 0.16, 0.04), Vector3(0, 0.0, -0.23), "ink")         # visor slot
	_glue(head, Vector3(0.12, 0.12, 0.06), Vector3(0, 0.0, -0.25), "bullet_enemy")  # single eye
	_part(rig, "antenna_top", Vector3(0.06, 0.26, 0.06), Vector3(0, 1.62, 0), accent)
	_glue(rig.parts["antenna_top"], Vector3(0.12, 0.12, 0.12), Vector3(0, 0.16, 0), "bullet_enemy")
	for side in SIDES:
		var t = _tag(side)
		_part(rig, "hand_" + t, Vector3(0.16, 0.44, 0.18), Vector3(side * 0.38, 0.84, -0.04), accent)
		_part(rig, "foot_" + t, Vector3(0.2, 0.3, 0.28), Vector3(side * 0.16, 0.15, 0), "ink")
	if armed:
		rig.parts["hand_r"].position = Vector3(0.38, 0.86, -0.1)
		_raygun(rig, Vector3(0.4, 0.76, -0.4), 0.9, "flash", "bullet_enemy")

# Grunt: a squat goomba/slime block, wide and low, big angry eyes, little feet.
# The skirmish and survival default.
func _grunt(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", Vector3(0.7, 0.56, 0.5), Vector3(0, 0.6, 0), tone)
	_glue(body, Vector3(0.5, 0.14, 0.52), Vector3(0, 0.3, 0), "ink")              # mouth line
	var head = _part(rig, "head", Vector3(0.62, 0.32, 0.46), Vector3(0, 1.06, 0), tone)
	_glue(head, Vector3(0.14, 0.18, 0.04), Vector3(-0.15, 0.04, -0.24), "ink")    # angry brow_l
	_glue(head, Vector3(0.14, 0.18, 0.04), Vector3(0.15, 0.04, -0.24), "ink")     # angry brow_r
	_eyes(head, 0.15, 0.1, -0.25, -0.02)
	_glue(head, Vector3(0.18, 0.1, 0.2), Vector3(0, 0.18, 0.02), accent)          # little tuft
	for side in SIDES:
		var t = _tag(side)
		_part(rig, "hand_" + t, Vector3(0.2, 0.26, 0.2), Vector3(side * 0.46, 0.66, -0.02), tone)
		_part(rig, "foot_" + t, Vector3(0.24, 0.2, 0.3), Vector3(side * 0.2, 0.1, 0), "ink")
	if armed:
		rig.parts["hand_r"].position = Vector3(0.46, 0.66, -0.08)
		_raygun(rig, Vector3(0.48, 0.58, -0.38), 0.95, accent, "bullet_enemy")

# Runner: a lean, forward-tilted bat/imp on long legs, pointy ears and claws out
# front (what it hits with). No weapon.
func _imp(rig: CharacterRig, tone: String, accent: String) -> void:
	var body = _part(rig, "body", Vector3(0.4, 0.58, 0.4), Vector3(0, 0.78, -0.04), tone, Vector3(0.35, 0, 0))
	_glue(body, Vector3(0.12, 0.44, 0.14), Vector3(0, 0.1, 0.22), accent, Vector3(0.5, 0, 0))  # fin spine
	var head = _part(rig, "head", Vector3(0.42, 0.36, 0.44), Vector3(0, 1.24, -0.18), tone)
	for side in SIDES:
		# Pointy ears, stepped from two cubes, read as a bat from above.
		_glue(head, Vector3(0.14, 0.2, 0.1), Vector3(side * 0.18, 0.24, 0.02), tone)
		_glue(head, Vector3(0.08, 0.12, 0.08), Vector3(side * 0.18, 0.4, 0.02), accent)
	_glue(head, Vector3(0.36, 0.1, 0.04), Vector3(0, 0.0, -0.24), "bullet_enemy")  # glowing eye slit
	for side in SIDES:
		var t = _tag(side)
		# Forward claws: a forearm box tipped with three stepped talons.
		var claw = _part(rig, "hand_" + t, Vector3(0.14, 0.14, 0.4), Vector3(side * 0.26, 0.86, -0.22), accent)
		for c in 3:
			_glue(claw, Vector3(0.04, 0.04, 0.16), Vector3((c - 1) * 0.06, 0, -0.26), "ink")
		_part(rig, "foot_" + t, Vector3(0.18, 0.46, 0.34), Vector3(side * 0.14, 0.23, 0.02), "ink")

# Tank: an armored brute, very wide, heavy shoulder blocks, a small visor head
# sunk between them, huge fists, a big arm cannon.
func _brute(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", Vector3(1.0, 0.68, 0.64), Vector3(0, 0.72, 0), tone)
	_glue(body, Vector3(0.72, 0.4, 0.04), Vector3(0, 0.8, -0.32), accent)         # chest plate
	_glue(body, Vector3(1.02, 0.14, 0.66), Vector3(0, 0.48, 0), "ink")           # belt
	for side in SIDES:
		_glue(body, Vector3(0.3, 0.32, 0.66), Vector3(side * 0.56, 1.0, 0), accent)  # shoulder_pad
	var head = _part(rig, "head", Vector3(0.42, 0.34, 0.42), Vector3(0, 1.28, 0), tone)
	_glue(head, Vector3(0.36, 0.1, 0.04), Vector3(0, 0.0, -0.23), "bullet_enemy")  # visor glow
	for side in SIDES:
		var t = _tag(side)
		_part(rig, "hand_" + t, Vector3(0.32, 0.38, 0.34), Vector3(side * 0.6, 0.64, -0.02), tone)
		_part(rig, "foot_" + t, Vector3(0.34, 0.26, 0.38), Vector3(side * 0.26, 0.13, 0), "ink")
	if armed:
		rig.parts["hand_r"].position = Vector3(0.62, 0.66, -0.08)
		_raygun(rig, Vector3(0.64, 0.56, -0.42), 1.45, accent, "bullet_enemy")

# Boss: a towering sprite, stacked stepped torso, broad shoulders, a crown of
# spikes, twin claw arms and a heavy twin-barrel cannon.
func _titan(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	var body = _part(rig, "body", Vector3(0.78, 0.44, 0.6), Vector3(0, 0.5, 0), tone)
	_glue(body, Vector3(0.98, 0.4, 0.66), Vector3(0, 0.9, 0), tone)               # upper torso step
	_glue(body, Vector3(0.68, 0.3, 0.52), Vector3(0, 1.22, 0), tone)              # chest step
	_glue(body, Vector3(0.74, 0.4, 0.04), Vector3(0, 0.92, -0.35), accent)        # chest plate
	for side in SIDES:
		_glue(body, Vector3(0.28, 0.3, 0.64), Vector3(side * 0.58, 1.0, 0), accent)  # shoulder_pad
	var head = _part(rig, "head", Vector3(0.5, 0.42, 0.46), Vector3(0, 1.6, 0), tone)
	_glue(head, Vector3(0.42, 0.12, 0.04), Vector3(0, 0.02, -0.24), "bullet_enemy")  # visor glow
	# A crown of stepped spikes around the head.
	for i in 5:
		var a = TAU * i / 5.0
		var out = Vector3(sin(a), 0, cos(a))
		_part(rig, "crown_%d" % i, Vector3(0.1, 0.22, 0.1), Vector3(0, 1.84, 0) + out * 0.2, accent, Vector3(out.z * 0.4, 0, -out.x * 0.4))
	for side in SIDES:
		var t = _tag(side)
		_part(rig, "hand_" + t, Vector3(0.3, 0.6, 0.3), Vector3(side * 0.66, 1.1, 0), tone)
		_glue(rig.parts["hand_" + t], Vector3(0.38, 0.24, 0.38), Vector3(0, -0.4, -0.02), tone)  # fist
		_part(rig, "foot_" + t, Vector3(0.36, 0.4, 0.44), Vector3(side * 0.3, 0.2, 0), "ink")
	if armed:
		rig.parts["hand_r"].position = Vector3(0.7, 1.12, -0.1)
		_raygun(rig, Vector3(0.74, 0.86, -0.46), 1.7, accent, "bullet_enemy")
		# Second barrel on the heavy cannon.
		_glue(rig.parts["weapon"], Vector3(0.14, 0.14, 0.42), Vector3(0, -0.22, -0.42), "weapon", Vector3.ZERO, "weapon")

# Two cube eyes with dark pupils pressed into a face. `depth` is the -Z offset,
# `y` the height on the part.
func _eyes(parent: Node3D, gap: float, radius: float, depth: float, y: float) -> void:
	for side in SIDES:
		_glue(parent, Vector3.ONE * radius * 2.0, Vector3(side * gap, y, depth), "flash")
		_glue(parent, Vector3.ONE * radius, Vector3(side * gap, y, depth - radius * 0.6), "ink")

# --------------------------------------------------------------- blocks -------

## Walls and props as blocky retro tiles. Box walls are brick courses, box props
## are crates, cylinder walls are stone pillars, cylinder props are barrels or
## bushes. The variant is picked deterministically from the footprint so the
## same layout always reads the same.
func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	if shape == "cylinder":
		if role == "wall":
			_pillar(holder, extent, color_key)
		elif roundi(extent.y * 10.0) % 2 == 0:
			_barrel(holder, extent, color_key)
		else:
			_bush(holder, extent, color_key)
	elif role == "wall":
		_brickwall(holder, extent, color_key)
	else:
		_crate(holder, extent, color_key)

# A running-bond brick wall: courses of inset cube bricks over a solid core, so
# the surface reads as stacked pixels. One merged mesh per size.
func _brickwall(holder: Node3D, extent: Vector3, key: String) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var depth = extent.z if along_x else extent.x
	var euler = Vector3.ZERO if along_x else Vector3(0, PI * 0.5, 0)
	var courses = maxi(1, roundi(extent.y / 0.55))
	var tall = extent.y / courses
	var across = maxi(1, roundi(length / 0.9))
	var wide = length / across
	add(holder, merge("brick%s/%d/%d" % [extent, courses, across], func():
		var p: Array = [cube(Vector3(0, extent.y * 0.5, 0), Vector3(length - 0.02, extent.y, depth - 0.08))]
		for row in courses:
			var odd = row % 2
			for i in across + odd:
				var x = -length * 0.5 + wide * (i + (0.0 if odd else 0.5))
				x = clampf(x, -length * 0.5 + wide * 0.35, length * 0.5 - wide * 0.35)
				p.append(cube(Vector3(x, tall * (row + 0.5), depth * 0.5 - 0.03), Vector3(wide - 0.06, tall - 0.06, 0.08)))
		return p), Vector3.ZERO, "wall", key, euler)

# A stacked crate: a cube with a darker rim frame and an item-block face stud.
func _crate(holder: Node3D, extent: Vector3, key: String) -> void:
	add(holder, merge("crate%s" % extent, func():
		var p: Array = [cube(Vector3(0, extent.y * 0.5, 0), extent - Vector3(0.1, 0.06, 0.1))]
		# Corner posts darker, read as a framed box.
		for sx in SIDES:
			for sz in SIDES:
				p.append(cube(Vector3(sx * (extent.x * 0.5 - 0.08), extent.y * 0.5, sz * (extent.z * 0.5 - 0.08)), Vector3(0.12, extent.y - 0.02, 0.12)))
		return p), Vector3.ZERO, "prop", key)
	# A bright pixel stud on top so crates read as item blocks.
	_glue(holder, Vector3(0.18, 0.1, 0.18), Vector3(0, extent.y + 0.02, 0), "player_accent", Vector3.ZERO, "pickup")

# A stone pillar: a stepped stack of square blocks, each course slightly inset.
func _pillar(holder: Node3D, extent: Vector3, key: String) -> void:
	var radius = extent.x * 0.5
	var courses = maxi(2, roundi(extent.y / 0.6))
	var tall = extent.y / courses
	add(holder, merge("pillar%f/%f/%d" % [radius, extent.y, courses], func():
		var p: Array = []
		for row in courses:
			var inset = 0.04 * float(row % 2)
			p.append(cube(Vector3(0, tall * (row + 0.5), 0), Vector3(radius * 2.0 - 0.08 - inset, tall - 0.04, radius * 2.0 - 0.08 - inset)))
		return p), Vector3.ZERO, "wall", key)

# A barrel: a short square drum with two band rings and a lid.
func _barrel(holder: Node3D, extent: Vector3, key: String) -> void:
	var r = extent.x * 0.5
	add(holder, merge("barrel%f/%f" % [r, extent.y], func(): return [
		cube(Vector3(0, extent.y * 0.5, 0), Vector3(r * 1.9, extent.y, r * 1.9)),
		cube(Vector3(0, extent.y * 0.3, 0), Vector3(r * 2.0, extent.y * 0.12, r * 2.0)),
		cube(Vector3(0, extent.y * 0.7, 0), Vector3(r * 2.0, extent.y * 0.12, r * 2.0))]),
		Vector3.ZERO, "prop", key)
	_glue(holder, Vector3(r * 1.7, 0.08, r * 1.7), Vector3(0, extent.y + 0.02, 0), "ink", Vector3.ZERO, "prop")

# A bush/tree-top: a stepped mound of green cubes on a short trunk.
func _bush(holder: Node3D, extent: Vector3, key: String) -> void:
	var r = extent.x * 0.5
	add(holder, merge("bush%f/%f" % [r, extent.y], func(): return [
		cube(Vector3(0, extent.y * 0.2, 0), Vector3(r * 0.6, extent.y * 0.4, r * 0.6)),
		cube(Vector3(0, extent.y * 0.55, 0), Vector3(r * 1.9, extent.y * 0.5, r * 1.9)),
		cube(Vector3(0, extent.y * 0.9, 0), Vector3(r * 1.3, extent.y * 0.4, r * 1.3))]),
		Vector3.ZERO, "prop", key)

# --------------------------------------------------------------- border -------

## A retro tile wall around the whole perimeter: a solid kerb with a row of
## alternating merlon caps on top (a classic dungeon/castle edge). Cheap: two
## merged meshes per run.
func border(holder: Node3D, extent: Vector3) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var depth = minf(extent.x, extent.z)
	var euler = Vector3.ZERO if along_x else Vector3(0, PI * 0.5, 0)
	var count = maxi(1, roundi(length / 1.2))
	var wide = length / count
	add(holder, merge("kerb%f/%f/%f/%d" % [length, extent.y, depth, count], func():
		var p: Array = [cube(Vector3(0, extent.y * 0.5, 0), Vector3(length, extent.y, depth - 0.04))]
		# Brick seams along the kerb face.
		for i in count:
			var x = -length * 0.5 + wide * (i + 0.5)
			p.append(cube(Vector3(x, extent.y * 0.5, depth * 0.5 - 0.02), Vector3(wide - 0.08, extent.y - 0.12, 0.06)))
		return p), Vector3.ZERO, "wall", "wall", euler)
	# Merlon caps: every other slot is raised, so the top edge reads crenellated.
	add(holder, merge("merlon%f/%f/%d" % [length, depth, count], func():
		var p: Array = []
		for i in count:
			if i % 2 == 0:
				var x = -length * 0.5 + wide * (i + 0.5)
				p.append(cube(Vector3(x, 0.14, 0), Vector3(wide - 0.12, 0.28, depth - 0.1)))
		return p), Vector3(0, extent.y, 0), "wall", "prop", euler)

# --------------------------------------------------------------- pickup -------

## Retro pickups: a flat voxel heart for health, bright item blocks with a
## distinct icon for each weapon power-up.
func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			# A pixel heart: two top squares, a body and a pointed bottom.
			add(holder, merge("heart", func(): return [
				cube(Vector3(-0.13, 0.1, 0), Vector3(0.22, 0.22, 0.16)),
				cube(Vector3(0.13, 0.1, 0), Vector3(0.22, 0.22, 0.16)),
				cube(Vector3(0, 0.0, 0), Vector3(0.44, 0.22, 0.16)),
				cube(Vector3(0, -0.18, 0), Vector3(0.28, 0.16, 0.16)),
				cube(Vector3(0, -0.32, 0), Vector3(0.12, 0.12, 0.16))]),
				Vector3.ZERO, "pickup", "pickup_health")
			_glue(holder, Vector3(0.1, 0.1, 0.18), Vector3(-0.08, 0.14, 0), "flash", Vector3.ZERO, "pickup")  # shine
		_:
			# An item block: a framed cube that carries a weapon icon.
			add(holder, merge("item", func(): return [
				cube(Vector3.ZERO, Vector3(0.5, 0.5, 0.5))]), Vector3.ZERO, "pickup", "pickup_ammo")
			for sx in SIDES:
				for sy in SIDES:
					_glue(holder, Vector3(0.12, 0.12, 0.54), Vector3(sx * 0.19, sy * 0.19, 0), "ink", Vector3.ZERO, "pickup")  # corner frame
			_icon(holder, what)

# A distinct front-face icon per weapon, in bright pixels.
func _icon(holder: Node3D, what: String) -> void:
	match what:
		"scatter":
			# Five spread dots.
			for d in [Vector3(0, 0.12, 0), Vector3(-0.13, -0.05, 0), Vector3(0.13, -0.05, 0), Vector3(-0.08, 0.02, 0), Vector3(0.08, 0.02, 0)]:
				_glue(holder, Vector3(0.09, 0.09, 0.08), d + Vector3(0, 0, -0.26), "player_accent", Vector3.ZERO, "pickup")
		"rapid":
			# A stepped lightning bolt.
			for d in [Vector3(0.06, 0.16, 0), Vector3(0, 0.05, 0), Vector3(-0.06, -0.05, 0), Vector3(0.02, -0.16, 0)]:
				_glue(holder, Vector3(0.1, 0.1, 0.08), d + Vector3(0, 0, -0.26), "player_accent", Vector3.ZERO, "pickup")
		_:
			# A round bomb: a cube core with a fuse pixel.
			_glue(holder, Vector3(0.24, 0.24, 0.08), Vector3(0, -0.04, -0.26), "ink", Vector3.ZERO, "pickup")
			_glue(holder, Vector3(0.08, 0.14, 0.08), Vector3(0.1, 0.16, -0.26), "player_accent", Vector3.ZERO, "pickup")

## Bullet: a small "pixel bolt", a plus/star of cubes flying nose-first -Z.
func bullet_mesh() -> Mesh:
	return merge("bolt", func(): return [
		cube(Vector3.ZERO, Vector3(0.5, 0.5, 0.9)),
		cube(Vector3(0, 0, -0.5), Vector3(0.26, 0.26, 0.3)),
		cube(Vector3(0.0, 0.34, 0.1), Vector3(0.22, 0.22, 0.22)),
		cube(Vector3(0.0, -0.34, 0.1), Vector3(0.22, 0.22, 0.22)),
		cube(Vector3(0.34, 0.0, 0.1), Vector3(0.22, 0.22, 0.22)),
		cube(Vector3(-0.34, 0.0, 0.1), Vector3(0.22, 0.22, 0.22))])

# -------------------------------------------------------------- scenery -------

## A tiled retro backdrop beyond the walls: a parallax horizon of hill/building
## blocks, pixel trees, a big pixel sun, floating cube clouds and a blocky score
## marquee. Everything stays outside the playfield; well under 80 instances.
func decorate(holder: Node3D, arena: Arena) -> void:
	var half = Vector3(arena.size.x * 0.5, 0, arena.size.y * 0.5)
	var salt = arena.size.x * 3.1 + arena.size.y * 1.7
	# A dark ground sheet under the backdrop so the horizon sits on something.
	add(holder, box(Vector3(arena.size.x + 80.0, 0.4, arena.size.y + 70.0)), Vector3(0, -0.4, 0), "prop", "floor_alt")
	# Parallax horizon: a staggered row of stepped hill/building blocks far back.
	var hues = ["wall", "tank", "runner", "bot", "player"]
	for i in 9:
		var x = (i - 4) * (arena.size.x + 24.0) / 9.0
		var h = 3.0 + fposmod(_noise(salt + i) + 1.0, 1.0) * 6.0
		_step_tower(holder, Vector3(x, 0, -half.z - 10.0), h, hues[i % hues.size()])
	# A big pixel sun low on the horizon, a stepped disc of one bright colour.
	_sun(holder, Vector3(half.x * 0.5, 9.0, -half.z - 16.0), 3.4, "player_accent")
	# Floating cube clouds.
	for i in 5:
		var at = Vector3((i - 2) * 9.0 + _noise(salt + i * 2.0) * 3.0, 7.0 + _noise(salt + i) * 2.0, -half.z - 7.0 - float(i % 2) * 3.0)
		_cloud(holder, at)
	# Pixel trees down the sides.
	for s in SIDES:
		for i in 3:
			var at = Vector3(s * (half.x + 5.0 + float(i % 2) * 2.0), 0, -half.z * 0.5 + i * half.z * 0.5)
			_tree(holder, at, "runner" if i % 2 == 0 else "tank")
	# A score marquee: a blocky banner of cubes above the back wall.
	_marquee(holder, Vector3(-half.x * 0.4, 5.6, -half.z - 2.2))

# A stepped pyramid tower (hill / retro building block).
func _step_tower(holder: Node3D, at: Vector3, height: float, key: String) -> void:
	var steps = maxi(2, roundi(height / 1.6))
	var tall = height / steps
	add(holder, merge("steptower%f/%d/%s" % [height, steps, key], func():
		var p: Array = []
		for i in steps:
			var w = 6.0 * (1.0 - float(i) / (steps + 1.0))
			p.append(cube(Vector3(0, tall * (i + 0.5), 0), Vector3(w, tall, w)))
		return p), at, "prop", key)

# A stepped pixel sun: concentric cube rings approximating a disc.
func _sun(holder: Node3D, at: Vector3, radius: float, key: String) -> void:
	add(holder, merge("sun%f" % radius, func():
		var p: Array = []
		var n = 6
		for iy in n:
			var y = (float(iy) / (n - 1) - 0.5) * 2.0 * radius
			var w = sqrt(maxf(radius * radius - y * y, 0.0)) * 2.0
			if w > 0.3:
				p.append(cube(Vector3(0, y, 0), Vector3(snappedf(w, radius / 3.0), 2.0 * radius / float(n), 0.6)))
		return p), at, "fx", key)

# A fluffy cube cloud: three stepped white boxes.
func _cloud(holder: Node3D, at: Vector3) -> void:
	add(holder, merge("cloud", func(): return [
		cube(Vector3(0, 0, 0), Vector3(2.6, 0.9, 0.6)),
		cube(Vector3(-0.8, 0.4, 0), Vector3(1.2, 0.8, 0.6)),
		cube(Vector3(0.7, 0.35, 0), Vector3(1.4, 0.7, 0.6))]), at, "fx", "flash")

# A pixel tree: a stepped trunk with a boxy stacked canopy.
func _tree(holder: Node3D, at: Vector3, leaf: String) -> void:
	add(holder, merge("tree/%s" % leaf, func(): return [
		[box(Vector3(0.8, 2.4, 0.8)), Transform3D(Basis(), Vector3(0, 1.2, 0))]]), at, "prop", "wall")
	add(holder, merge("tree_top/%s" % leaf, func(): return [
		cube(Vector3(0, 2.6, 0), Vector3(2.8, 1.4, 2.8)),
		cube(Vector3(0, 3.6, 0), Vector3(2.0, 1.2, 2.0)),
		cube(Vector3(0, 4.4, 0), Vector3(1.2, 1.0, 1.2))]), at, "prop", leaf)

# A score marquee: a framed banner of cube "digits" high behind the back wall.
func _marquee(holder: Node3D, at: Vector3) -> void:
	add(holder, merge("marquee_frame", func(): return [
		cube(Vector3(0, 0, 0.1), Vector3(9.0, 2.4, 0.3))]), at, "prop", "weapon")
	# A row of bright digit blocks.
	var cols = ["player_accent", "bullet_player", "pickup_ammo", "bullet_enemy", "flash", "player_accent"]
	for i in 6:
		add(holder, box(Vector3(0.9, 1.4, 0.2)), at + Vector3((i - 2.5) * 1.3, 0, -0.1), "fx", cols[i])

# Scenery varies by arena size; the same layout always looks the same.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
