extends DimensionAnimator
## Cartoon / Comic: rubber-hose squash and stretch. Everything is smooth and
## elastic: the body keeps its volume while it bounces, decaying timers
## (recoil, hurt, dash) ring like springs instead of fading, and loose parts
## (head, hands, horns) trail the body by a slice of the walk cycle.
## The pack's builder adds more loose parts (ears, hat, crest, tail, cape, jaw,
## antenna, wind-up key): they trail a beat later still, then ride the part
## named in their "on" meta, and the noodle limbs are re-spanned last.

const Shapes = preload("builder.gd")

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	var go = rig.speed_ratio
	var slide = Vector3(rig.move_local.x, 0, rig.move_local.z)

	# Bouncy walk. cos(2 * phase) is -1 on each footfall and +1 mid-stride.
	walk(rig, phase, 1.5)
	var bounce = cos(phase * 2.0)
	var late = cos(phase * 2.0 - 1.1)
	var sway = sin(phase - 0.6)
	rig.position.y = (0.5 + 0.5 * bounce) * 0.16 * go
	var tall = 1.0 + bounce * 0.15 * go
	# Idle: slow breathing, out of step between characters.
	var breath = sin(time * 3.2 + rig.variation * TAU)
	tall += breath * 0.035 * (1.0 - go)

	# Follow-through: head and hands arrive late and overshoot.
	rig.move("head", Vector3(sway * 0.04, late * 0.07, 0) * go)
	rig.turn("head", Vector3(late * 0.14, 0, sway * 0.16) * go + Vector3(breath * 0.03, 0, sin(time * 1.6 + rig.variation * 9.0) * 0.05) * (1.0 - go))
	rig.move("hand_l", Vector3(-absf(sway) * 0.06, late * 0.09, -sway * 0.2) * go)
	_carry(rig, Vector3(0, late * 0.05, sway * 0.06) * go)
	for side in ["l", "r"]:
		rig.turn("horn_" + side, Vector3(late * 0.2 * go, 0, (sway * 0.25 if side == "l" else -sway * 0.25) * go))

	# Recoil: the gun arm snaps back and springs past rest, the body rocks.
	var snap = _spring(rig.recoil, 6.0)
	# Seen from the weapon the kick is shorter, or the glove fills the screen.
	_carry(rig, Vector3(0, snap * 0.04, snap * (0.1 if rig.first_person else 0.26)))
	rig.stretch("weapon", Vector3(1.0 + snap * 0.25, 1.0 + snap * 0.25, 1.0 - snap * 0.3))
	rig.move("head", Vector3(0, 0, _spring(rig.recoil, 3.5) * 0.07))
	rig.move("hand_l", Vector3(-snap * 0.05, snap * 0.05, 0))

	# Hurt: jelly wobble, head knocked back, hands thrown up.
	var jelly = _spring(rig.hurt, 9.0)
	tall *= 1.0 - jelly * 0.22
	rig.turn("head", Vector3(-rig.hurt * 0.45, 0, jelly * 0.25))
	rig.move("hand_l", Vector3(-rig.hurt * 0.12, rig.hurt * 0.3, 0))
	rig.move("hand_r", Vector3(rig.hurt * 0.08, 0, 0))
	for side in ["l", "r"]:
		rig.turn("horn_" + side, Vector3(0, 0, jelly * 0.5))

	# Dash: smear along the travel direction, loose parts dragged behind, then
	# a springy settle as the timer runs out.
	var smear = _spring(rig.dash, 4.5)
	var along = 1.0 + smear * 0.55
	var thin = 1.0 / sqrt(maxf(along, 0.5))
	var axis = Vector3(slide.x * slide.x, 0, slide.z * slide.z) / maxf(slide.length_squared(), 0.001)
	var drag = -slide * rig.dash
	rig.move("head", drag * 0.22)
	rig.move("hand_l", drag * 0.4)
	rig.move("hand_r", drag * 0.15)
	rig.move("foot_l", drag * 0.3)
	rig.move("foot_r", drag * 0.3)

	# Lean hard into the run and harder into a dash.
	lean(rig, 0.3)
	rig.rotation.x += slide.z * rig.dash * 0.45 - snap * 0.07
	rig.rotation.z += -slide.x * rig.dash * 0.45

	_loose(rig, time, phase, snap, jelly, drag)
	_attach(rig)

	var factor = _volume(tall) * Vector3(lerpf(thin, along, axis.x), thin, lerpf(thin, along, axis.z))
	rig.squash(factor * _life(rig))

