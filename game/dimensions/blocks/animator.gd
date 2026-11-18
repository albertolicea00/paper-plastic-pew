extends DimensionAnimator
## Plastic Blocks: a snap-together toy-robot. Motion is stepped on a mechanical
## clock (faster than clay's stop-motion, stiffer than cartoon's rubber-hose),
## limbs pivot rigidly about their sockets instead of bending, the gun kicks in
## a hard rotate-click, hits jolt the bricks apart and snap them back, a spawn
## drops the pieces in from above and a death bursts them outward. Stateless:
## every value comes from the rig's own fields, and missing parts are skipped.

# Poses per second, and the stride is quantised into eight snap positions.
const FPS = 22.0
const STEP = PI / 4.0
const CENTRE = Vector3(0, 0.82, 0)
# The word before the first "_" picks a part's extra behaviour.
const RIDES_BODY = {"key": true, "plate": true}

func animate(rig: CharacterRig, _delta: float) -> void:
	# Each figure ticks on its own frame so a crowd never snaps in unison.
	var frame = floorf(rig.clock * FPS + rig.variation * 3.0)
	var phase = roundf(rig.phase / STEP) * STEP
	pose(rig, frame / FPS, phase)

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	var pace = _hold(minf(rig.speed_ratio, 1.2), 4.0)
	var recoil = _hold(rig.recoil, 3.0)
	var hurt = _hold(rig.hurt, 3.0)
	var dash = _hold(rig.dash, 2.0)
	var gone = rig.death
	var armed = rig.parts.has("weapon")

	# Rigid gait: legs pivot about the hip, arms counter-swing about the
	# shoulder, nothing bends. cos(phase) crosses zero on each footfall.
	var stride = sin(phase) * pace
	var weight = absf(stride)
	rig.turn("foot_l", Vector3(stride * 0.55, 0, 0))
	rig.turn("foot_r", Vector3(-stride * 0.55, 0, 0))
	rig.turn("hand_l", Vector3(-stride * 0.4, 0, 0))
	if not armed:
		rig.turn("hand_r", Vector3(stride * 0.4, 0, 0))
	# The clack: the body drops hard onto the planted foot each step, and the
	# whole chassis twists a notch with the stride.
	rig.move("body", Vector3(0, -weight * 0.05, 0))
	rig.move("head", Vector3(0, -weight * 0.06, 0))
	rig.turn("body", Vector3(0, stride * 0.09, 0))

	# Lean a notch into the travel direction; a dash tips it further.
	var heading = rig.move_local.snappedf(0.25)
	rig.rotation.x = heading.z * (0.1 * pace + 0.22 * dash)
	rig.rotation.z = -heading.x * (0.1 * pace + 0.22 * dash)

	# Recoil: the barrel snaps up and back in a hard click, the torso twists.
	rig.turn("weapon", Vector3(recoil * 0.5, 0, 0))
	rig.move("weapon", Vector3(0, 0, recoil * (0.08 if rig.first_person else 0.16)))
	rig.turn("hand_r", Vector3(recoil * 0.5, 0, 0))
	rig.turn("body", Vector3(recoil * 0.12, -recoil * 0.14, 0))
	rig.move("head", Vector3(0, 0, recoil * 0.05))

	# Idle: a tiny mechanical bob, out of step between figures.
	var idle = sin(time * 3.0 + rig.variation * TAU) * (1.0 - pace)
	rig.move("head", Vector3(0, idle * 0.015, 0))
	rig.turn("antenna", Vector3(idle * 0.3 + stride * 0.2, 0, stride * 0.3 + idle * 0.4))
	rig.turn("key_back", Vector3(0, 0, time * 3.0 + phase))

	# Per-part reactions: the hit jolt, the spawn drop and the death burst all
	# push each brick along its own direction out from the core.
	var born = clampf(rig.spawn, 0.0, 1.0)
	var index = 0.0
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var dir = (rig.rest[part].origin - CENTRE)
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.UP
		# Hit: bricks pop apart a notch then snap back as hurt decays.
		if hurt > 0.0:
			node.position += dir * hurt * 0.22
			node.rotation += Vector3(_noise(index + 1.0), _noise(index + 2.0), _noise(index + 3.0)) * hurt * 0.4
		# Spawn: each piece drops from above, staggered, and clicks into place.
		if born < 1.0:
			var arrive = clampf(born * 1.7 - index * 0.07, 0.0, 1.0)
			node.position.y += (1.0 - ease(arrive, 0.35)) * 2.4
			node.scale *= clampf(arrive * 2.0, 0.02, 1.0)
		# Death: the figure bursts into scattered bricks that spin off and shrink.
		if gone > 0.0:
			var fan = Vector3(_noise(index * 1.7 + rig.variation), 0.4, _noise(index * 2.3 + rig.variation)).normalized()
			node.position += (dir * 0.6 + fan) * gone * 2.0
			node.rotation += Vector3(_noise(index + 4.0), _noise(index + 5.0), _noise(index + 6.0)) * gone * 6.0
			node.scale *= maxf(1.0 - gone * 1.2, 0.02)
		index += 1.0

	rig.squash(Vector3.ONE * lerpf(0.85, 1.0, ease(born, 0.5)))
	rig.position.y = -weight * 0.02

func _hold(value: float, steps: float) -> float:
	return roundf(value * steps) / steps

# Deterministic -1..1 hash; the animator may keep no random state.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
