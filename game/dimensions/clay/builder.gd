extends DimensionBuilder
## Clay shapes: a tabletop claymation set. Puppets are squashed balls, rolled
## sausages and coils; walls are stacked clay bricks and coil towers; props
## are craft-table things (spools, coil pots, mushrooms, stick crates).
## Part names matter to animator.gd: the word before the first "_" picks how
## an extra part moves (eye, pupil, lump, tail, arm, leg, hat, crown...).

const FLAT = Vector3(PI * 0.5, 0, 0)

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	# Enemies without an accent get cream trim: it reads on every clay colour.
	var trim: String = look.get("accent", "flash")
	match kind:
		"player": _hero(rig, tone, trim)
		"bot": _bot(rig, tone, trim)
		"runner": _slug(rig, tone)
		"tank": _snowman(rig, tone, trim, look.get("weapon", true))
		"boss": _blob_king(rig, tone, trim, look.get("weapon", true))
		_: _goon(rig, tone, trim, look.get("weapon", true))

# --- puppets ---------------------------------------------------------------

## Stubby hero: pill body, belt coil, big head under a rolled-coil hat.
func _hero(rig: CharacterRig, tone: String, trim: String) -> void:
	_part(rig, "body", capsule(0.31, 0.78), Vector3(0, 0.68, 0), tone, Vector3(1.05, 1, 0.95))
	_part(rig, "belt_coil", ring(0.25, 0.37), Vector3(0, 0.56, 0), trim, Vector3.ONE, Vector3(0.06, 0, -0.05))
	_part(rig, "head", sphere(0.3), Vector3(0, 1.2, 0), tone, Vector3(1.05, 0.92, 1))
	_part(rig, "nose", sphere(0.07), Vector3(0.01, 1.16, -0.31), tone, Vector3(0.9, 0.9, 1.6))
	_eyes(rig, Vector3(0, 1.27, -0.23), 0.12, 0.085, 1.0, 1.18)
	_part(rig, "hat_coil", coil("hat", 0.25, 0.03, 0.36, 3.5, 0.062), Vector3(0, 1.4, 0), trim, Vector3.ONE, Vector3(-0.08, 0, 0.06))
	_biped(rig, tone, 0.46, 0.13)
	_gun(rig, Vector3(0.46, 0.86, -0.56), "blaster", 1.0, trim, "bullet_player")

