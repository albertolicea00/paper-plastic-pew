extends DimensionBuilder
## Manga shapes: tapered torsos, spiked hair, blades and trailing cloth for the
## cast; shoji walls, shrine pillars, stone lanterns, bamboo and strapped
## cargo for the arena; rooftops, cherry trees and a red sun around it.
## Scenery keeps 2.5 clear of the border walls: the behind view can swing out
## that far above them.
## Extra character parts are moved by this pack's animator (see its groups).

const PAPER = "floor" # paper, plaster, rice, steel highlights
const VERMILION = "grunt" # torii red for scenery
# The behind view rides 3.2 up and passes over blocks: dressing that rises
# above its collision stays under this, or the camera ends up inside it.
const CEILING = 2.9

func character(rig: CharacterRig, look: Dictionary, kind: String) -> void:
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "ink")
	var armed: bool = look.get("weapon", true)
	match kind if kind in ["player", "bot", "runner", "tank", "boss"] else look.get("build", "grunt"):
		"player": _hero(rig, tone, accent, armed)
		"bot": _rival(rig, tone, accent, armed)
		"runner": _ninja(rig, tone, accent, armed)
		"tank": _oni(rig, tone, accent, armed)
		"boss": _lord(rig, tone, accent, armed)
		_: _soldier(rig, tone, accent, armed)

# Shonen hero: V torso, spiked hair, scarf with two tails.
func _hero(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.19, 0.62, 0.34, 6), Vector3(0, 0.68, 0), tone)
	rig.add_part("belt", cylinder(0.25, 0.2, 0.2, 6), Vector3(0, 0.33, 0), "ink")
	_face(rig, 1.32, 0.25, "ink")
	rig.add_part("hair", fused("hair_hero", func(): return [
		[sphere(0.275), _at(Vector3(0, 0.04, 0.05))],
		[_spike(0.13, 0.42), _at(Vector3(0, 0.3, 0.02), Vector3(0.25, 0, 0))],
		[_spike(0.12, 0.44), _at(Vector3(0, 0.2, 0.26), Vector3(1.05, 0, 0))],
		[_spike(0.11, 0.4), _at(Vector3(0, 0.0, 0.32), Vector3(1.7, 0, 0))],
		[_spike(0.11, 0.38), _at(Vector3(-0.24, 0.16, 0.08), Vector3(0.5, 0, 1.0))],
		[_spike(0.11, 0.38), _at(Vector3(0.24, 0.16, 0.08), Vector3(0.5, 0, -1.0))],
		[_spike(0.09, 0.3), _at(Vector3(0.06, 0.2, -0.24), Vector3(-1.25, 0, -0.2))]]), Vector3(0, 1.32, 0), tone)
	rig.add_part("scarf", cylinder(0.21, 0.14, 0.17, 8), Vector3(0, 1.04, 0), accent)
	rig.add_part("scarf_a", _strip(0.2, 0.62), Vector3(0.09, 1.05, 0.16), accent, "character", Vector3(0.95, 0.25, 0))
	rig.add_part("scarf_b", _strip(0.16, 0.46), Vector3(-0.07, 1.03, 0.16), accent, "character", Vector3(1.15, -0.3, 0))
	_limbs(rig, 0.46, 0.84, 0.17, accent, 0.13)
	if armed:
		_blaster(rig, Vector3(0.46, 0.86, -0.5), accent, "bullet_player")

# Rival swordsman: flared coat, eye band, topknot with a long ponytail.
func _rival(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.2, 0.6, 0.32, 6), Vector3(0, 0.7, 0), tone)
	rig.add_part("coat", cylinder(0.4, 0.42, 0.2, 6), Vector3(0, 0.36, 0.02), "ink")
	rig.add_part("head", sphere(0.24), Vector3(0, 1.3, 0), PAPER)
	rig.add_part("visor", box(Vector3(0.4, 0.09, 0.3)), Vector3(0, 1.33, -0.1), accent)
	rig.add_part("hair", fused("hair_rival", func(): return [
		[sphere(0.265), _at(Vector3(0, 0.05, 0.05))],
		[cylinder(0.07, 0.2, 0.1, 6), _at(Vector3(0, 0.34, 0.06))],
		[_spike(0.1, 0.3), _at(Vector3(0, 0.12, -0.22), Vector3(-1.35, 0, 0))]]), Vector3(0, 1.3, 0), tone)
	rig.add_part("tail", _strip(0.22, 0.8, 0.1), Vector3(0, 1.66, 0.1), tone, "character", Vector3(1.1, 0, 0))
	for side in [-1, 1]:
		rig.add_part("shoulder_" + _tag(side), prism(Vector3(0.26, 0.14, 0.3)), Vector3(side * 0.36, 1.02, 0), "ink", "character", Vector3(0, 0, -side * 0.35))
	_limbs(rig, 0.46, 0.84, 0.17, tone, 0.13)
	if armed:
		_blaster(rig, Vector3(0.46, 0.86, -0.5), accent, "bullet_enemy")

