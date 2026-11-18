extends DimensionBuilder
## Stickman shapes: every fighter is a marker drawing. A blob head, a single
## stroke for the spine and one stroke per limb, all in the team colour, so a
## crowd reads as "the blue one", "the red one". Limbs are thin capsules whose
## pivot sits at the joint (shoulder, hip) so the animator swings the whole arm
## like a stick-fight drawing. Ink details (pupils, brows, scribbles) are glued
## on in the "flash" role: flat ink, no hull, so they stay crisp dots and lines.
## Props and scenery are flat doodles with the bold inverted-hull outline doing
## the drawing; most scenery lies flat on the page like doodles in the margin.

const INK = "flash" # flat ink detail: no outline hull, reads as a pen line

# ----------------------------------------------------------------- helpers ---

func _tag(side: int) -> String:
	return "l" if side < 0 else "r"

func _at(origin: Vector3, euler: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(euler) * Basis.from_scale(size), origin)

## Several meshes baked into one part: one colour, one outline, one hit flash.
func fused(key: String, pieces: Callable) -> Mesh:
	return shared("fused:" + key, func():
		var tool = SurfaceTool.new()
		for piece in pieces.call():
			tool.append_from(piece[0], 0, piece[1])
		tool.generate_normals()
		return tool.commit())

## A limb/torso stroke: a capsule whose TOP sits at the part origin and whose
## body hangs down `length`, so turning the part swings it about the joint.
func stroke(radius: float, length: float) -> Mesh:
	return shared("stroke%f/%f" % [radius, length], func():
		var tool = SurfaceTool.new()
		tool.append_from(capsule(radius, length), 0, _at(Vector3(0, -length * 0.5, 0)))
		return tool.commit())

# A hanging / aiming arm: one stroke pivoting at the shoulder with a knuckle nub
# at the far end. `aim` points it forward (-Z) for the gun hand.
func _arm(rig: CharacterRig, tag: String, shoulder: Vector3, length: float, radius: float, tone: String, aim: float = 0.0) -> MeshInstance3D:
	var node = rig.add_part("hand_" + tag, stroke(radius, length), shoulder, tone, "character", Vector3(aim, 0, 0))
	add(node, sphere(radius * 1.2), Vector3(0, -length, 0), "character", tone)
	return node

# A leg: one stroke pivoting at the hip with a flat foot dash pointing forward.
func _leg(rig: CharacterRig, tag: String, hip: Vector3, length: float, radius: float, tone: String) -> MeshInstance3D:
	var node = rig.add_part("foot_" + tag, stroke(radius, length), hip, tone)
	add(node, box(Vector3(radius * 2.2, radius * 1.1, radius * 3.4)), Vector3(0, -length, -radius * 0.9), "character", tone)
	return node

# The spine stroke.
func _torso(rig: CharacterRig, top: float, bottom: float, radius: float, tone: String) -> MeshInstance3D:
	return rig.add_part("body", capsule(radius, top - bottom), Vector3(0, (top + bottom) * 0.5, 0), tone)

# Blob (or boxy) head with two ink pupils and an optional angry brow.
func _skull(rig: CharacterRig, at: float, radius: float, tone: String, square: bool, pupil: String, brow: float = 0.0) -> MeshInstance3D:
	var mesh = box(Vector3.ONE * radius * 1.7) if square else sphere(radius)
	var head = rig.add_part("head", mesh, Vector3(0, at, 0), tone)
	var pr = radius * 0.16
	for side in [-1, 1]:
		add(head, sphere(pr), Vector3(side * radius * 0.4, radius * 0.1, -radius * 0.92), INK, pupil)
		if brow != 0.0:
			# Angled brow stroke over each eye: lower on the inside = a scowl.
			add(head, box(Vector3(radius * 0.5, radius * 0.1, 0.03)), Vector3(side * radius * 0.42, radius * 0.34, -radius * 0.9), INK, "ink", Vector3(0, 0, side * brow))
	return head

# The pen blaster: a drawn barrel pointing -Z with a grip and a glowing nib. The
# right hand holds it, so the weapon view shows the barrel + arm bottom-right.
func _pen(rig: CharacterRig, at: Vector3, bullet: String) -> void:
	var gun = rig.add_part("weapon", box(Vector3(0.07, 0.09, 0.5)), at, "weapon", "weapon")
	add(gun, box(Vector3(0.08, 0.2, 0.1)), Vector3(0, -0.13, 0.13), "weapon", "weapon") # grip
	add(gun, cylinder(0.035, 0.26, -1.0, 8), Vector3(0, 0.01, -0.34), "weapon", "weapon", Vector3(PI * 0.5, 0, 0)) # nib
	add(gun, sphere(0.05), Vector3(0, 0.01, -0.46), "flash", bullet) # inking tip glows