## Skirmish puppet: same build as the hero, but a flat head with a goggle
## strap and a toothpick antenna, so the two never read alike from above.
func _bot(rig: CharacterRig, tone: String, trim: String) -> void:
	_part(rig, "body", capsule(0.31, 0.78), Vector3(0, 0.68, 0), tone, Vector3(1, 1, 0.92))
	_part(rig, "lump_badge", sphere(0.12), Vector3(-0.06, 0.82, -0.27), trim, Vector3(1, 1, 0.4))
	_part(rig, "head", sphere(0.3), Vector3(0, 1.2, 0), tone, Vector3(1.08, 0.74, 1.05))
	_part(rig, "band", ring(0.25, 0.33), Vector3(0, 1.22, 0), trim, Vector3.ONE, Vector3(0.05, 0, 0))
	_eyes(rig, Vector3(0, 1.23, -0.27), 0.11, 0.1, 1.1, 1.0)
	_limb(rig, "stalk", Vector3(0, 1.38, 0.02), Vector3(0.07, 1.68, 0.04), 0.022, "flash")
	_part(rig, "bobble", sphere(0.075), Vector3(0.07, 1.7, 0.04), trim)
	for side in [-1, 1]:
		_part(rig, "ear_" + _tag(side), cylinder(0.07, 0.1, -1.0, 10), Vector3(side * 0.33, 1.2, 0), "ink", Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_biped(rig, tone, 0.46, 0.13)
	_gun(rig, Vector3(0.46, 0.86, -0.5), "blaster", 1.0, trim, tone)

## Lumpy potato goon: lopsided, big pinched nose, unibrow and a sprout.
func _goon(rig: CharacterRig, tone: String, trim: String, armed: bool) -> void:
	_part(rig, "body", sphere(0.36), Vector3(0, 0.6, 0.02), tone, Vector3(1, 1.3, 0.95), Vector3(0.08, 0, 0.06))
	_part(rig, "lump_a", sphere(0.16), Vector3(-0.27, 0.92, 0.08), tone)
	_part(rig, "lump_b", sphere(0.14), Vector3(0.2, 0.42, 0.25), tone)
	_part(rig, "head", sphere(0.25), Vector3(0.04, 1.2, -0.03), tone, Vector3(1.1, 0.95, 1))
	_part(rig, "nose", sphere(0.09), Vector3(0.04, 1.14, -0.27), tone, Vector3(0.9, 0.85, 1.9))
	_eyes(rig, Vector3(0.04, 1.28, -0.19), 0.1, 0.07, 1.3, 1.0)
	_part(rig, "brow", capsule(0.03, 0.32), Vector3(0.04, 1.38, -0.2), "ink", Vector3.ONE, Vector3(0, 0, PI * 0.5 + 0.12))
	_part(rig, "sprout", tube("sprout", [Vector3.ZERO, Vector3(0.02, 0.1, 0), Vector3(0.08, 0.17, 0), Vector3(0.16, 0.15, 0)], [0.035, 0.03, 0.03, 0.035]), Vector3(0.04, 1.42, 0), "ink")
	_mitts(rig, tone, 0.44, 0.12, armed)
	_feet(rig, 0.17, 0.15)
	if armed:
		_gun(rig, Vector3(0.46, 0.86, -0.46), "press", 1.0, trim, tone)

## Slug on six stubby feet, eyes on stalks, pincers out front. No weapon.
func _slug(rig: CharacterRig, tone: String) -> void:
	_part(rig, "body", sphere(0.36), Vector3(0, 0.42, 0.05), tone, Vector3(1, 0.85, 1.3))
	_part(rig, "head", sphere(0.3), Vector3(0, 0.74, -0.32), tone, Vector3(1, 0.95, 1.05))
	_part(rig, "tail_a", sphere(0.25), Vector3(0, 0.3, 0.44), tone)
	_part(rig, "tail_b", sphere(0.15), Vector3(0.04, 0.2, 0.68), tone, Vector3(1, 0.9, 1.3))
	_part(rig, "mouth", sphere(0.1), Vector3(0, 0.64, -0.58), "ink", Vector3(1.5, 0.5, 0.6))
	for side in [-1, 1]:
		var tag = _tag(side)
		var tip = Vector3(side * 0.26, 1.42, -0.4)
		_limb(rig, "stalk_" + tag, Vector3(side * 0.12, 0.92, -0.32), tip, 0.045, tone)
		var size = 0.15 if side < 0 else 0.125
		_part(rig, "eye_" + tag, sphere(0.1), tip, "flash", Vector3.ONE * size / 0.1)
		_part(rig, "pupil_" + tag, sphere(0.045), tip + Vector3(0, 0, -size * 0.8), "ink", Vector3.ONE * 1.4)
		rig.add_part("hand_" + tag, cone(0.09, 0.36), Vector3(side * 0.27, 0.5, -0.52), "ink", "character", Vector3(-PI * 0.5, 0, -side * 0.3))
		_part(rig, "foot_" + tag, sphere(0.11), Vector3(side * 0.33, 0.07, -0.14), "ink", Vector3(1, 0.6, 1.3))
		_part(rig, "foot_" + tag + "2", sphere(0.11), Vector3(side * 0.33, 0.07, 0.2), "ink", Vector3(1, 0.6, 1.3))
		_part(rig, "foot_" + tag + "3", sphere(0.11), Vector3(side * 0.25, 0.06, 0.5), "ink", Vector3(0.9, 0.55, 1.2))
	# Pinched ridge down the back: the read from above.
	_part(rig, "lump_a", cone(0.1, 0.24), Vector3(0, 0.78, 0.0), "ink", Vector3.ONE, Vector3(0.3, 0, 0))
	_part(rig, "lump_b", cone(0.09, 0.2), Vector3(0, 0.66, 0.3), "ink", Vector3.ONE, Vector3(0.6, 0, 0))
	_part(rig, "lump_c", cone(0.07, 0.16), Vector3(0, 0.5, 0.56), "ink", Vector3.ONE, Vector3(0.9, 0, 0))

## Fat snowman stack under a bottle cap, carrot nose, scarf coil, big cannon.
func _snowman(rig: CharacterRig, tone: String, trim: String, armed: bool) -> void:
	_part(rig, "body", sphere(0.45), Vector3(0, 0.4, 0), tone, Vector3(1, 0.88, 1))
	_part(rig, "lump_mid", sphere(0.35), Vector3(0.01, 0.98, 0), tone, Vector3(1, 0.9, 1))
	_part(rig, "head", sphere(0.23), Vector3(0, 1.44, -0.02), tone)
	_part(rig, "scarf", ring(0.15, 0.29), Vector3(0, 1.25, 0), trim, Vector3.ONE, Vector3(0.1, 0, 0.06))
	_part(rig, "cap", cylinder(0.25, 0.1, 0.2, 12), Vector3(0, 1.67, -0.02), "ink", Vector3.ONE, Vector3(0.1, 0, -0.08))
	_part(rig, "nose", cone(0.05, 0.2), Vector3(0, 1.42, -0.3), "runner", Vector3.ONE, Vector3(-PI * 0.5, 0, 0))
	_eyes(rig, Vector3(0, 1.5, -0.19), 0.08, 0.055, 1.0, 1.0)
	_part(rig, "brow", capsule(0.03, 0.28), Vector3(0, 1.57, -0.2), "ink", Vector3.ONE, Vector3(0, 0, PI * 0.5))
	_part(rig, "button_a", sphere(0.05), Vector3(0, 1.06, -0.33), "ink")
	_part(rig, "button_b", sphere(0.05), Vector3(0.01, 0.86, -0.32), "ink")
	_mitts(rig, tone, 0.54, 0.17, armed)
	_feet(rig, 0.25, 0.2)
	if armed:
		_gun(rig, Vector3(0.56, 0.9, -0.5), "cannon", 1.3, trim, tone)

## Boss: a heap of blobs with three eyes and a crown of pinched spikes.
func _blob_king(rig: CharacterRig, tone: String, trim: String, armed: bool) -> void:
	_part(rig, "body", sphere(0.44), Vector3(0, 0.5, 0), tone, Vector3(1, 1.1, 0.95))
	_part(rig, "lump_l", sphere(0.24), Vector3(-0.36, 0.92, 0.02), tone)
	_part(rig, "lump_r", sphere(0.2), Vector3(0.36, 0.97, 0.04), tone)
	_part(rig, "lump_back", sphere(0.26), Vector3(0.05, 0.72, 0.3), tone)
	_part(rig, "lump_belly", sphere(0.2), Vector3(-0.08, 0.44, -0.32), tone)
	_part(rig, "belt_coil", ring(0.36, 0.48), Vector3(0, 0.3, 0), trim, Vector3.ONE, Vector3(0.05, 0, 0.04))
	_part(rig, "head", sphere(0.3), Vector3(0, 1.28, -0.04), tone, Vector3(1.1, 0.9, 1))
	_eyes(rig, Vector3(0, 1.3, -0.26), 0.13, 0.075, 1.2, 0.9)
	_part(rig, "eye_m", sphere(0.1), Vector3(0.01, 1.44, -0.24), "flash", Vector3.ONE * 0.6)
	_part(rig, "pupil_m", sphere(0.045), Vector3(0.01, 1.44, -0.29), "ink", Vector3.ONE * 0.7)
	_part(rig, "mouth", sphere(0.1), Vector3(0, 1.13, -0.29), "ink", Vector3(1.7, 0.5, 0.5))
	_part(rig, "tooth_a", cone(0.035, 0.1), Vector3(-0.07, 1.16, -0.33), "flash")
	_part(rig, "tooth_b", cone(0.035, 0.08), Vector3(0.08, 1.15, -0.33), "flash")
	_part(rig, "crown_band", ring(0.17, 0.26), Vector3(0, 1.5, -0.04), trim)
	for i in 5:
		var angle = TAU * i / 5.0 + 0.3
		var out = Vector3(sin(angle), 0, cos(angle))
		# Each spike leans outward, as if pinched up between two fingers.
		_part(rig, "crown_%d" % i, cone(0.07, 0.27), Vector3(0, 1.62, -0.04) + out * 0.2, trim, Vector3.ONE, Vector3(out.z * 0.45, 0, -out.x * 0.45))
	_mitts(rig, tone, 0.6, 0.2, armed)
	_feet(rig, 0.26, 0.2)
	if armed:
		_gun(rig, Vector3(0.6, 0.86, -0.5), "cannon", 1.45, trim, tone)

# --- puppet pieces -----------------------------------------------------------

func _tag(side: int) -> String:
	return "l" if side < 0 else "r"

func _part(rig: CharacterRig, part: String, mesh: Mesh, at: Vector3, key: String, size: Vector3 = Vector3.ONE, euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node = rig.add_part(part, mesh, at, key, "character", euler)
	node.scale = size
	return node

## Rolled sausage from `a` to `b`.
func _limb(rig: CharacterRig, part: String, a: Vector3, b: Vector3, radius: float, key: String) -> void:
	var node = rig.add_part(part, capsule(radius, snappedf(a.distance_to(b) + radius * 2.0, 0.02)), (a + b) * 0.5, key)
	var up = (b - a).normalized()
	var side = up.cross(Vector3.BACK).normalized()
	node.basis = Basis(side, up, side.cross(up))

## Ball eyes pressed into the face, never quite the same size.
func _eyes(rig: CharacterRig, centre: Vector3, gap: float, radius: float, left: float, right: float) -> void:
	for side in [-1, 1]:
		var size = radius * (left if side < 0 else right)
		var at = centre + Vector3(side * gap, 0, 0)
		_part(rig, "eye_" + _tag(side), sphere(0.1), at, "flash", Vector3.ONE * size / 0.1)
		_part(rig, "pupil_" + _tag(side), sphere(0.045), at + Vector3(side * -0.01, 0, -size * 0.8), "ink", Vector3.ONE * size / 0.085)

## Hands; the right one sits on the weapon grip when armed.
func _mitts(rig: CharacterRig, tone: String, reach: float, radius: float, armed: bool) -> void:
	rig.add_part("hand_l", sphere(radius), Vector3(-reach, 0.74, -0.16), tone)
	rig.add_part("hand_r", sphere(radius), Vector3(reach, 0.72, -0.34) if armed else Vector3(reach, 0.74, -0.16), tone)

## Thumb-squashed feet.
func _feet(rig: CharacterRig, gap: float, radius: float) -> void:
	for side in [-1, 1]:
		_part(rig, "foot_" + _tag(side), sphere(radius), Vector3(side * gap, radius * 0.45, -0.06), "ink", Vector3(1, 0.5, 1.5), Vector3(0, -side * 0.15, 0))

## Arms and coil legs of the two-legged puppets.
func _biped(rig: CharacterRig, tone: String, reach: float, fist: float) -> void:
	_mitts(rig, tone, reach, fist, true)
	_limb(rig, "arm_l", Vector3(-0.3, 0.96, 0), Vector3(-reach, 0.76, -0.14), 0.07, tone)
	_limb(rig, "arm_r", Vector3(0.3, 0.96, -0.02), Vector3(reach, 0.76, -0.3), 0.07, tone)
	_feet(rig, 0.17, 0.15)
	for side in [-1, 1]:
		_part(rig, "leg_" + _tag(side), coil("leg", 0.07, 0.07, 0.2, 2.5, 0.04), Vector3(side * 0.16, 0.12, 0), tone)

## Toy clay gun, pointing along -Z. The barrel is the `weapon` part; the rest
## hangs off it so the whole thing recoils and shows in the weapon view.
## `style`: blaster (extruder with a plunger), press (cookie press with a
## T-handle) or cannon (wide mouth, two hoppers).
func _gun(rig: CharacterRig, at: Vector3, style: String, size: float, trim: String, ammo: String) -> void:
	var profile: Array = {
		"blaster": [[0.3, 0.0], [0.3, 0.1], [0.06, 0.115], [-0.02, 0.085], [-0.3, 0.08], [-0.33, 0.12], [-0.44, 0.125], [-0.44, 0.07], [-0.38, 0.0]],
		"press": [[0.26, 0.0], [0.26, 0.13], [-0.12, 0.13], [-0.16, 0.09], [-0.3, 0.09], [-0.32, 0.16], [-0.38, 0.16], [-0.38, 0.0]],
		"cannon": [[0.3, 0.0], [0.3, 0.12], [0.1, 0.15], [-0.15, 0.1], [-0.3, 0.11], [-0.46, 0.19], [-0.46, 0.11], [-0.36, 0.0]],
	}[style]
	var gun = rig.add_part("weapon", lathe("gun_" + style, profile, 16), at, "weapon", "weapon")
	gun.scale = Vector3.ONE * size
	add(gun, capsule(0.055, 0.26), Vector3(0, -0.15, 0.1), "weapon", "ink", Vector3(0.35, 0, 0))
	# The lump of clay about to be fired, pressed into the hopper.
	add(gun, ring(0.05, 0.1), Vector3(0, 0.1, 0.04), "weapon", trim)
	add(gun, sphere(0.095), Vector3(0, 0.16, 0.04), "weapon", ammo).scale = Vector3(1, 0.9, 1)
	add(gun, sphere(0.035), Vector3(0, 0.14, -0.4), "weapon", trim)
	add(gun, cylinder(0.035, 0.2, -1.0, 8), Vector3(0, 0, 0.36), "weapon", "flash", FLAT)
	match style:
		"blaster":
			add(gun, ring(0.075, 0.125), Vector3(0, 0, -0.16), "weapon", trim, FLAT)
			add(gun, sphere(0.1), Vector3(0, 0, 0.47), "weapon", trim).scale = Vector3(1, 1, 0.5)
		"press":
			add(gun, capsule(0.045, 0.34), Vector3(0, 0, 0.46), "weapon", trim, Vector3(0, 0, PI * 0.5))
		"cannon":
			add(gun, sphere(0.1), Vector3(0.02, 0.15, -0.2), "weapon", ammo)
			add(gun, ring(0.1, 0.17), Vector3(0, 0, -0.24), "weapon", trim, FLAT)
			add(gun, sphere(0.1), Vector3(0, 0, 0.47), "weapon", trim).scale = Vector3(1, 1, 0.5)

# --- arena blocks ------------------------------------------------------------

## Walls: stacked clay bricks (box) or a coil-built tower (cylinder).
## Props by footprint: long boxes are a pile of rolled logs, wide ones a stack
## of slabs, small ones a craft-stick crate. Cylinder props pick by height:
## tenths of a metre mod 3 gives coil pot (1.2, 1.5), cotton reel (1.3, 1.6)
## or mushroom (1.1, 1.4, 1.7, 2.0).
func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	if shape == "cylinder":
		if role == "wall":
			_tower(holder, extent, role, color_key)
		else:
			match roundi(extent.y * 10.0) % 3:
				0: _pot(holder, extent, role, color_key)
				1: _reel(holder, extent, role, color_key)
				_: _mushroom(holder, extent, role, color_key)
	elif role == "wall":
		_bricks(holder, extent, role, color_key)
	elif maxf(extent.x, extent.z) >= minf(extent.x, extent.z) * 1.8:
		_logs(holder, extent, role, color_key)
	elif maxf(extent.x, extent.z) >= 2.4:
		_slabs(holder, extent, role, color_key)
	else:
		_crate(holder, extent, role, color_key)

func _bricks(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var depth = extent.z if along_x else extent.x
	var courses = maxi(1, roundi(extent.y / 0.72))
	var tall = extent.y / courses
	var count = maxi(1, roundi(length / 1.5))
	var wide = length / count
	var full = rbox(Vector3(wide - 0.05, tall - 0.03, depth - 0.1), 0.14)
	var half = rbox(Vector3(wide * 0.5 - 0.05, tall - 0.03, depth - 0.1), 0.14)
	var turn = 0.0 if along_x else PI * 0.5
	var salt = _seed(holder)
	for row in courses:
		# Running bond: odd courses start and end on a half brick.
		var odd = row % 2 == 1
		for i in (count + 1 if odd else count):
			var mesh = full
			var offset = -length * 0.5 + wide * (i + 0.5)
			if odd:
				mesh = half if i == 0 or i == count else full
				offset = -length * 0.5 + (wide * 0.25 if i == 0 else length - wide * 0.25 if i == count else wide * i)
			var jitter = _noise(salt + row * 7.0 + i * 13.0)
			var at = Vector3(offset, tall * (row + 0.5), jitter * 0.02)
			add(holder, mesh, at if along_x else Vector3(at.z, at.y, at.x), role, key, Vector3(0, turn + jitter * 0.03, 0))
	# A leftover sausage of clay rolled out along the top.
	var lying = Vector3(0, 0, PI * 0.5) if along_x else FLAT
	add(holder, capsule(0.13, snappedf(length * 0.62, 0.1)), Vector3(0, extent.y + 0.1, 0), role, "prop" if key != "prop" else "wall", lying)

func _tower(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var radius = extent.x * 0.5
	var fat = 0.2
	add(holder, coil("tower", radius - fat, radius - fat, extent.y - fat * 2.0, (extent.y - fat * 2.0) / (fat * 1.9), fat), Vector3(0, fat, 0), role, key, Vector3(0, _seed(holder), 0))
	add(holder, cylinder(radius - fat, extent.y - 0.1), Vector3(0, extent.y * 0.5 - 0.05, 0), role, key)
	add(holder, sphere(radius * 0.8), Vector3(0, extent.y - 0.05, 0), role, "prop").scale = Vector3(1, 0.3, 1)
	add(holder, sphere(0.22), Vector3(0, extent.y + 0.22, 0), role, key)

func _pot(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var radius = extent.x * 0.5
	var fat = 0.13
	var turns = (extent.y - fat * 2.0) / (fat * 1.9)
	add(holder, coil("pot", radius * 0.62, radius * 0.7, extent.y - fat * 2.0, turns, fat, radius * 0.3 - fat), Vector3(0, fat, 0), role, key, Vector3(0, _seed(holder), 0))
	add(holder, cylinder(radius * 0.72, extent.y - 0.2, radius * 0.6), Vector3(0, extent.y * 0.5 - 0.1, 0), role, "ink")

func _reel(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var radius = extent.x * 0.5
	for y in [0.08, extent.y - 0.08]:
		add(holder, cylinder(radius - 0.03, 0.16), Vector3(0, y, 0), role, key)
	add(holder, cylinder(radius * 0.72, extent.y - 0.3), Vector3(0, extent.y * 0.5, 0), role, "flash")
	# Thread wound round the core.
	var gap = extent.y - 0.44
	add(holder, coil("thread", radius * 0.74, radius * 0.74, gap, gap / 0.12, 0.06), Vector3(0, 0.22, 0), role, "ui_danger")
	add(holder, cylinder(radius * 0.3, 0.04), Vector3(0, extent.y, 0), role, "ink")

func _mushroom(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var radius = extent.x * 0.5
	add(holder, cylinder(radius * 0.5, extent.y * 0.7, radius * 0.38), Vector3(0, extent.y * 0.35, 0), role, "flash")
	add(holder, sphere(radius - 0.03), Vector3(0, extent.y * 0.72, 0), role, key).scale = Vector3(1, extent.y * 0.36 / radius, 1)
	var salt = _seed(holder)
	for i in 4:
		var angle = salt + TAU * i / 4.0 + _noise(salt + i) * 0.4
		var out = 0.55 if i % 2 == 0 else 0.3
		add(holder, sphere(0.14), Vector3(sin(angle) * radius * out, extent.y * (1.0 if out < 0.5 else 0.93), cos(angle) * radius * out), role, "flash").scale = Vector3(1, 0.4, 1)

func _logs(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var along_x = extent.x >= extent.z
	var length = extent.x if along_x else extent.z
	var depth = extent.z if along_x else extent.x
	# Two on the bottom, one on top: 2 + sqrt(3) radii tall.
	var fat = snappedf(minf(depth * 0.25, extent.y / 3.73), 0.01)
	var lying = Vector3(0, 0, PI * 0.5) if along_x else FLAT
	var mesh = capsule(fat, length - 0.06)
	for spot in [Vector2(-fat, fat), Vector2(fat, fat), Vector2(0, fat * 2.73)]:
		var at = Vector3(0, spot.y, spot.x) if along_x else Vector3(spot.x, spot.y, 0)
		add(holder, mesh, at, role, key if spot.y < fat * 2.0 else "wall", lying)
	# Toothpick stakes with a ball on top hold the pile together.
	for end in [-1, 1]:
		for side in [-1, 1]:
			var x = end * (length * 0.5 - 0.5)
			var z = side * (depth * 0.5 - 0.07)
			var at = Vector3(x, 0, z) if along_x else Vector3(z, 0, x)
			add(holder, cylinder(0.04, extent.y, -1.0, 6), at + Vector3(0, extent.y * 0.5, 0), role, "flash")
			add(holder, sphere(0.1), at * Vector3(1, 0, 1) * 0.97 + Vector3(0, extent.y, 0), role, "wall")

func _slabs(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	var salt = _seed(holder)
	var tall = extent.y / 3.0
	# Slabs sit a little crooked; shrunk so the corners stay in the footprint.
	var mesh = rbox(Vector3(extent.x * 0.93, tall - 0.02, extent.z * 0.93), 0.16)
	for layer in 3:
		add(holder, mesh, Vector3(0, tall * (layer + 0.5), 0), role, key if layer != 1 else "flash", Vector3(0, _noise(salt + layer) * 0.035, 0))
	for i in 3:
		var angle = salt + TAU * i / 3.0
		add(holder, sphere(0.2 + 0.05 * i), Vector3(sin(angle), 0, cos(angle)) * minf(extent.x, extent.z) * 0.22 + Vector3(0, extent.y + 0.1, 0), role, "wall").scale = Vector3(1, 0.8, 1)

func _crate(holder: Node3D, extent: Vector3, role: String, key: String) -> void:
	add(holder, rbox(extent - Vector3(0.14, 0.06, 0.14), 0.12), Vector3(0, extent.y * 0.5 - 0.03, 0), role, key)
	for x in [-1, 1]:
		for z in [-1, 1]:
			add(holder, rbox(Vector3(0.16, extent.y, 0.16), 0.05), Vector3(x * (extent.x * 0.5 - 0.08), extent.y * 0.5, z * (extent.z * 0.5 - 0.08)), role, "flash")
	add(holder, rbox(Vector3(extent.x - 0.08, 0.12, extent.z - 0.08), 0.05), Vector3(0, extent.y - 0.07, 0), role, "wall")
	# Two craft sticks crossed on the lid, pinned by a ball of clay.
	var stick = rbox(Vector3(minf(extent.x, extent.z) * 1.15, 0.06, 0.2), 0.03)
	var turn = _noise(_seed(holder)) * 0.08
	add(holder, stick, Vector3(0, extent.y, 0), role, "flash", Vector3(0, PI * 0.25 + turn, 0))
	add(holder, stick, Vector3(0, extent.y + 0.04, 0), role, "flash", Vector3(0, -PI * 0.25 + turn, 0))
	add(holder, sphere(0.14), Vector3(0, extent.y + 0.1, 0), role, key).scale = Vector3(1, 0.6, 1)

# --- pickups and bullets -----------------------------------------------------

## Health is a clay heart; weapons are what they fire: a clutch of pellets
## (scatter), a wound coil (rapid) or one fat bomb with a fuse (launcher).
func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			# Two fat sausages pressed together into a V.
			for side in [-1, 1]:
				add(holder, capsule(0.16, 0.5), Vector3(side * 0.1, 0, 0), "pickup", "pickup_health", Vector3(0, 0, side * -0.62)).scale = Vector3(1, 1, 0.75)
			add(holder, sphere(0.07), Vector3(-0.12, 0.12, -0.11), "pickup", "flash").scale = Vector3(1, 1, 0.5)
		"scatter":
			add(holder, sphere(0.12), Vector3(0, 0.02, 0), "pickup", "weapon")
			for i in 5:
				var angle = TAU * i / 5.0
				add(holder, sphere(0.12), Vector3(sin(angle) * 0.2, 0.02 + (0.16 if i % 2 == 0 else -0.12), cos(angle) * 0.2), "pickup", "pickup_ammo")
		"rapid":
			add(holder, coil("spring", 0.17, 0.17, 0.44, 4.5, 0.05), Vector3(0, -0.22, 0), "pickup", "pickup_ammo")
			add(holder, capsule(0.08, 0.62), Vector3.ZERO, "pickup", "weapon")
		_:
			add(holder, sphere(0.25), Vector3(0, -0.04, 0), "pickup", "pickup_ammo")
			add(holder, ring(0.2, 0.28), Vector3(0, -0.04, 0), "pickup", "weapon")
			add(holder, tube("fuse", [Vector3.ZERO, Vector3(0.01, 0.1, 0), Vector3(0.06, 0.18, 0), Vector3(0.14, 0.2, 0)], [0.04, 0.03, 0.03, 0.03]), Vector3(0, 0.18, 0), "pickup", "ink")
			add(holder, sphere(0.06), Vector3(0.16, 0.39, 0), "pickup", "player_accent")

## Rolled pellet: fat nose forward, pinched tail behind.
func bullet_mesh() -> Mesh:
	return lathe("bullet", [[0.5, 0.0], [0.3, 0.12], [0.05, 0.3], [-0.2, 0.42], [-0.38, 0.38], [-0.5, 0.0]], 8)

# --- scenery -----------------------------------------------------------------

## The arena is a miniature set on a craft table: cutting mat, tubs of clay,
## giant tools and pencils, a desk lamp and lumpy model trees.
func decorate(holder: Node3D, arena: Arena) -> void:
	var half = Vector3(arena.size.x * 0.5, 0, arena.size.y * 0.5)
	var salt = arena.size.x * 3.1 + arena.size.y * 1.7
	add(holder, box(Vector3(arena.size.x + 70.0, 0.2, arena.size.y + 60.0)), Vector3(0, -0.45, 0), "prop", "prop")
	add(holder, box(Vector3(arena.size.x + 9.0, 0.3, arena.size.y + 9.0)), Vector3(0, -0.17, 0), "prop", "floor_alt")
	# Ruler ticks along the near edge of the mat.
	for i in 9:
		add(holder, box(Vector3(0.12, 0.04, 0.5 if i % 2 == 1 else 0.9)), Vector3((i - 4) * arena.size.x / 9.0, -0.02, half.z + 3.7), "prop", "flash")
	# Model trees just outside the back and side walls.
	var spots = [Vector3(-half.x * 0.6, 0, -half.z - 3.0), Vector3(half.x * 0.25, 0, -half.z - 3.2), Vector3(-half.x - 3.0, 0, -half.z * 0.3), Vector3(half.x + 3.0, 0, half.z * 0.2), Vector3(half.x + 2.8, 0, -half.z * 0.7)]
	for i in spots.size():
		var grow = 1.0 + _noise(salt + i * 3.0) * 0.25
		add(holder, cylinder(0.4, 2.0, 0.25, 8), spots[i] + Vector3(0, 1.0, 0), "prop", "prop")
		add(holder, sphere(1.2), spots[i] + Vector3(0, 2.6, 0), "prop", "bot").scale = Vector3(grow, 0.9, grow)
		add(holder, sphere(0.8), spots[i] + Vector3(0.5 * grow, 3.5, 0.2), "prop", "bot").scale = Vector3.ONE * grow
	# Tubs of clay behind the set; one has its lid off.
	var tub = Vector3(-half.x - 5.5, 0, -half.z - 6.5)
	for i in 2:
		var at = tub + Vector3(i * 6.0, 0, i * -1.0)
		add(holder, cylinder(2.3, 3.0, 2.5, 16), at + Vector3(0, 1.5, 0), "prop", "flash")
		add(holder, cylinder(2.5, 0.4, -1.0, 16), at + Vector3(0, 2.0 if i == 0 else 3.1, 0), "prop", "ui_danger" if i == 0 else "pickup_ammo")
	add(holder, sphere(2.1), tub + Vector3(0, 2.9, 0), "prop", "ui_danger").scale = Vector3(1, 0.5, 1)
	# Rolled sausages and balls of spare clay.
	var colours = ["ui_accent", "pickup_ammo", "ui_danger", "pickup_health"]
	for i in 4:
		var at = Vector3(half.x + 5.0 + (i % 2) * 2.2, 0.6, -half.z * 0.2 + i * 2.6)
		add(holder, capsule(0.6, 5.0 + (i % 2)), at, "prop", colours[i], Vector3(PI * 0.5, 0.5 + _noise(salt + i) * 0.4, 0))
		add(holder, sphere(0.7 + 0.15 * i), Vector3(-half.x - 4.5 - i * 1.4, 0.6, half.z * 0.7 - i * 2.4), "prop", colours[3 - i]).scale = Vector3(1, 0.85, 1)
	# Wire loop tool lying on the left, wooden knife tool at the back right.
	var loop_tool = Vector3(-half.x - 4.0, 0.35, -half.z * 0.35)
	add(holder, cylinder(0.35, 7.0, 0.28, 8), loop_tool, "prop", "flash", Vector3(PI * 0.5, 0.15, 0))
	add(holder, cylinder(0.3, 1.0, 0.2, 8), loop_tool + Vector3(-0.6, 0, -4.0), "prop", "ink", Vector3(PI * 0.5, 0.15, 0))
	add(holder, ring(0.75, 0.95), loop_tool + Vector3(-0.85, 0, -5.3), "prop", "ink")
	add(holder, tube("knife", [Vector3(-5, 0, 0), Vector3(-2, 0, 0), Vector3(2, 0, 0), Vector3(4.2, 0.1, 0), Vector3(5, 0.3, 0)], [0.25, 0.4, 0.42, 0.5, 0.15], 8), Vector3(half.x * 0.55, 0.45, -half.z - 6.5), "prop", "flash", Vector3(0, 0.12, 0)).scale = Vector3(1, 0.7, 1)
	# Pencils in front of the mat and along the left.
	_pencil(holder, Vector3(-half.x * 0.3, 0.4, half.z + 6.2), 0.06, "ui_accent")
	_pencil(holder, Vector3(half.x * 0.6, 0.4, half.z + 7.6), -0.1, "pickup_ammo")
	# Desk lamp leaning over the back right corner. It casts no shadow, or
	# its arm would stripe the playfield.
	var foot = Vector3(half.x + 6.5, 0, -half.z - 5.0)
	var elbow = foot + Vector3(1.5, 8.0, -1.5)
	var shade = foot + Vector3(-3.0, 11.0, 2.0)
	var lamp = [add(holder, cylinder(2.2, 0.6, 1.9, 16), foot + Vector3(0, 0.3, 0), "prop", "ink"),
		_beam(holder, foot + Vector3(0, 0.5, 0), elbow, "ink"), _beam(holder, elbow, shade, "ink"),
		add(holder, sphere(0.45), elbow, "prop", "ui_accent")]
	var to_set = (Vector3(half.x * 0.3, 0, 0) - shade).normalized()
	var side = to_set.cross(Vector3.BACK).normalized()
	var head = add(holder, cylinder(2.0, 2.4, 0.6, 16), shade, "prop", "ui_danger")
	# The cone's narrow end is +Y: point that away from the set.
	head.basis = Basis(side, -to_set, side.cross(-to_set))
	lamp.append(head)
	lamp.append(add(holder, sphere(0.8), shade + to_set * 0.9, "pickup", "flash"))
	for node in lamp:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _pencil(holder: Node3D, at: Vector3, yaw: float, key: String) -> void:
	var along = Vector3(cos(yaw), 0, -sin(yaw))
	var lying = Vector3(0, yaw, -PI * 0.5)
	add(holder, cylinder(0.4, 11.0, -1.0, 6), at, "prop", key, lying)
	add(holder, cylinder(0.4, 1.2, 0.12, 6), at + along * 6.1, "prop", "flash", lying)
	add(holder, cylinder(0.12, 0.35, 0.0, 6), at + along * 6.85, "prop", "ink", lying)
	add(holder, cylinder(0.42, 0.9, -1.0, 10), at - along * 5.9, "prop", "ui_danger", lying)

func _beam(holder: Node3D, a: Vector3, b: Vector3, key: String) -> MeshInstance3D:
	var node = add(holder, cylinder(0.22, snappedf(a.distance_to(b), 0.1), -1.0, 8), (a + b) * 0.5, "prop", key)
	var up = (b - a).normalized()
	var side = up.cross(Vector3.BACK).normalized()
	node.basis = Basis(side, up, side.cross(up))
	return node

# --- meshes ------------------------------------------------------------------

## Clay ring lying flat (axis Y), from `inner` to `outer` radius.
func ring(inner: float, outer: float) -> Mesh:
	return shared("ring%f/%f" % [inner, outer], func():
		var mesh = TorusMesh.new()
		mesh.inner_radius = inner
		mesh.outer_radius = outer
		mesh.rings = 20
		mesh.ring_segments = 8
		return mesh)

## Pillow-soft box: a ball pulled apart to the corners of `extent`.
func rbox(extent: Vector3, radius: float) -> Mesh:
	var size = extent.snappedf(0.01)
	return shared("rbox%s/%f" % [size, radius], func():
		var source = BoxMesh.new()
		# Five segments per side: no vertex sits on a centre plane, so every
		# vertex belongs to exactly one corner of the pulled-apart ball.
		source.subdivide_width = 4
		source.subdivide_height = 4
		source.subdivide_depth = 4
		var arrays = source.get_mesh_arrays()
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var round_off = minf(radius, minf(size.x, minf(size.y, size.z)) * 0.5)
		var inner = size * 0.5 - Vector3.ONE * round_off
		for i in points.size():
			var out = (points[i] * 2.0).normalized()
			points[i] = out * round_off + points[i].sign() * inner
			normals[i] = out
		var made = []
		made.resize(Mesh.ARRAY_MAX)
		made[Mesh.ARRAY_VERTEX] = points
		made[Mesh.ARRAY_NORMAL] = normals
		made[Mesh.ARRAY_INDEX] = arrays[Mesh.ARRAY_INDEX]
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, made)
		return mesh)

## Sausage rolled along `points`, with a radius per point and rounded ends.
func tube(key: String, points: Array, radii: Array, sides: int = 8) -> Mesh:
	return shared("tube/" + key, func(): return _sweep(points, radii, sides, true))

## Shape turned around the Z axis from [z, radius] pairs, back to front.
func lathe(key: String, profile: Array, sides: int = 12) -> Mesh:
	return shared("lathe/" + key, func():
		var points = []
		var radii = []
		for pair in profile:
			points.append(Vector3(0, 0, pair[0]))
			radii.append(pair[1])
		return _sweep(points, radii, sides, false))

## Coil of clay wound upward from radius `from` to `to` over `height`;
## `bulge` swells the middle (pots). The cache key is the name plus sizes.
func coil(key: String, from: float, to: float, height: float, turns: float, fat: float, bulge: float = 0.0) -> Mesh:
	return shared("coil/%s/%.2f/%.2f/%.2f" % [key, from, height, fat], func():
		var points = []
		var radii = []
		var steps = maxi(4, ceili(turns * 12.0))
		for i in steps + 1:
			var along = float(i) / steps
			var reach = lerpf(from, to, along) + bulge * sin(along * PI)
			points.append(Vector3(cos(along * turns * TAU) * reach, along * height, sin(along * turns * TAU) * reach))
			radii.append(fat)
		return _sweep(points, radii, 7, true))

func _sweep(path: Array, girth: Array, sides: int, rounded: bool) -> ArrayMesh:
	var points = path.duplicate()
	var radii = girth.duplicate()
	if rounded:
		# Two extra rings per end approximate a dome.
		var head: Vector3 = (points[0] - points[1]).normalized()
		var tail: Vector3 = (points[-1] - points[-2]).normalized()
		var first: float = radii[0]
		var final: float = radii[-1]
		points.push_front(points[0] + head * first * 0.6)
		points.push_front(points[0] + head * first * 0.4)
		radii.push_front(first * 0.75)
		radii.push_front(0.0)
		points.append(points[-1] + tail * final * 0.6)
		points.append(points[-1] + tail * final * 0.4)
		radii.append(final * 0.75)
		radii.append(0.0)
	var last = points.size() - 1
	var tangent: Vector3 = (points[last] - points[0]).normalized()
	var side = tangent.cross(Vector3.UP)
	if side.length() < 0.01:
		side = tangent.cross(Vector3.RIGHT)
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	for i in points.size():
		var ahead: Vector3 = points[mini(i + 1, last)] - points[maxi(i - 1, 0)]
		if ahead.length() > 0.0001:
			tangent = ahead.normalized()
		# Carry the frame along the path so the tube never twists.
		var flat = side - tangent * side.dot(tangent)
		side = flat.normalized() if flat.length() > 0.001 else tangent.cross(Vector3.RIGHT).normalized()
		var up = tangent.cross(side)
		for j in sides:
			var angle = TAU * j / sides
			var out = side * cos(angle) + up * sin(angle)
			verts.append(points[i] + out * radii[i])
			normals.append(out if radii[i] > 0.0001 else (-tangent if i == 0 else tangent))
		if i < last:
			for j in sides:
				var a = i * sides + j
				var b = i * sides + (j + 1) % sides
				indices.append_array([a, a + sides, b, b, a + sides, b + sides])
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

# Blocks vary by where they stand: the same layout always looks the same.
func _seed(holder: Node3D) -> float:
	return absf(holder.position.x * 7.3 + holder.position.z * 13.7) + 1.0

func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