# Foot soldier: robe, wide straw hat, banner on the back, rifle with bayonet.
func _soldier(rig: CharacterRig, tone: String, _accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.33, 0.78, 0.2, 6), Vector3(0, 0.6, 0), tone)
	rig.add_part("belt", cylinder(0.27, 0.1, 0.25, 6), Vector3(0, 0.66, 0), "ink")
	_face(rig, 1.2, 0.21, "ink")
	rig.add_part("hat", fused("hat_soldier", func(): return [
		[cylinder(0.44, 0.2, 0.04, 8), _at(Vector3.ZERO)],
		[_spike(0.07, 0.14), _at(Vector3(0, 0.15, 0))]]), Vector3(0, 1.42, 0), tone)
	rig.add_part("banner", fused("banner", func(): return [
		[cylinder(0.025, 1.0, -1.0, 4), _at(Vector3(0, 0.5, 0))],
		[box(Vector3(0.34, 0.5, 0.04)), _at(Vector3(0.18, 0.74, 0))]]), Vector3(0, 0.95, 0.24), "ink", "character", Vector3(0.12, 0, 0))
	_limbs(rig, 0.42, 0.8, 0.16, "ink", 0.15)
	if armed:
		var gun = rig.add_part("weapon", box(Vector3(0.08, 0.11, 0.7)), Vector3(0.42, 0.84, -0.46), "weapon", "weapon")
		add(gun, _blade(0.07, 0.34), Vector3(0, -0.02, -0.35), "weapon", PAPER)
		add(gun, box(Vector3(0.1, 0.18, 0.2)), Vector3(0, -0.05, 0.36), "weapon", "ink")
		add(gun, box(Vector3(0.1, 0.05, 0.16)), Vector3(0, 0.07, 0.05), "weapon", "bullet_enemy")

# Masked ninja: hunched and narrow, headband tails, a blade in each fist.
func _ninja(rig: CharacterRig, tone: String, _accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.13, 0.62, 0.27, 5), Vector3(0, 0.66, -0.04), tone, "character", Vector3(-0.3, 0, 0))
	rig.add_part("belt", cylinder(0.19, 0.12, 0.15, 5), Vector3(0, 0.4, 0.05), "ink")
	rig.add_part("head", sphere(0.24), Vector3(0, 1.22, -0.14), tone)
	rig.add_part("visor", box(Vector3(0.42, 0.11, 0.3)), Vector3(0, 1.25, -0.24), "ink")
	rig.add_part("hair", fused("hood_ninja", func(): return [
		[_spike(0.2, 0.34, 4), _at(Vector3(0, 0.22, 0.08), Vector3(0.7, 0, 0))],
		[box(Vector3(0.06, 0.03, 0.03)), _at(Vector3(-0.09, 0.04, -0.27))],
		[box(Vector3(0.06, 0.03, 0.03)), _at(Vector3(0.09, 0.04, -0.27))]]), Vector3(0, 1.22, -0.14), PAPER)
	rig.add_part("band_a", _strip(0.1, 0.55), Vector3(0.05, 1.27, 0.08), "ink", "character", Vector3(0.8, 0.3, 0))
	rig.add_part("band_b", _strip(0.08, 0.4), Vector3(-0.04, 1.26, 0.08), "ink", "character", Vector3(1.0, -0.35, 0))
	rig.add_part("sheath", box(Vector3(0.07, 0.07, 0.8)), Vector3(0, 0.84, 0.2), "ink", "character", Vector3(1.0, 0, 0.5))
	for side in [-1, 1]:
		var tag = _tag(side)
		rig.add_part("hand_" + tag, box(Vector3.ONE * 0.15), Vector3(side * 0.36, 0.7, -0.26), "ink")
		rig.add_part("blade_" + tag, _blade(0.11, 0.62), Vector3(side * 0.36, 0.7, -0.3), PAPER, "character", Vector3(-0.15, -side * 0.3, 0))
		rig.add_part("foot_" + tag, box(Vector3(0.16, 0.14, 0.32)), Vector3(side * 0.14, 0.07, -0.02), "ink")
	if armed:
		_blaster(rig, Vector3(0.4, 0.8, -0.5), "ink", "bullet_enemy")

