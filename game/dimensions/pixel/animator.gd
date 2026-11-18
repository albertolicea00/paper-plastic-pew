extends DimensionAnimator
## Pixel Art: a sprite animated on a handful of hard frames. Motion is stepped
## at a low sprite rate (about 9 fps), limbs snap between a few poses with no
## in-between, the gun kicks in one hard click, a hit throws the sprite into a
## 2-frame knockback flash pose, a death blinks the figure out as it scatters,
## and a spawn flickers it in with a stepped pop. Stateless: every value comes
## from the rig's own fields, and missing parts are skipped.

# Sprite frames per second, and four hard walk poses per cycle.
const FPS = 9.0
const STEP = PI / 2.0
const CORE = Vector3(0, 0.8, 0)
# Extra top-level parts that should ride the head.
const HEAD_RIDERS = {"crown": true, "antenna": true}

func animate(rig: CharacterRig, _delta: float) -> void:
	# Each figure ticks on its own frame so a crowd never snaps in unison.
	var frame = floorf(rig.clock * FPS + rig.variation * 4.0)
	var phase = roundf(rig.phase / STEP) * STEP
	pose(rig, frame, phase)

func pose(rig: CharacterRig, frame: float, phase: float) -> void:
	rig.reset()
	var pace = _hold(minf(rig.speed_ratio, 1.2), 3.0)
	var recoil = _hold(rig.recoil, 2.0)
	var hurt = _hold(rig.hurt, 2.0)
	var dash = _hold(rig.dash, 2.0)
	var gone = rig.death
	var armed = rig.parts.has("weapon")

	# Hard gait: feet and arms jump between poses, the body hops on each step.
	var stride = sin(phase) * pace
	var weight = absf(stride)
	rig.move("foot_l", Vector3(0, maxf(0.0, -stride) * 0.2, stride * 0.2))
	rig.move("foot_r", Vector3(0, maxf(0.0, stride) * 0.2, -stride * 0.2))
	rig.turn("hand_l", Vector3(-stride * 0.5, 0, 0))
	if not armed:
		rig.turn("hand_r", Vector3(stride * 0.5, 0, 0))
	rig.move("body", Vector3(0, weight * 0.04, 0))
	rig.move("head", Vector3(0, weight * 0.05, 0))

	# Lean a notch into travel; a dash tips it harder. Snapped, never smooth.
	var heading = rig.move_local.snappedf(0.34)
	rig.rotation.x = heading.z * (0.08 * pace + 0.2 * dash)
	rig.rotation.z = -heading.x * (0.08 * pace + 0.2 * dash)

	# Recoil: one hard click back and up on the gun arm.
	rig.turn("weapon", Vector3(recoil * 0.5, 0, 0))
	rig.move("weapon", Vector3(0, 0, recoil * (0.1 if rig.first_person else 0.2)))
	rig.turn("hand_r", Vector3(recoil * 0.5, 0, 0))
	rig.move("body", Vector3(0, 0, recoil * 0.06))

	# Hurt: a 2-frame knockback flash pose. The sprite rocks back, head snaps
	# up, arms fly out, held on coarse steps so it reads as two drawn frames.
	rig.rotation.x -= hurt * 0.3
	rig.move("head", Vector3(0, hurt * 0.06, hurt * 0.1))
	rig.turn("hand_l", Vector3(0, 0, hurt * 0.6))
	rig.turn("hand_r", Vector3(0, 0, -hurt * 0.6))

	# Idle twitch out of step between figures.
	var idle = _hold(sin(frame / FPS * 3.0 + rig.variation * TAU), 2.0) * (1.0 - pace)
	rig.move("head", Vector3(0, idle * 0.02, 0))

	_extras(rig, frame, stride, hurt, dash)

	var born = clampf(rig.spawn, 0.0, 1.0)
	if born < 1.0:
		_popin(rig, born, frame)
	if gone > 0.0:
		_blinkout(rig, gone, frame)

	# Base squash: a tiny stepped idle breath plus the spawn pop.
	var breath = 1.0 + (idle * 0.03)
	rig.squash(Vector3(1.0, breath, 1.0) * _hold(lerpf(0.4, 1.0, ease(born, 0.5)), 4.0))
	rig.position.y = weight * 0.03

## Extra parts react: faces blink, antennae wobble, boss spikes splay on a hit,
## and the crown/antenna ride the head.
func _extras(rig: CharacterRig, frame: float, stride: float, hurt: float, dash: float) -> void:
	var head_shift = _shift(rig, "head")
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var word = part.get_slice("_", 0)
		if HEAD_RIDERS.has(word):
			node.position += head_shift
		match word:
			"antenna":
				node.rotation += Vector3(0, 0, stride * 0.4 + _noise(frame + 2.0) * 0.2)
			"crown":
				# Boss spikes splay outward on a hit, twitch on a dash.
				var out = rig.rest[part].origin - CORE
				node.position += Vector3(out.x, 0, out.z).normalized() * hurt * 0.3
				node.rotation += Vector3(0, 0, _noise(frame) * dash * 0.3)

## Spawn: the sprite flickers in and pops to size in a couple of hard steps.
func _popin(rig: CharacterRig, born: float, frame: float) -> void:
	# A classic materialise flicker: blink on alternate frames early in the spawn.
	if born < 0.55 and fmod(frame, 2.0) < 1.0:
		rig.squash(Vector3.ONE * 0.01)
		return
	# Stepped overshoot: small -> too big -> settle.
	var key = clampi(int(born * 4.0), 0, 3)
	var pop = [0.6, 1.25, 0.9, 1.0][key]
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		node.scale *= pop

## Death: the figure scatters its cubes outward, shrinks and blinks out.
func _blinkout(rig: CharacterRig, gone: float, frame: float) -> void:
	var index = 0.0
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var dir = rig.rest[part].origin - CORE
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.UP
		var fan = Vector3(_noise(index + rig.variation), 0.5, _noise(index * 2.0 + rig.variation))
		node.position += (dir * 0.5 + fan) * gone * 1.6
		node.rotation += fan * gone * 5.0
		node.scale *= maxf(1.0 - gone * 1.3, 0.02)
		index += 1.0
	# Flicker out over the last stretch, like a sprite despawning.
	if gone > 0.4 and fmod(frame, 2.0) < 1.0:
		rig.scale *= 0.2

## How far a part has been posed away from its rest origin.
func _shift(rig: CharacterRig, part: String) -> Vector3:
	return rig.parts[part].position - rig.rest[part].origin if rig.parts.has(part) else Vector3.ZERO

func _hold(value: float, steps: float) -> float:
	return roundf(value * steps) / steps

# Deterministic -1..1 hash; the animator may keep no random state.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
