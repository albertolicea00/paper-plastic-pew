extends DimensionAnimator
## Clay stop motion: puppets are shot "on twos" (12 poses per second) while
## gameplay stays smooth. Every held frame re-touches the clay a little, steps
## land heavy, and recoil, hits, spawns and deaths squash like soft plasticine.
## Stateless: every value is derived from the rig's own fields.

const FPS = 12.0
# Six walk poses per cycle; at full speed that is about one pose per frame.
const STRIDE = PI / 3.0
const CORE = Vector3(0, 0.72, 0)
# How the builder's extra parts move, by the word before the first "_".
const RIDES_HEAD = 1
const RIDES_BODY = 2
const EXTRAS = {
	"visor": RIDES_HEAD, "horn": RIDES_HEAD, "eye": RIDES_HEAD, "pupil": RIDES_HEAD, "nose": RIDES_HEAD, "brow": RIDES_HEAD,
	"mouth": RIDES_HEAD, "tooth": RIDES_HEAD, "hat": RIDES_HEAD, "crown": RIDES_HEAD, "cap": RIDES_HEAD, "sprout": RIDES_HEAD,
	"stalk": RIDES_HEAD, "bobble": RIDES_HEAD, "ear": RIDES_HEAD, "band": RIDES_HEAD, "scarf": RIDES_HEAD,
	"lump": RIDES_BODY, "button": RIDES_BODY, "belt": RIDES_BODY, "tail": RIDES_BODY }
# Sausage limbs trail halfway behind the hand or foot they end in.
const TRAILS = {"arm_l": "hand_l", "arm_r": "hand_r", "leg_l": "foot_l", "leg_r": "foot_r"}
# Spawn keys: a rolled ball, pinched up too tall, then patted down to size.
const SPAWN_HEIGHT = [0.5, 0.66, 0.86, 1.16, 0.94, 1.0]
const SPAWN_WIDTH = [1.15, 1.15, 1.06, 0.86, 1.06, 1.0]

func animate(rig: CharacterRig, _delta: float) -> void:
	# Each puppet is exposed on its own frame so a crowd never ticks in unison.
	var frame = floorf(rig.clock * FPS + rig.variation)
	pose(rig, frame / FPS, (floorf(rig.phase / STRIDE) + 0.5) * STRIDE)

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	# The rig's timers decay smoothly; hold them on coarse steps so each
	# reaction plays as a handful of distinct poses.
	var pace = _hold(minf(rig.speed_ratio, 1.2), 4.0)
	var recoil = _hold(rig.recoil, 2.0)
	var hurt = _hold(rig.hurt, 3.0)
	var dash = _hold(rig.dash, 3.0)
	var gone = _hold(rig.death, 5.0)
	var heading = rig.move_local.snappedf(0.25)
	var frame = roundf(time * FPS) + rig.variation * 977.0
	_walk(rig, phase, pace)
	# Lean into the move; a dash smears the whole puppet forward.
	var tilt = 0.13 * pace + 0.3 * dash
	rig.rotation.x = heading.z * tilt
	rig.rotation.z += -heading.x * tilt
	# Recoil: the gun and fist squash against the body, which rocks back.
	rig.move("weapon", Vector3(0, 0, recoil * 0.15))
	rig.stretch("weapon", Vector3(1.0 + recoil * 0.3, 1.0 + recoil * 0.3, 1.0 - recoil * 0.3))
	rig.move("hand_r", Vector3(0, 0, recoil * 0.15))
	rig.stretch("hand_r", Vector3.ONE * (1.0 + recoil * 0.25))
	rig.turn("body", Vector3(recoil * 0.1, 0, 0))
	rig.move("head", Vector3(0, 0, recoil * 0.05))
	# Hurt: pressed flat by a thumb, head sunk into the shoulders.
	rig.move("head", Vector3(0, -0.12 * hurt, 0))
	rig.stretch("head", Vector3(1.0 + hurt * 0.15, 1.0 - hurt * 0.2, 1.0 + hurt * 0.15))
	rig.move("hand_l", Vector3(-0.08 * hurt, 0.05 * hurt, 0))
	rig.move("hand_r", Vector3(0.08 * hurt, 0.05 * hurt, 0))
	var shape = Vector3(1.0 + hurt * 0.2 - dash * 0.08, 1.0 - hurt * 0.22 - dash * 0.1, 1.0 + hurt * 0.2 + dash * 0.22)
	# Idle breath, also held on frames.
	shape.y *= 1.0 + sin(time * 2.6 + rig.variation * TAU) * 0.02
	if gone > 0.0:
		shape *= _slump(rig, gone)
	_extras(rig, frame, pace * sin(phase), hurt, dash, gone)
	if rig.spawn < 1.0:
		shape *= _sculpt(rig)
	rig.squash(shape)
	_boil(rig, frame)