# Armoured oni: barrel chest, plate shoulders and skirt, horned helmet, club cannon.
func _oni(rig: CharacterRig, tone: String, _accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.33, 0.72, 0.44, 6), Vector3(0, 0.72, 0), tone)
	rig.add_part("skirt", cylinder(0.46, 0.3, 0.34, 6), Vector3(0, 0.33, 0), "ink")
	rig.add_part("head", sphere(0.2), Vector3(0, 1.24, -0.04), tone)
	rig.add_part("visor", box(Vector3(0.3, 0.07, 0.2)), Vector3(0, 1.25, -0.13), "bullet_enemy")
	rig.add_part("hat", fused("helm_oni", func(): return [
		[cylinder(0.3, 0.16, 0.14, 6), _at(Vector3(0, 0.0, 0))],
		[cylinder(0.34, 0.06, 0.3, 6), _at(Vector3(0, -0.08, 0.08))]]), Vector3(0, 1.4, 0), "ink")
	for side in [-1, 1]:
		var tag = _tag(side)
		rig.add_part("horn_" + tag, _spike(0.07, 0.36), Vector3(side * 0.2, 1.56, -0.06), PAPER, "character", Vector3(-0.2, 0, -side * 0.7))
		rig.add_part("shoulder_" + tag, cylinder(0.25, 0.24, 0.08, 4), Vector3(side * 0.44, 1.08, 0), "ink", "character", Vector3(0, PI * 0.25, -side * 0.3))
		rig.add_part("hand_" + tag, box(Vector3(0.24, 0.24, 0.26)), Vector3(side * 0.56, 0.74, -0.24), "ink")
		rig.add_part("foot_" + tag, box(Vector3(0.26, 0.18, 0.4)), Vector3(side * 0.22, 0.09, -0.03), "ink")
	if armed:
		var club = rig.add_part("weapon", fused("club", func(): return [
			[cylinder(0.09, 0.8, 0.17, 6), _at(Vector3.ZERO, Vector3(-PI * 0.5, 0, 0))]]), Vector3(0.56, 0.84, -0.55), "weapon", "weapon")
		for ring in 3:
			add(club, cylinder(0.14 + ring * 0.025, 0.07, -1.0, 6), Vector3(0, 0, 0.05 - ring * 0.2), "weapon", "ink", Vector3(-PI * 0.5, 0, 0))
		add(club, cylinder(0.13, 0.04, -1.0, 6), Vector3(0, 0, -0.4), "flash", "bullet_enemy", Vector3(-PI * 0.5, 0, 0))

# Demon lord: horns, white mane, spiked shoulders, torn cape, trident staff.
func _lord(rig: CharacterRig, tone: String, accent: String, armed: bool) -> void:
	rig.add_part("body", cylinder(0.24, 0.76, 0.42, 6), Vector3(0, 0.74, 0), tone)
	rig.add_part("skirt", cylinder(0.4, 0.34, 0.22, 6), Vector3(0, 0.34, 0), "ink")
	rig.add_part("chest", prism(Vector3(0.5, 0.34, 0.12)), Vector3(0, 0.86, -0.3), accent, "character", Vector3(0.2, 0, PI))
	rig.add_part("head", sphere(0.23), Vector3(0, 1.36, -0.03), PAPER)
	rig.add_part("visor", fused("eyes_lord", func(): return [
		[box(Vector3(0.13, 0.05, 0.06)), _at(Vector3(-0.1, 0, 0), Vector3(0, 0, -0.4))],
		[box(Vector3(0.13, 0.05, 0.06)), _at(Vector3(0.1, 0, 0), Vector3(0, 0, 0.4))]]), Vector3(0, 1.38, -0.22), "bullet_enemy")
	rig.add_part("mane", fused("mane_lord", func():
		var pieces = [[sphere(0.25), _at(Vector3(0, 0.04, 0.07))]]
		for i in 7:
			var turn = (i - 3) * 0.5
			pieces.append([_spike(0.12, 0.5), _at(Vector3(sin(turn) * 0.22, 0.12, 0.1 + cos(turn) * 0.2), Vector3(1.15, turn, 0))])
		return pieces), Vector3(0, 1.36, -0.03), PAPER)
	rig.add_part("cape", fused("cape_lord", func():
		var pieces = [[box(Vector3(0.84, 0.75, 0.05)), _at(Vector3(0, -0.375, 0))]]
		for i in 4:
			pieces.append([prism(Vector3(0.21, 0.3, 0.05)), _at(Vector3(-0.315 + i * 0.21, -0.9, 0), Vector3(0, 0, PI))])
		return pieces), Vector3(0, 1.1, 0.26), "ink", "character", Vector3(-0.25, 0, 0))
	for side in [-1, 1]:
		var tag = _tag(side)
		rig.add_part("horn_" + tag, _spike(0.08, 0.5), Vector3(side * 0.24, 1.62, -0.08), accent, "character", Vector3(-0.35, 0, -side * 0.75))
		rig.add_part("shoulder_" + tag, _spike(0.17, 0.42, 4), Vector3(side * 0.44, 1.16, 0), "ink", "character", Vector3(0, 0, -side * 0.9))
		rig.add_part("hand_" + tag, box(Vector3(0.2, 0.2, 0.24)), Vector3(side * 0.56, 0.78, -0.24), tone)
		rig.add_part("foot_" + tag, box(Vector3(0.22, 0.16, 0.38)), Vector3(side * 0.2, 0.08, -0.03), "ink")
	if armed:
		var staff = rig.add_part("weapon", box(Vector3(0.07, 0.07, 1.3)), Vector3(0.56, 0.86, -0.4), "weapon", "weapon")
		for prong in [-1, 0, 1]:
			add(staff, _blade(0.12, 0.34 if prong == 0 else 0.26), Vector3(prong * 0.13, 0, -0.62), "weapon", accent, Vector3(0, -prong * 0.25, PI * 0.5))
		add(staff, box(Vector3(0.4, 0.08, 0.08)), Vector3(0, 0, -0.62), "weapon", "ink")
		add(staff, sphere(0.09), Vector3(0, 0, 0.68), "flash", "bullet_enemy")