# --------------------------------------------------------------- characters ---

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var armed: bool = look.get("weapon", true)
	match kind:
		"player": _player(rig, tone, armed)
		"bot": _bot(rig, tone, armed)
		"runner": _runner(rig, tone)
		"tank": _tank(rig, tone, armed)
		"boss": _boss(rig, tone, armed)
		_: _grunt(rig, tone, armed)

# Classic stickman: even strokes, a little pen in hand.
func _player(rig: CharacterRig, tone: String, armed: bool) -> void:
	var r = 0.08
	_torso(rig, 1.18, 0.52, 0.1, tone)
	_skull(rig, 1.42, 0.2, tone, false, "ink")
	_arm(rig, "l", Vector3(-0.15, 1.12, -0.04), 0.58, r, tone)
	_arm(rig, "r", Vector3(0.15, 1.12, -0.04), 0.58, r, tone, 1.2 if armed else 0.0)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.09, 0.54, 0), 0.6, r, tone)
	if armed:
		_pen(rig, Vector3(0.17, 0.95, -0.5), "bullet_player")

# Plain foot soldier scribble: a touch slighter than the player, scowling.
func _grunt(rig: CharacterRig, tone: String, armed: bool) -> void:
	var r = 0.072
	_torso(rig, 1.16, 0.52, 0.09, tone)
	_skull(rig, 1.4, 0.19, tone, false, "ink", 0.5)
	_arm(rig, "l", Vector3(-0.14, 1.1, -0.04), 0.56, r, tone)
	_arm(rig, "r", Vector3(0.14, 1.1, -0.04), 0.56, r, tone, 1.2 if armed else 0.0)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.09, 0.54, 0), 0.58, r, tone)
	if armed:
		_pen(rig, Vector3(0.16, 0.93, -0.5), "bullet_enemy")

# Sprinter: thin, hunched forward, short arms and long raking legs. Melee, so no
# pen; the whole drawing leans into the run.
func _runner(rig: CharacterRig, tone: String) -> void:
	var r = 0.065
	rig.add_part("body", capsule(0.085, 0.6), Vector3(0, 0.98, -0.08), tone, "character", Vector3(0.4, 0, 0))
	_skull(rig, 1.3, 0.17, tone, false, "ink", 0.35).position += Vector3(0, 0, -0.16)
	_arm(rig, "l", Vector3(-0.13, 1.08, -0.1), 0.44, r, tone)
	_arm(rig, "r", Vector3(0.13, 1.08, -0.1), 0.44, r, tone)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.08, 0.74, 0.02), 0.74, r, tone)

# Heavyweight: fat strokes, big head, a scribbled round shield on the left arm.
func _tank(rig: CharacterRig, tone: String, armed: bool) -> void:
	var r = 0.13
	_torso(rig, 1.12, 0.46, 0.18, tone)
	_skull(rig, 1.36, 0.24, tone, false, "ink", 0.55)
	var left = _arm(rig, "l", Vector3(-0.26, 1.06, -0.04), 0.5, r, tone)
	# A drawn shield slung on the forearm: a flat disc with an ink cross.
	add(left, cylinder(0.3, 0.07, -1.0, 16), Vector3(0, -0.42, -0.14), "character", tone, Vector3(PI * 0.5, 0, 0))
	add(left, box(Vector3(0.5, 0.05, 0.04)), Vector3(0, -0.42, -0.2), INK, "ink")
	add(left, box(Vector3(0.05, 0.5, 0.04)), Vector3(0, -0.42, -0.2), INK, "ink")
	_arm(rig, "r", Vector3(0.26, 1.06, -0.04), 0.5, r, tone, 1.15 if armed else 0.0)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.16, 0.5, 0), 0.5, r, tone)
	if armed:
		_pen(rig, Vector3(0.28, 0.9, -0.52), "bullet_enemy")