## Follow-through for the builder's extra parts: a beat behind the head,
## bigger swings, and everything flies up when hit. Missing parts are skipped.
func _loose(rig: CharacterRig, time: float, phase: float, snap: float, jelly: float, drag: Vector3) -> void:
	var go = rig.speed_ratio
	var later = cos(phase * 2.0 - 2.2)
	var swing = sin(phase - 1.4)
	var idle = sin(time * 2.3 + rig.variation * 5.0) * (1.0 - go)
	var pop = absf(jelly)
	# Ears flap up and down with each step and stream back in a run.
	for side in [-1.0, 1.0]:
		var ear = "ear_l" if side < 0 else "ear_r"
		rig.turn(ear, Vector3((0.35 + later * 0.3) * go + rig.dash * 0.7 + snap * 0.3, 0, side * (later * 0.3 * go - pop * 0.7 + idle * 0.06)))
		rig.stretch(ear, Vector3(1, 1.0 + pop * 0.3, 1))
	# The hat hops on every footfall, tips with the sway and jumps off when hit.
	rig.move("hat", Vector3(0, maxf(0.0, -later) * 0.07 * go + pop * 0.28 + maxf(0.0, -snap) * 0.05, 0) + drag * 0.2)
	rig.turn("hat", Vector3(later * 0.14 * go - snap * 0.2, 0, swing * 0.16 * go + jelly * 0.35 + idle * 0.03))
	# Feathers, tails and capes trail behind and whip on a dash.
	rig.turn("crest", Vector3((0.5 + later * 0.3) * go + rig.dash * 0.8 + pop * 0.6, 0, swing * 0.3 * go + idle * 0.08))
	rig.turn("tail", Vector3((later * 0.35 - 0.3) * go - rig.dash * 0.6, swing * 0.5 * go + idle * 0.25, 0))
	rig.stretch("tail", Vector3.ONE * (1.0 + pop * 0.4))
	rig.turn("cape", Vector3((0.45 + later * 0.12) * go + rig.dash * 0.8 + pop * 0.5 + idle * 0.04, 0, swing * 0.1 * go))
	rig.stretch("cape", Vector3(1.0 + go * 0.12, 1, 1))
	# The jaw chatters in a run, drops when hit and barks with each shot.
	rig.move("jaw", Vector3(0, -(maxf(0.0, later) * 0.03 * go + rig.hurt * 0.12 + maxf(0.0, snap) * 0.08), 0))
	rig.turn("jaw", Vector3(-(rig.hurt * 0.3 + maxf(0.0, snap) * 0.25), 0, 0))
	rig.turn("antenna", Vector3(later * 0.4 * go + snap * 0.5 + rig.dash * 0.8, 0, swing * 0.5 * go + jelly * 0.8 + idle * 0.12))
	# The wind-up key never stops; it spins faster on the move.
	rig.turn("key", Vector3(0, 0, time * 2.5 + phase))
	# Gloves squash against the gun on the kick and balloon when hit.
	var puff = snap * (0.12 if rig.first_person else 0.3)
	rig.stretch("hand_r", Vector3(1.0 + puff, 1.0 + puff, 1.0 - puff))
	rig.stretch("hand_l", Vector3.ONE * (1.0 + pop * 0.35))
	if rig.kind == "runner":
		# Wings flap, the neck cranes forward at speed.
		for side in [-1.0, 1.0]:
			rig.turn("hand_l" if side < 0 else "hand_r", Vector3(0, 0, side * (0.5 + cos(phase * 2.0) * 0.5) * go))
		rig.move("head", Vector3(0, -0.06, -0.14) * go)

## Carries parts on the part they are built onto, then stretches the hoses
## between their two ends. Runs after every other part has its pose.
func _attach(rig: CharacterRig) -> void:
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var base: String = node.get_meta("on", "")
		if rig.parts.has(base):
			node.transform = rig.parts[base].transform * rig.rest[base].affine_inverse() * node.transform
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var to: String = node.get_meta("to", "")
		if not rig.parts.has(to):
			continue
		var from: Vector3 = node.get_meta("from")
		var root: String = node.get_meta("root", "")
		if rig.parts.has(root):
			from = rig.parts[root].transform * rig.rest[root].affine_inverse() * from
		Shapes.span(node, from, rig.parts[to].transform * node.get_meta("tip", Vector3.ZERO))

## Moves the gun hand and the weapon together so the grip never slips.
func _carry(rig: CharacterRig, offset: Vector3) -> void:
	rig.move("hand_r", offset)
	rig.move("weapon", offset)

## Turns a timer that decays 1 -> 0 into a ringing spring: full kick at 1,
## then overshoots through zero with shrinking swings.
func _spring(level: float, swing: float) -> float:
	return level * cos((1.0 - level) * swing)

## Height factor -> scale that keeps the volume: shorter means wider.
func _volume(tall: float) -> Vector3:
	var wide = 1.0 / sqrt(maxf(tall, 0.05))
	return Vector3(wide, tall, wide)

## Spawn: squashed flat, shoots up too tall, wobbles into shape.
## Death: a startled stretch, then flattened into a pancake that jiggles.
func _life(rig: CharacterRig) -> Vector3:
	var born = rig.spawn
	var grow = smoothstep(0.0, 0.35, born)
	var up = 1.0 + pow(2.0, -7.0 * born) * sin(born * 11.0 - 1.4) * 1.1
	var out = Vector3(grow * (2.0 - clampf(up, 0.6, 1.6)), grow * maxf(up, 0.02), grow * (2.0 - clampf(up, 0.6, 1.6)))
	if rig.death > 0.0:
		var gasp = sin(minf(rig.death / 0.25, 1.0) * PI) * 0.3
		var splat = smoothstep(0.2, 0.55, rig.death)
		var jiggle = sin(rig.death * 22.0) * 0.12 * splat * (1.0 - rig.death)
		var wide = lerpf(1.0 - gasp * 0.4, 1.75, splat) + jiggle
		out *= Vector3(wide, lerpf(1.0 + gasp, 0.07, splat), wide)
	return out