# Paper face with two ink eyes; the animator blinks the visor.
func _face(rig: CharacterRig, height: float, skull: float, eyes: String) -> void:
	rig.add_part("head", sphere(skull), Vector3(0, height, 0), PAPER)
	rig.add_part("visor", fused("eyes%f" % skull, func(): return [
		[box(Vector3(skull * 0.34, skull * 0.44, 0.05)), _at(Vector3(-skull * 0.4, 0, 0))],
		[box(Vector3(skull * 0.34, skull * 0.44, 0.05)), _at(Vector3(skull * 0.4, 0, 0))]]), Vector3(0, height, -skull * 0.93), eyes)

# Square fists and boots at the usual places.
func _limbs(rig: CharacterRig, reach: float, height: float, fist: float, glove: String, stance: float) -> void:
	for side in [-1, 1]:
		rig.add_part("hand_" + _tag(side), box(Vector3(fist, fist, fist * 1.15)), Vector3(side * reach, height, -0.24), glove)
		rig.add_part("foot_" + _tag(side), box(Vector3(0.2, 0.16, 0.36)), Vector3(side * stance, 0.08, -0.03), "ink")

# Brush blaster. Seen from behind in weapon view: glowing cell and rear fin on
# top, the white barrel and its muzzle ring running away from the eye.
func _blaster(rig: CharacterRig, at: Vector3, accent: String, glow: String) -> void:
	var gun = rig.add_part("weapon", box(Vector3(0.13, 0.17, 0.46)), at, "weapon", "weapon")
	add(gun, cylinder(0.05, 0.4, -1.0, 6), Vector3(0, 0.02, -0.4), "weapon", PAPER, Vector3(-PI * 0.5, 0, 0))
	add(gun, cylinder(0.075, 0.07, -1.0, 6), Vector3(0, 0.02, -0.58), "weapon", accent, Vector3(-PI * 0.5, 0, 0))
	add(gun, box(Vector3(0.07, 0.05, 0.24)), Vector3(0, 0.1, -0.04), "flash", glow)
	add(gun, prism(Vector3(0.03, 0.07, 0.12)), Vector3(0, 0.12, 0.15), "weapon", accent)
	add(gun, box(Vector3(0.15, 0.06, 0.1)), Vector3(0, 0.0, 0.14), "weapon", accent)
	add(gun, box(Vector3(0.09, 0.2, 0.1)), Vector3(0, -0.15, 0.12), "weapon", "ink", Vector3(0.3, 0, 0))

func block(holder: Node3D, extent: Vector3, shape: String, role: String, color_key: String) -> void:
	# Same block, same dressing: a shift back must rebuild the same prop.
	var pick = int(absf(holder.position.x * 7.0 + holder.position.z * 13.0 + extent.x * 3.0))
	if shape == "cylinder":
		var radius = extent.x * 0.5
		var slim = extent.y / extent.x
		if role == "wall":
			_pillar(holder, radius, extent.y, color_key)
		elif slim >= 1.5:
			_bamboo(holder, radius, extent.y, color_key, pick)
		elif slim < 0.6:
			_drum(holder, radius, extent.y, color_key)
		elif pick % 2 == 0:
			_lantern(holder, radius, extent.y, color_key)
		else:
			_barrel(holder, radius, extent.y, color_key)
		return
	# Long blocks are built along X inside a turned frame.
	var frame = holder
	var along = extent
	if extent.z > extent.x:
		frame = Node3D.new()
		frame.rotation.y = PI * 0.5
		holder.add_child(frame)
		along = Vector3(extent.z, extent.y, extent.x)
	var long = along.x >= along.z * 2.0
	if role == "wall":
		if long:
			_shoji(frame, along, color_key)
		else:
			_storehouse(frame, along, color_key)
	elif long:
		_cargo(frame, along, color_key, pick)
	elif along.z >= 2.4:
		_dais(frame, along, color_key)
	else:
		_crate(frame, along, color_key, pick)

# Dojo wall: stone footing, paper panels between ink posts, tiled ridge on top.
func _shoji(frame: Node3D, size: Vector3, key: String) -> void:
	var foot = minf(0.3, size.y * 0.2)
	var beam = minf(0.24, size.y * 0.15)
	add(frame, box(Vector3(size.x, foot, size.z)), Vector3(0, foot * 0.5, 0), "wall", key)
	add(frame, box(Vector3(size.x - 0.16, size.y - foot - beam, size.z * 0.5)), Vector3(0, (size.y + foot - beam) * 0.5, 0), "wall", PAPER)
	add(frame, box(Vector3(size.x, beam, size.z * 0.8)), Vector3(0, size.y - beam * 0.5, 0), "wall", key)
	var posts = maxi(2, int(round(size.x / 2.0)) + 1)
	for i in posts:
		add(frame, box(Vector3(0.18, size.y - foot - beam, size.z * 0.72)), Vector3(lerpf(-size.x * 0.5 + 0.09, size.x * 0.5 - 0.09, i / float(posts - 1)), (size.y + foot - beam) * 0.5, 0), "wall", "ink")
	_ridge(frame, size, key)