# Boss: a towering inked stickman (whole figure is black), long swinging arms,
# white staring eyes and a scribbled crown of horns. look.scale blows it up.
func _boss(rig: CharacterRig, tone: String, armed: bool) -> void:
	var r = 0.11
	_torso(rig, 1.24, 0.46, 0.15, tone)
	var head = _skull(rig, 1.46, 0.26, tone, false, "flash", 0.6)
	# Crown of scribbled horns.
	add(head, fused("crown", func():
		var pieces = []
		for i in 5:
			var t = (i - 2) * 0.46
			pieces.append([cone(0.07, 0.3), _at(Vector3(sin(t) * 0.22, 0.24, cos(t) * 0.05 - 0.02), Vector3(-0.2, 0, -t * 0.5))])
		return pieces), Vector3.ZERO, "character", tone)
	_arm(rig, "l", Vector3(-0.26, 1.2, -0.04), 0.78, r, tone)
	_arm(rig, "r", Vector3(0.26, 1.2, -0.04), 0.78, r, tone, 1.1 if armed else 0.0)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.13, 0.5, 0), 0.5, r, tone)
	if armed:
		_pen(rig, Vector3(0.3, 1.0, -0.58), "bullet_enemy")

# Doodle robot: square head, single-eye and an antenna that the animator wags.
func _bot(rig: CharacterRig, tone: String, armed: bool) -> void:
	var r = 0.085
	_torso(rig, 1.16, 0.52, 0.11, tone)
	var head = rig.add_part("head", box(Vector3(0.36, 0.34, 0.34)), Vector3(0, 1.4, 0), tone)
	add(head, box(Vector3(0.26, 0.09, 0.03)), Vector3(0, 0.02, -0.2), INK, "ink") # visor band
	add(head, sphere(0.055), Vector3(0, 0.02, -0.21), "flash", "bullet_enemy") # eye glows
	rig.add_part("antenna", fused("antenna", func(): return [
		[cylinder(0.02, 0.24, -1.0, 6), _at(Vector3(0, 0.12, 0))],
		[sphere(0.05), _at(Vector3(0, 0.26, 0))]]), Vector3(0, 1.57, 0.02), tone)
	_arm(rig, "l", Vector3(-0.15, 1.1, -0.04), 0.56, r, tone)
	_arm(rig, "r", Vector3(0.15, 1.1, -0.04), 0.56, r, tone, 1.2 if armed else 0.0)
	for side in [-1, 1]:
		_leg(rig, _tag(side), Vector3(side * 0.1, 0.54, 0), 0.58, r, tone)
	if armed:
		_pen(rig, Vector3(0.17, 0.93, -0.5), "bullet_enemy")

# ------------------------------------------------------------------ blocks ---

## Doodled walls and props: flat marker fills carrying the bold ink hull, with a
## few drawn detail lines. Deterministic in the block's own position so a shift
## back rebuilds the exact same doodle.
func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	var pick = int(absf(holder.position.x * 7.0 + holder.position.z * 13.0 + extent.x * 3.0))
	if shape == "cylinder":
		var radius = extent.x * 0.5
		if extent.y / maxf(extent.x, 0.1) >= 1.3:
			_barrel(holder, radius, extent.y, role, color_key)
		else:
			_rock(holder, radius, extent.y, role, color_key, pick)
		return
	# Model along X and turn the whole doodle when the block runs along Z.
	var turned = extent.z > extent.x
	var size = Vector3(extent.z, extent.y, extent.x) if turned else extent
	var euler = Vector3(0, PI * 0.5, 0) if turned else Vector3.ZERO
	if role == "wall":
		_brick(holder, size, euler, color_key)
	else:
		_crate(holder, size, euler, color_key, pick)

# Sketched crate: a flat box, an ink frame around the front face and an X brace.
func _crate(holder: Node3D, size: Vector3, euler: Vector3, key: String, pick: int) -> void:
	add(holder, box(size), Vector3(0, size.y * 0.5, 0), "prop", key, euler)
	var face = Node3D.new()
	face.rotation = euler
	face.position = Vector3(0, size.y * 0.5, 0)
	holder.add_child(face)
	var fz = size.z * 0.5 + 0.015
	var bar = minf(size.x, size.y) * 0.09
	add(face, box(Vector3(size.x, bar, 0.02)), Vector3(0, size.y * 0.5 - bar * 0.5, fz), INK, "ink")
	add(face, box(Vector3(size.x, bar, 0.02)), Vector3(0, -size.y * 0.5 + bar * 0.5, fz), INK, "ink")
	var diag = sqrt(size.x * size.x + size.y * size.y)
	var ang = atan2(size.y, size.x)
	for s in [-1, 1]:
		add(face, box(Vector3(diag, bar * 0.8, 0.02)), Vector3(0, 0, fz), INK, "ink", Vector3(0, 0, s * ang))
	if pick % 2 == 0: # a smaller box stacked on half the crates
		add(holder, box(size * 0.5), Vector3(size.x * 0.1, size.y * 1.25, -size.z * 0.1), "prop", key, euler)