## Heavy waddle: the planted foot flattens and the body sinks onto it.
func _walk(rig: CharacterRig, phase: float, pace: float) -> void:
	var stride = sin(phase) * pace
	var weight = absf(stride)
	rig.move("foot_l", Vector3(0, maxf(0.0, -stride) * 0.16, stride * 0.26))
	rig.move("foot_r", Vector3(0, maxf(0.0, stride) * 0.16, -stride * 0.26))
	rig.stretch("foot_l", Vector3(1.0 + maxf(0.0, stride) * 0.2, 1.0 - maxf(0.0, stride) * 0.25, 1.0 + maxf(0.0, stride) * 0.1))
	rig.stretch("foot_r", Vector3(1.0 + maxf(0.0, -stride) * 0.2, 1.0 - maxf(0.0, -stride) * 0.25, 1.0 + maxf(0.0, -stride) * 0.1))
	rig.move("hand_l", Vector3(0, 0, -stride * 0.14))
	if not rig.parts.has("weapon"):
		rig.move("hand_r", Vector3(0, 0, stride * 0.14))
	rig.move("body", Vector3(0, -weight * 0.05, 0))
	rig.stretch("body", Vector3(1.0 + weight * 0.07, 1.0 - weight * 0.09, 1.0 + weight * 0.07))
	rig.move("head", Vector3(0, -weight * 0.08, 0))
	rig.rotation.z = stride * 0.07
	# Many-legged puppets: each further pair steps against the one in front.
	for pair in [2, 3]:
		var step = -stride if pair == 2 else stride
		rig.move("foot_l%d" % pair, Vector3(0, maxf(0.0, -step) * 0.12, step * 0.16))
		rig.move("foot_r%d" % pair, Vector3(0, maxf(0.0, step) * 0.12, -step * 0.16))
	# The tail drags from side to side, the tip a pose behind.
	rig.move("tail_a", Vector3(stride * 0.06, 0, 0))
	rig.move("tail_b", Vector3(-stride * 0.12, weight * 0.04, 0))

## Spawn: rolled as a ball, limbs pinched out of the lump, patted to size.
func _sculpt(rig: CharacterRig) -> Vector3:
	var key = clampi(int(rig.spawn * 5.0), 0, 4)
	var grown = (key + 1.0) / 6.0
	var limbs = clampf((grown - 0.3) / 0.5, 0.0, 1.0)
	for part in rig.parts:
		if part != "body":
			var node: Node3D = rig.parts[part]
			node.position = CORE.lerp(node.position, limbs)
			node.scale *= maxf(limbs, 0.01)
	rig.rotation.y = (1.0 - grown) * -2.6
	return Vector3(SPAWN_WIDTH[key], SPAWN_HEIGHT[key], SPAWN_WIDTH[key]) * lerpf(0.7, 1.0, grown)

## Death: the armature gives way and everything sags into one soft blob.
func _slump(rig: CharacterRig, gone: float) -> Vector3:
	rig.move("head", Vector3(0, -0.6 * gone, -0.12 * gone))
	rig.stretch("head", Vector3(1.0 + gone * 0.2, 1.0 - gone * 0.25, 1.0 + gone * 0.2))
	rig.stretch("body", Vector3(1.0 + gone * 0.3, 1.0 - gone * 0.35, 1.0 + gone * 0.3))
	rig.move("body", Vector3(0, -0.2 * gone, 0))
	rig.move("hand_l", Vector3(-0.12 * gone, -0.62 * gone, 0.1 * gone))
	rig.move("hand_r", Vector3(0.12 * gone, -0.62 * gone, 0.1 * gone))
	rig.move("foot_l", Vector3(-0.1 * gone, 0, 0.06 * gone))
	rig.move("foot_r", Vector3(0.1 * gone, 0, 0.06 * gone))
	rig.move("weapon", Vector3(0.1 * gone, -0.7 * gone, 0))
	rig.turn("weapon", Vector3(0, 0.5 * gone, 0.6 * gone))
	return Vector3(1.0 + gone * 0.35, 1.0 - gone * 0.42, 1.0 + gone * 0.35)