# Squat plaster store with a tiled roof.
func _storehouse(frame: Node3D, size: Vector3, key: String) -> void:
	var foot = minf(0.3, size.y * 0.2)
	add(frame, box(Vector3(size.x, foot, size.z)), Vector3(0, foot * 0.5, 0), "wall", "ink")
	add(frame, box(Vector3(size.x * 0.9, size.y - foot, size.z * 0.9)), Vector3(0, (size.y + foot) * 0.5, 0), "wall", key)
	add(frame, box(Vector3(size.x * 0.4, (size.y - foot) * 0.6, size.z * 0.94)), Vector3(0, foot + (size.y - foot) * 0.3, 0), "wall", PAPER)
	_ridge(frame, size, key)

# Tiled ridge along a wall, as tall as the ceiling allows.
func _ridge(frame: Node3D, size: Vector3, key: String) -> void:
	var rise = snappedf(minf(minf(size.z * 0.42, 0.5), CEILING - size.y), 0.05)
	if rise >= 0.1:
		add(frame, prism(Vector3(size.z, rise, size.x)), Vector3(0, size.y + rise * 0.5, 0), "wall", key, Vector3(0, PI * 0.5, 0))

# Shrine pillar: stone foot, tapered shaft, paper rope with four zigzag
# streamers, flared cap.
func _pillar(holder: Node3D, radius: float, height: float, key: String) -> void:
	var foot = minf(0.3, height * 0.2)
	add(holder, cylinder(radius, foot, radius * 0.9, 8), Vector3(0, foot * 0.5, 0), "wall", "ink")
	add(holder, cylinder(radius * 0.78, height - foot, radius * 0.66, 10), Vector3(0, (height + foot) * 0.5, 0), "wall", key)
	add(holder, cylinder(radius * 0.84, 0.16, -1.0, 10), Vector3(0, height * 0.66, 0), "wall", PAPER)
	for i in 4:
		var turn = PI * 0.25 + i * PI * 0.5
		add(holder, prism(Vector3(0.22, 0.34, 0.05)), Vector3(sin(turn) * radius * 0.86, height * 0.66 - 0.24, cos(turn) * radius * 0.86), "wall", PAPER, Vector3(0, turn, PI))
	add(holder, cylinder(radius * 0.7, 0.3, radius, 8), Vector3(0, height - 0.15, 0), "wall", "ink")

# Stone lantern: foot, post, shelf, paper light box, hexagonal roof, finial.
func _lantern(holder: Node3D, radius: float, height: float, key: String) -> void:
	add(holder, cylinder(radius, height * 0.14, radius * 0.8, 6), Vector3(0, height * 0.07, 0), "prop", key)
	add(holder, cylinder(radius * 0.34, height * 0.44, radius * 0.28, 6), Vector3(0, height * 0.36, 0), "prop", key)
	add(holder, cylinder(radius * 0.5, height * 0.1, radius * 0.8, 6), Vector3(0, height * 0.63, 0), "prop", key)
	add(holder, cylinder(radius * 0.52, height * 0.26, -1.0, 4), Vector3(0, height * 0.81, 0), "flash", PAPER, Vector3(0, PI * 0.25, 0))
	add(holder, cylinder(radius, height * 0.3, radius * 0.12, 6), Vector3(0, height * 1.09, 0), "prop", key)
	add(holder, sphere(radius * 0.14), Vector3(0, height * 1.27, 0), "prop", "ink")

# Sake barrel: bulging staves, paper wrap, rope rings, dark lid.
func _barrel(holder: Node3D, radius: float, height: float, key: String) -> void:
	add(holder, _cask(), Vector3.ZERO, "prop", key).scale = Vector3(radius * 2.0, height, radius * 2.0)
	add(holder, cylinder(radius * 0.99, height * 0.34, -1.0, 12), Vector3(0, height * 0.5, 0), "prop", PAPER)
	for level in [0.12, 0.88]:
		add(holder, cylinder(radius * 0.9, 0.09, -1.0, 12), Vector3(0, height * level, 0), "prop", "ink")
	add(holder, cylinder(radius * 0.76, 0.06, -1.0, 12), Vector3(0, height + 0.01, 0), "prop", "ink")

# Bamboo grove in a planter: uneven canes, taller than the collision.
func _bamboo(holder: Node3D, radius: float, height: float, key: String, pick: int) -> void:
	add(holder, cylinder(radius, 0.26, radius * 0.86, 6), Vector3(0, 0.13, 0), "prop", "ink")
	var cane = fused("cane", func(): return [
		[cylinder(0.42, 0.96, -1.0, 6), _at(Vector3(0, 0.48, 0))],
		[cylinder(0.5, 0.03, -1.0, 6), _at(Vector3(0, 0.34, 0))],
		[cylinder(0.5, 0.03, -1.0, 6), _at(Vector3(0, 0.68, 0))],
		[cylinder(0.42, 0.14, 0.0, 6), _at(Vector3(0, 1.03, 0))]])
	for i in 5:
		var turn = i * TAU / 5.0 + pick
		var spread = radius * (0.5 if i > 0 else 0.0)
		var node = add(holder, cane, Vector3(sin(turn) * spread, 0.2, cos(turn) * spread), "prop", key, Vector3(0.05 * sin(turn * 3.0), 0, 0.05 * cos(turn * 2.0)))
		var thick = radius * (0.34 - 0.03 * ((i + pick) % 3))
		node.scale = Vector3(thick, (minf(height * 1.25, maxf(height, CEILING)) - 0.2) / 1.1 * (1.0 - 0.1 * ((i * 2 + pick) % 4)), thick)

