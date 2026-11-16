extends DimensionAnimator
## Cartoon / Comic: rubber-hose squash and stretch. Everything is smooth and
## elastic: the body keeps its volume while it bounces, decaying timers
## (recoil, hurt, dash) ring like springs instead of fading, and loose parts
## (head, hands, horns) trail the body by a slice of the walk cycle.

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
	_carry(rig, Vector3(0, snap * 0.04, snap * 0.26))
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

	var factor = _volume(tall) * Vector3(lerpf(thin, along, axis.x), thin, lerpf(thin, along, axis.z))
	rig.squash(factor * _life(rig))

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
