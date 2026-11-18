extends DimensionAnimator
## Stick-fight motion: crude frame-by-frame doodle animation. Everything snaps
## between a few held poses (stepped on ~9 fps), limbs swing hard about their
## joints like a flip-book brawler, a shot throws the whole arm up in a big
## wind-up and follow-through, a hit sends the figure into a comedic flail, and
## death crumples it into a splayed heap of lines. Stateless: every value comes
## off the rig's own fields, and missing parts are skipped.

const FPS = 9.0        # held drawings per second
const STEP = PI / 3.0  # six held poses per walk cycle
const CENTRE = Vector3(0, 0.8, 0)

func animate(rig: CharacterRig, _delta: float) -> void:
	# Each figure holds on its own frame so a crowd never flips in unison.
	var frame = floorf(rig.clock * FPS + rig.variation * 4.0)
	var phase = _stepped(rig.phase, STEP, 0.28)
	pose(rig, frame / FPS, phase)

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	var pace = minf(rig.speed_ratio, 1.0)
	var shot = _held(rig.recoil, 0.5)
	var hurt = _held(rig.hurt, 0.45)
	var dash = _held(rig.dash, 0.3)
	var armed = rig.parts.has("weapon")
	var heading = rig.move_local * Vector3(1, 0, 1)

	# Rubber-hose gait: legs swing wide about the hips, arms counter-swing, the
	# whole thing bobs and twists. A secondary wobble keeps the lines floppy.
	var stride = sin(phase) * pace
	var wobble = sin(phase * 2.0 + time * 4.0) * pace * 0.18
	var weight = absf(stride)
	rig.turn("foot_l", Vector3(stride * 0.95, 0, 0))
	rig.turn("foot_r", Vector3(-stride * 0.95, 0, 0))
	rig.turn("hand_l", Vector3(-stride * 0.8 + wobble, 0, 0))
	if not armed:
		rig.turn("hand_r", Vector3(stride * 0.8 - wobble, 0, 0))
	rig.move("body", Vector3(0, -weight * 0.06, 0))
	rig.move("head", Vector3(0, -weight * 0.07, 0))
	rig.turn("body", Vector3(0, stride * 0.12, 0))

	# Lean into the travel; a dash throws the drawing right over.
	rig.rotation.x = heading.z * (0.14 * pace + 0.4 * dash)
	rig.rotation.z = -heading.x * (0.14 * pace + 0.4 * dash)

	# Idle: a little breathing bob, out of step between figures; antenna sways.
	var idle = sin(time * 2.4 + rig.variation * TAU) * (1.0 - pace)
	rig.move("head", Vector3(0, idle * 0.02, 0))
	rig.turn("antenna", Vector3(idle * 0.5 + stride * 0.4, 0, stride * 0.5 + idle * 0.6))

	_shoot(rig, shot, armed)
	_flail(rig, hurt, time)

	var born = clampf(rig.spawn, 0.0, 1.0)
	var size = Vector3(1.0 - 0.18 * dash + 0.14 * hurt, 1.0 + 0.28 * dash - 0.12 * hurt, 1.0 - 0.18 * dash + 0.14 * hurt)
	if rig.dead:
		size = _crumple(rig, size)
	elif born < 1.0:
		size = _sketch_in(rig, size)
	rig.squash(size.max(Vector3.ONE * 0.001))
	rig.position.y += -weight * 0.02

# The shot: the gun arm flings up and back in a big wind-up, the torso rocks,
# then it rides the follow-through down as recoil decays.
func _shoot(rig: CharacterRig, shot: float, armed: bool) -> void:
	if shot <= 0.0:
		return
	if armed:
		rig.turn("weapon", Vector3(-1.1 * shot, 0, 0))
		rig.move("weapon", Vector3(0, 0.12 * shot, 0.14 * shot))
		rig.turn("hand_r", Vector3(-1.1 * shot, 0, 0))
	else:
		# Unarmed melee: the right arm throws a round punch forward.
		rig.turn("hand_r", Vector3(1.3 * shot, 0, 0))
	rig.turn("body", Vector3(0.18 * shot, 0, 0))
	rig.move("head", Vector3(0, 0, 0.06 * shot))

# Comedic hit: arms fly up and out, head snaps back, the whole drawing shakes
# while the pose is held.
func _flail(rig: CharacterRig, hurt: float, time: float) -> void:
	if hurt <= 0.0:
		return
	rig.turn("hand_l", Vector3(-2.2 * hurt, 0, -0.6 * hurt))
	rig.turn("hand_r", Vector3(-2.0 * hurt, 0, 0.6 * hurt))
	rig.turn("foot_l", Vector3(0.5 * hurt, 0, -0.3 * hurt))
	rig.turn("foot_r", Vector3(0.5 * hurt, 0, 0.3 * hurt))
	rig.rotation.x += -0.4 * hurt
	rig.turn("head", Vector3(-0.4 * hurt, 0, 0))
	if hurt > 0.5:
		rig.position.x += 0.05 if int(time * FPS) % 2 == 0 else -0.05

# Drawn-in spawn: the figure is sketched on, a limb at a time, snapping to full
# size in two or three staggered drawings.
func _sketch_in(rig: CharacterRig, size: Vector3) -> Vector3:
	var index = 0.0
	for part in rig.parts:
		var arrive = clampf(rig.spawn * 1.8 - index * 0.12, 0.0, 1.0)
		rig.parts[part].scale *= clampf(arrive * 2.5, 0.01, 1.0)
		index += 1.0
	return size

# Death: the figure crumples. It faceplants, the limbs splay out from the core
# and the whole drawing thins into a heap of loose strokes on the page.
func _crumple(rig: CharacterRig, _size: Vector3) -> Vector3:
	var fade = clampf((rig.death - 0.3) / 0.7, 0.0, 1.0)
	rig.rotation.x = 1.4 * fade
	var index = 0.0
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var dir = node.position - CENTRE
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.UP
		node.position += dir * fade * 0.5
		node.rotation += Vector3(_noise(index + 1.0), _noise(index + 2.0), _noise(index + 3.0)) * fade * 1.6
		index += 1.0
	rig.turn("hand_l", Vector3(0, 0, -1.4 * fade))
	rig.turn("hand_r", Vector3(0, 0, 1.4 * fade))
	rig.turn("foot_l", Vector3(0.9 * fade, 0, -0.5 * fade))
	rig.turn("foot_r", Vector3(0.9 * fade, 0, 0.5 * fade))
	rig.position.y = fade * 0.1
	var thin = 1.0 - fade * 0.7
	return Vector3(thin, 1.0 - fade * 0.4, thin)

## Holds each multiple of `step`, then crosses to the next over the last `snap`.
func _stepped(value: float, step: float, snap: float) -> float:
	var whole = floorf(value / step)
	return (whole + smoothstep(1.0 - snap, 1.0, value / step - whole)) * step

## Turns a 1-to-0 decay into a held extreme that releases late and fast.
func _held(value: float, release: float) -> float:
	return smoothstep(0.0, release, value)

# Deterministic -1..1 hash; the animator keeps no random state.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