# Taiko lying flat: wide body, paper skin, studded rim.
func _drum(holder: Node3D, radius: float, height: float, key: String) -> void:
	add(holder, cylinder(radius * 0.9, height * 0.96, radius * 0.98, 12), Vector3(0, height * 0.48, 0), "prop", key)
	add(holder, cylinder(radius, height * 0.16, -1.0, 12), Vector3(0, height * 0.86, 0), "prop", "ink")
	add(holder, cylinder(radius * 0.86, 0.06, -1.0, 12), Vector3(0, height * 0.96, 0), "prop", PAPER)

# Strapped crate; every other one carries a smaller box and a paper tag.
func _crate(frame: Node3D, size: Vector3, key: String, pick: int) -> void:
	add(frame, box(Vector3(size.x * 0.92, size.y, size.z * 0.92)), Vector3(0, size.y * 0.5, 0), "prop", key)
	add(frame, box(Vector3(size.x, size.y * 1.02, size.z * 0.14)), Vector3(0, size.y * 0.51, 0), "prop", "ink")
	add(frame, box(Vector3(size.x * 0.14, size.y * 1.02, size.z)), Vector3(0, size.y * 0.51, 0), "prop", "ink")
	if pick % 2 == 0:
		add(frame, box(Vector3(size.x, size.y, size.z) * 0.5), Vector3(size.x * 0.12, size.y * 1.27, -size.z * 0.1), "prop", key, Vector3(0, 0.5, 0))
		add(frame, box(Vector3(size.x * 0.3, 0.03, size.z * 0.2)), Vector3(size.x * 0.12, size.y * 1.53, -size.z * 0.1), "prop", PAPER, Vector3(0, 0.5, 0))
	else:
		add(frame, box(Vector3(size.x * 0.34, 0.03, size.z * 0.24)), Vector3(size.x * 0.2, size.y + 0.03, size.z * 0.18), "prop", PAPER, Vector3(0, -0.3, 0))

# Long strapped chest with tubs and a rolled mat on the lid.
func _cargo(frame: Node3D, size: Vector3, key: String, pick: int) -> void:
	var deck = size.y * 0.62
	add(frame, box(Vector3(size.x * 0.97, deck, size.z * 0.9)), Vector3(0, deck * 0.5, 0), "prop", key)
	for side in [-1, 1]:
		add(frame, box(Vector3(0.14, deck + 0.04, size.z)), Vector3(side * size.x * 0.3, deck * 0.5 + 0.02, 0), "prop", "ink")
	var tubs = clampi(int(size.x / 1.6), 2, 3)
	var tub = minf(size.z * 0.36, size.x / (tubs * 2.4))
	for i in tubs:
		var at = Vector3(lerpf(-size.x * 0.36, size.x * 0.36, i / float(tubs - 1)), deck, 0)
		if (i + pick) % 3 == 0:
			add(frame, cylinder(tub * 0.6, size.z * 0.84, -1.0, 8), at + Vector3(0, tub * 0.6, 0), "prop", PAPER, Vector3(PI * 0.5, 0, 0))
		else:
			add(frame, cylinder(tub * 0.86, size.y * 0.5, tub, 8), at + Vector3(0, size.y * 0.25, 0), "prop", key)
			add(frame, cylinder(tub * 0.8, 0.05, -1.0, 8), at + Vector3(0, size.y * 0.5 + 0.01, 0), "prop", "ink")

# Stepped platform with a festival drum on its stand.
func _dais(frame: Node3D, size: Vector3, key: String) -> void:
	var step = size.y * 0.3
	add(frame, box(Vector3(size.x, step, size.z)), Vector3(0, step * 0.5, 0), "prop", "ink")
	add(frame, box(Vector3(size.x * 0.84, step, size.z * 0.84)), Vector3(0, step * 1.5, 0), "prop", key)
	var drum = minf(size.x, size.z) * 0.27
	var top = step * 2.0 + drum * 1.25
	for side in [-1, 1]:
		add(frame, box(Vector3(0.12, drum * 1.3, drum * 1.5)), Vector3(side * drum * 0.7, step * 2.0 + drum * 0.65, 0), "prop", "ink")
		add(frame, cylinder(drum * 0.9, 0.06, -1.0, 12), Vector3(side * (drum * 1.04), top, 0), "prop", PAPER, Vector3(0, 0, PI * 0.5))
	add(frame, _cask(), Vector3(drum, top, 0), "prop", key, Vector3(0, 0, PI * 0.5)).scale = Vector3(drum * 2.0, drum * 2.0, drum * 2.0)