## Extra parts join in: the face rides the head, lumps ride the body, eyes
## blink and wince, hats and crowns flop, lumps sag when the armature fails.
func _extras(rig: CharacterRig, frame: float, stride: float, hurt: float, dash: float, gone: float) -> void:
	var weight = absf(stride)
	var head_shift = _shift(rig, "head")
	var body_shift = _shift(rig, "body")
	# One exposure in a dozen is a blink; a hit or death shuts the eyes too.
	var shut = _noise(frame * 1.37) > 0.84 or gone > 0.5
	# The gaze darts to a new spot twice a second.
	var gaze = _noise(floorf(frame / 6.0) * 5.3) * 0.012
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		if TRAILS.has(part):
			node.position += _shift(rig, TRAILS[part]) * 0.5
			continue
		var word = part.get_slice("_", 0)
		match EXTRAS.get(word, 0):
			RIDES_HEAD:
				node.position += head_shift
				# Features slide apart as the head is pressed flat.
				node.position.y -= (rig.rest[part].origin.y - _rest_y(rig, "head")) * (hurt * 0.2 + gone * 0.25)
			RIDES_BODY:
				node.position += body_shift
				# The armature gives way: lumps slide down and spread out.
				node.position.y -= rig.rest[part].origin.y * gone * 0.5
				node.position.x *= 1.0 + gone * 0.35
				node.position.z *= 1.0 + gone * 0.35
		match word:
			"eye":
				node.scale *= Vector3(1.0 + hurt * 0.3, 0.12 if shut else 1.0 - hurt * 0.55, 1.0)
			"pupil":
				node.position.x += gaze
				node.scale *= 0.01 if shut else 1.0 - hurt * 0.4
			"hat", "cap", "bobble", "sprout":
				# Top-heavy things flatten on each footfall and trail in a dash.
				node.scale *= Vector3(1.0 + (weight + hurt) * 0.12, 1.0 - weight * 0.14 - hurt * 0.35, 1.0 + (weight + hurt) * 0.12)
				node.rotation.x += dash * 0.5
				node.rotation.z += stride * 0.1
			"crown":
				# Spikes splay outward when the boss is hit.
				var out = rig.rest[part].origin - rig.rest["head"].origin if rig.rest.has("head") else Vector3.ZERO
				node.position += Vector3(out.x, 0, out.z) * hurt * 0.5
				node.scale *= 1.0 - gone * 0.5
			"lump", "tail":
				# Soft masses lag behind the step and bulge when struck.
				node.position.y -= weight * 0.03
				node.scale *= Vector3(1.0 + hurt * 0.2 + gone * 0.2, 1.0 - weight * 0.06 - gone * 0.3, 1.0 + hurt * 0.2 + gone * 0.2)
			"belt", "scarf", "band":
				node.scale *= Vector3(1.0 + weight * 0.07 + hurt * 0.2, 1.0, 1.0 + weight * 0.07 + hurt * 0.2)

## Every exposure the animator's fingers nudge each part a little.
func _boil(rig: CharacterRig, frame: float) -> void:
	var index = 0.0
	for part in rig.parts:
		var node: Node3D = rig.parts[part]
		var key = frame * 7.31 + index * 23.17
		# Small pressed-on features move less, or eyes would float off faces.
		var loose = 0.3 if EXTRAS.has(part.get_slice("_", 0)) else 1.0
		node.position += Vector3(_noise(key), _noise(key + 1.0), _noise(key + 2.0)) * 0.012 * loose
		node.rotation += Vector3(_noise(key + 3.0), _noise(key + 4.0), _noise(key + 5.0)) * 0.05
		node.scale *= Vector3(1.0 + _noise(key + 6.0) * 0.03, 1.0 + _noise(key + 7.0) * 0.03, 1.0 + _noise(key + 8.0) * 0.03)
		index += 1.0
	rig.rotation.y += _noise(frame * 3.7) * 0.03

## How far a part has been posed away from rest.
func _shift(rig: CharacterRig, part: String) -> Vector3:
	return rig.parts[part].position - rig.rest[part].origin if rig.parts.has(part) else Vector3.ZERO

func _rest_y(rig: CharacterRig, part: String) -> float:
	return rig.rest[part].origin.y if rig.rest.has(part) else 0.0

func _hold(value: float, steps: float) -> float:
	return roundf(value * steps) / steps

# Deterministic -1..1 hash; the animator may keep no random state.
func _noise(key: float) -> float:
	return fposmod(sin(key * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