# Hand-drawn brick wall: a flat box with a scribbled brick grid on the front.
func _brick(holder: Node3D, size: Vector3, euler: Vector3, key: String) -> void:
	add(holder, box(size), Vector3(0, size.y * 0.5, 0), "wall", key, euler)
	var face = Node3D.new()
	face.rotation = euler
	face.position = Vector3(0, size.y * 0.5, 0)
	holder.add_child(face)
	var fz = size.z * 0.5 + 0.015
	var rows = clampi(int(round(size.y / 0.5)), 1, 5)
	var th = 0.02
	for row in range(1, rows):
		add(face, box(Vector3(size.x, 0.03, th)), Vector3(0, -size.y * 0.5 + row * size.y / rows, fz), INK, "ink")
	var cols = clampi(int(round(size.x / 0.6)), 1, 7)
	for row in rows:
		var shift = 0.5 if row % 2 == 1 else 0.0
		for c in cols:
			add(face, box(Vector3(0.03, size.y / rows, th)), Vector3(-size.x * 0.5 + (c + shift) * size.x / cols, -size.y * 0.5 + (row + 0.5) * size.y / rows, fz), INK, "ink")

# Drawn barrel: a cylinder with two ink bands around it.
func _barrel(holder: Node3D, radius: float, height: float, role: String, key: String) -> void:
	add(holder, cylinder(radius, height, radius * 0.94), Vector3(0, height * 0.5, 0), role, key)
	for level in [0.28, 0.72]:
		add(holder, cylinder(radius * 1.03, 0.04, -1.0, 16), Vector3(0, height * level, 0), INK, "ink")

# Drawn rock / boulder: a squat blob, flattened and nudged off-round per site.
func _rock(holder: Node3D, radius: float, height: float, role: String, key: String, pick: int) -> void:
	var blob = add(holder, sphere(radius, 0.8), Vector3(0, height * 0.52, 0), role, key)
	blob.scale = Vector3(1.0 + 0.12 * ((pick % 3) - 1), height / (radius * 1.6), 1.0 - 0.1 * (pick % 2))
	# A crack line drawn across it.
	add(holder, box(Vector3(radius * 1.4, 0.03, 0.03)), Vector3(0, height * 0.6, -radius * 0.7), INK, "ink", Vector3(0, 0, 0.4))

# ------------------------------------------------------------------ border ---

## A drawn picket fence around the whole perimeter: a rail and evenly spaced
## posts along the run. Cheap: the border loops the arena four times.
func border(holder: Node3D, extent: Vector3) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var euler = Vector3.ZERO if along_x else Vector3(0, PI * 0.5, 0)
	var top = minf(extent.y, 1.1)
	var frame = Node3D.new()
	frame.rotation = euler
	holder.add_child(frame)
	# Two rails running the length.
	for h in [top * 0.5, top * 0.88]:
		add(frame, box(Vector3(length, 0.1, 0.08)), Vector3(0, h, 0), "wall", "wall")
	var count = clampi(int(length / 2.0), 3, 24)
	for i in count + 1:
		var x = -length * 0.5 + i * length / count
		add(frame, box(Vector3(0.12, top, 0.12)), Vector3(x, top * 0.5, 0), "wall", "wall")
		add(frame, cone(0.1, 0.14), Vector3(x, top + 0.05, 0), "wall", "wall")

# ------------------------------------------------------------------ pickup ---

## Drawn icons: a doodled heart for health, a dot-cluster, a dash-stack and a
## little rocket for the weapons. All carry the bold pickup outline.
func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			add(holder, fused("heart", func(): return [
				[sphere(0.16), _at(Vector3(-0.12, 0.08, 0))],
				[sphere(0.16), _at(Vector3(0.12, 0.08, 0))],
				[cone(0.26, 0.4), _at(Vector3(0, -0.16, 0), Vector3(PI, 0, 0))]]), Vector3.ZERO, "pickup", "pickup_health")
		"scatter":
			add(holder, cylinder(0.28, 0.08, -1.0, 16), Vector3(0, -0.16, 0), "pickup", "pickup_ammo")
			for i in 4:
				var a = TAU * i / 4.0
				add(holder, sphere(0.09), Vector3(sin(a) * 0.14, 0.04, cos(a) * 0.14), "pickup", "pickup_ammo")
			add(holder, sphere(0.1), Vector3(0, 0.08, 0), "pickup", "pickup_ammo")
		"rapid":
			for i in 3:
				add(holder, box(Vector3(0.4, 0.09, 0.14)), Vector3(0, -0.12 + i * 0.13, 0), "pickup", "pickup_ammo", Vector3(0, 0, -0.25))
		_:
			add(holder, cylinder(0.12, 0.34, -1.0, 10), Vector3(0, -0.06, 0), "pickup", "pickup_ammo")
			add(holder, cone(0.14, 0.22), Vector3(0, 0.22, 0), "pickup", "pickup_ammo")
			for s in [-1, 1]:
				add(holder, box(Vector3(0.14, 0.02, 0.1)), Vector3(s * 0.12, -0.16, 0), "pickup", "pickup_ammo", Vector3(0, 0, s * 0.6))