func pickup(holder: Node3D, what: String) -> void:
	match what:
		"health":
			# Medicine gourd.
			add(holder, sphere(0.24), Vector3(0, -0.08, 0), "pickup", "pickup_health")
			add(holder, sphere(0.16), Vector3(0, 0.22, 0), "pickup", "pickup_health")
			add(holder, cylinder(0.13, 0.07, -1.0, 8), Vector3(0, 0.1, 0), "pickup", "ink")
			add(holder, cylinder(0.05, 0.12, 0.07, 6), Vector3(0, 0.4, 0), "pickup", "prop")
			add(holder, box(Vector3(0.16, 0.2, 0.02)), Vector3(0.17, -0.02, 0.17), "pickup", PAPER, Vector3(0, PI * 0.25, 0.2))
		"scatter":
			# Four-point shuriken, tipped so it reads from above and from the side.
			add(holder, fused("shuriken", func():
				var pieces = [[cylinder(0.13, 0.07, -1.0, 8), _at(Vector3.ZERO, Vector3(PI * 0.5, 0, 0))]]
				for i in 4:
					pieces.append([prism(Vector3(0.2, 0.3, 0.05)), _at(Vector3(0, 0.2, 0).rotated(Vector3.BACK, i * PI * 0.5), Vector3(0, 0, i * PI * 0.5))])
				return pieces), Vector3.ZERO, "pickup", "pickup_ammo", Vector3(-0.9, 0, 0))
			add(holder, cylinder(0.06, 0.09, -1.0, 8), Vector3.ZERO, "pickup", "ink", Vector3(PI * 0.5 - 0.9, 0, 0))
		"rapid":
			# Sealed scroll.
			add(holder, cylinder(0.14, 0.5, -1.0, 10), Vector3.ZERO, "pickup", "pickup_ammo", Vector3(0, 0, PI * 0.5 - 0.3))
			add(holder, cylinder(0.05, 0.7, -1.0, 6), Vector3.ZERO, "pickup", "ink", Vector3(0, 0, PI * 0.5 - 0.3))
			add(holder, cylinder(0.15, 0.14, -1.0, 10), Vector3.ZERO, "pickup", PAPER, Vector3(0, 0, PI * 0.5 - 0.3))
		_:
			# Festival rocket on its stick.
			var tilt = Vector3(0, 0, -0.6)
			var axis = Vector3.UP.rotated(Vector3.BACK, -0.6)
			add(holder, cylinder(0.13, 0.36, -1.0, 8), axis * 0.02, "pickup", "pickup_ammo", tilt)
			add(holder, cone(0.17, 0.24), axis * 0.32, "pickup", "ink", tilt)
			add(holder, cylinder(0.14, 0.07, -1.0, 8), axis * -0.1, "pickup", PAPER, tilt)
			add(holder, cylinder(0.025, 0.4, -1.0, 4), axis * -0.36, "pickup", "ink", tilt)

## Kunai: a flat diamond blade ahead of a short grip. Normals are smoothed
## over the whole blade so the bullet shader inks its edge, not its face.
func bullet_mesh() -> Mesh:
	return shared("kunai", func():
		var tool = SurfaceTool.new()
		tool.append_from(cylinder(0.46, 0.62, 0.0, 4), 0, _at(Vector3(0, 0, -0.19), Vector3(-PI * 0.5, 0, 0), Vector3(1, 1, 0.45)))
		tool.append_from(cylinder(0.46, 0.24, 0.0, 4), 0, _at(Vector3(0, 0, 0.24), Vector3(PI * 0.5, 0, 0), Vector3(1, 1, 0.45)))
		tool.append_from(box(Vector3(0.12, 0.12, 0.16)), 0, _at(Vector3(0, 0, 0.42)))
		tool.generate_normals()
		return tool.commit())

func decorate(holder: Node3D, arena: Arena) -> void:
	var half = arena.size * 0.5
	var back = -(half.y + 5.0)
	# Red sun over three peaks, far behind the back wall.
	add(holder, cylinder(10.0, 0.2, -1.0, 28), Vector3(4, 11, back - 34), "flash", "ui_danger", Vector3(PI * 0.5, 0, 0))
	for peak in [[-20.0, 15.0, 13.0], [2.0, 20.0, 20.0], [24.0, 14.0, 11.0]]:
		add(holder, cylinder(peak[1], peak[2], 0.0, 7), Vector3(peak[0], peak[2] * 0.5 - 0.5, back - 24), "wall", "wall")
		add(holder, cylinder(peak[1] * 0.31, peak[2] * 0.3, 0.0, 7), Vector3(peak[0], peak[2] * 0.86 - 0.5, back - 24), "wall", PAPER)
	# Town roofs on three sides; the row nearest the top-down camera stays low.
	var count = int(arena.size.x / 9.0)
	for i in count:
		var x = lerpf(-half.x + 3.0, half.x - 3.0, i / float(count - 1))
		if count % 2 == 1 and i == count / 2:
			_torii(holder, Vector3(x, 0, back + 0.5))
		else:
			_house(holder, Vector3(x, 0, back - (i % 2) * 1.5), Vector3(6.5, 3.4 + (i % 2) * 1.2, 4.5), 0.0)
		_house(holder, Vector3(x * 0.8, 0, half.y + 5.0), Vector3(7.0, 1.6, 4.0), 0.0)
	for side in [-1, 1]:
		for i in 2:
			_house(holder, Vector3(side * (half.x + 6.5 + i), 0, lerpf(-half.y * 0.5, half.y * 0.5, float(i))), Vector3(7.0, 3.0 + i, 4.5), PI * 0.5)
		_cherry(holder, Vector3(side * (half.x + 5.2), 0, -half.y - 2.6), 1.25)
		_cherry(holder, Vector3(side * (half.x + 4.8), 0, 0), 1.0)
		_cherry(holder, Vector3(side * (half.x + 4.4), 0, half.y + 2.4), 0.8)
		# Festival lanterns on a line along each side wall.
		_lantern_line(holder, Vector3(side * (half.x + 2.7), 3.3, 0), half.y * 2.0, PI * 0.5)
	_lantern_line(holder, Vector3(0, 3.5, -half.y - 2.7), half.x * 2.0, 0.0)

func _house(holder: Node3D, at: Vector3, size: Vector3, turn: float) -> void:
	var euler = Vector3(0, turn, 0)
	add(holder, box(size), at + Vector3(0, size.y * 0.5, 0), "wall", "floor_alt", euler)
	add(holder, prism(Vector3(size.z + 1.4, size.z * 0.42, size.x + 1.0)), at + Vector3(0, size.y + size.z * 0.21, 0), "wall", "wall", Vector3(0, turn + PI * 0.5, 0))

func _torii(holder: Node3D, at: Vector3) -> void:
	for side in [-1, 1]:
		add(holder, cylinder(0.3, 5.0, 0.24, 8), at + Vector3(side * 2.2, 2.5, 0), "prop", VERMILION, Vector3(0, 0, side * 0.04))
	add(holder, box(Vector3(5.4, 0.3, 0.36)), at + Vector3(0, 4.0, 0), "prop", VERMILION)
	add(holder, box(Vector3(6.6, 0.4, 0.5)), at + Vector3(0, 5.1, 0), "prop", "ink")

func _cherry(holder: Node3D, at: Vector3, grow: float) -> void:
	add(holder, cylinder(0.34 * grow, 2.6 * grow, 0.16 * grow, 6), at + Vector3(0, 1.3 * grow, 0), "prop", "ink", Vector3(0, 0, 0.08))
	var crown = add(holder, fused("blossom", func():
		var puff = SphereMesh.new()
		puff.radius = 1.0
		puff.height = 1.7
		puff.radial_segments = 8
		puff.rings = 4
		return [[puff, _at(Vector3.ZERO)], [puff, _at(Vector3(0.95, -0.25, 0.3), Vector3.ZERO, Vector3.ONE * 0.7)],
			[puff, _at(Vector3(-0.85, -0.3, -0.35), Vector3.ZERO, Vector3.ONE * 0.75)], [puff, _at(Vector3(0.1, 0.5, -0.5), Vector3.ZERO, Vector3.ONE * 0.6)]]),
		at + Vector3(0, 3.3 * grow, 0), "prop", "bullet_enemy")
	crown.scale = Vector3.ONE * 1.15 * grow

func _lantern_line(holder: Node3D, at: Vector3, length: float, turn: float) -> void:
	var along = Vector3.RIGHT.rotated(Vector3.UP, turn)
	add(holder, box(Vector3(length + 2.0, 0.04, 0.04)), at, "prop", "ink", Vector3(0, turn, 0))
	for i in 4:
		add(holder, sphere(0.32, 1.25), at + along * lerpf(-length * 0.36, length * 0.36, i / 3.0) + Vector3(0, -0.42, 0), "flash", "pickup_ammo" if i % 2 == 0 else "ui_danger")

func _tag(side: int) -> String:
	return "l" if side < 0 else "r"

func _at(origin: Vector3, euler: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(euler) * Basis.from_scale(size), origin)

## Several meshes baked into one: one part, one colour, one hit flash. Each
## piece is [mesh, transform]; it also moves a pivot away from the centre.
func fused(key: String, pieces: Callable) -> Mesh:
	return shared("fused:" + key, func():
		var tool = SurfaceTool.new()
		for piece in pieces.call():
			tool.append_from(piece[0], 0, piece[1])
		return tool.commit())

## Wedge: triangle in XY with the apex up, extruded along Z.
func prism(extent: Vector3) -> Mesh:
	return shared("prism%s" % extent, func():
		var mesh = PrismMesh.new()
		mesh.size = extent
		return mesh)

# Bulging barrel body, unit sized with its base at the origin.
func _cask() -> Mesh:
	return fused("cask", func(): return [
		[cylinder(0.42, 0.5, 0.5, 12), _at(Vector3(0, 0.25, 0))],
		[cylinder(0.5, 0.5, 0.42, 12), _at(Vector3(0, 0.75, 0))]])

func _spike(radius: float, height: float, sides: int = 5) -> Mesh:
	return cylinder(radius, height, 0.0, sides)

# Flat tapered cloth or hair, pivot at the wide end, trailing along +Z.
func _strip(width: float, length: float, thick: float = 0.04) -> Mesh:
	return fused("strip%f/%f/%f" % [width, length, thick], func(): return [
		[prism(Vector3(width, length, thick)), _at(Vector3(0, 0, length * 0.5), Vector3(PI * 0.5, 0, 0))]])

# Flat blade, pivot at the grip, point along -Z.
func _blade(width: float, length: float) -> Mesh:
	return fused("blade%f/%f" % [width, length], func(): return [
		[prism(Vector3(width, length, 0.03)), _at(Vector3(0, 0, -length * 0.5), Vector3(-PI * 0.5, 0, 0))]])