## The ink bolt: a short dash flying nose-first along -Z. The core stretches it
## 2.4x along Z, so it reads as a flicked pen stroke.
func bullet_mesh() -> Mesh:
	return fused("bolt", func(): return [
		[capsule(0.4, 1.0), _at(Vector3.ZERO, Vector3(PI * 0.5, 0, 0))]])

# ----------------------------------------------------------------- scenery ---

## Doodles in the page margin: a sun, clouds, stick trees, little houses, arrows
## and a POW burst, nearly all drawn FLAT on the page beyond the walls so the
## behind camera never clips them. Deterministic, well under 80 instances.
func decorate(holder: Node3D, arena: Arena) -> void:
	var half = Vector3(arena.size.x * 0.5, 0, arena.size.y * 0.5)
	var y = 0.03
	# Sun with rays in a far corner.
	var sun_at = Vector3(half.x + 4.0, y, -half.z - 4.0)
	add(holder, cylinder(1.6, 0.04, -1.0, 24), sun_at, "prop", "pickup_ammo")
	for i in 10:
		var a = TAU * i / 10.0
		add(holder, box(Vector3(0.9, 0.04, 0.12)), sun_at + Vector3(sin(a) * 2.3, 0, cos(a) * 2.3), INK, "ink", Vector3(0, -a, 0))
	# A couple of flat clouds along the top margin.
	for cx in [-half.x * 0.5, half.x * 0.35]:
		_cloud(holder, Vector3(cx, y, -half.z - 3.5))
	# Stick trees and little houses down each side.
	for side in [-1, 1]:
		_tree(holder, Vector3(side * (half.x + 3.5), y, -half.z * 0.3), 1.0)
		_tree(holder, Vector3(side * (half.x + 4.2), y, half.z * 0.4), 0.8)
		_house(holder, Vector3(side * (half.x + 4.5), y, half.z * 0.9))
	# Arrows pointing inward along the bottom margin, and a POW near one corner.
	for i in 3:
		var ax = lerpf(-half.x * 0.5, half.x * 0.5, i / 2.0)
		_arrow(holder, Vector3(ax, y, half.z + 3.0))
	_pow(holder, Vector3(-half.x - 4.5, y, -half.z - 3.0))

func _cloud(holder: Node3D, at: Vector3) -> void:
	add(holder, fused("cloud", func(): return [
		[cylinder(1.0, 0.05, -1.0, 16), _at(Vector3.ZERO)],
		[cylinder(0.7, 0.05, -1.0, 16), _at(Vector3(1.1, 0, 0.1))],
		[cylinder(0.8, 0.05, -1.0, 16), _at(Vector3(-1.1, 0, 0.1))]]), at, "prop", "floor_alt")

func _tree(holder: Node3D, at: Vector3, grow: float) -> void:
	add(holder, box(Vector3(0.14, 0.04, 1.4 * grow)), at + Vector3(0, 0, 0.7 * grow), INK, "ink")
	add(holder, cylinder(0.9 * grow, 0.05, -1.0, 7), at, "prop", "runner")

func _house(holder: Node3D, at: Vector3) -> void:
	add(holder, box(Vector3(1.6, 0.05, 1.3)), at, "prop", "floor_alt")
	add(holder, cone(1.1, 0.05), at + Vector3(0, 0.01, -1.0), "prop", "prop", Vector3(PI * 0.5, 0, 0))

func _arrow(holder: Node3D, at: Vector3) -> void:
	add(holder, box(Vector3(0.12, 0.04, 1.2)), at, INK, "ink")
	add(holder, cone(0.22, 0.4), at + Vector3(0, 0, -0.7), INK, "ink", Vector3(-PI * 0.5, 0, 0))

func _pow(holder: Node3D, at: Vector3) -> void:
	add(holder, fused("pow", func():
		var pieces = []
		for i in 10:
			var a = TAU * i / 10.0
			var rad = 1.4 if i % 2 == 0 else 0.8
			pieces.append([box(Vector3(0.3, 0.05, rad)), _at(Vector3(sin(a) * rad * 0.5, 0, cos(a) * rad * 0.5), Vector3(0, -a, 0))])
		return pieces), at, "prop", "bullet_enemy")
