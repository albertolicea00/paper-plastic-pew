extends DimensionAnimator
## Anime timing: key poses are held and the in-betweens are skipped. Idle and
## walk are shot "on twos", reactions (recoil, hit, dash) snap to an extreme,
## hold it, then snap back.

const TWOS = 1.0 / 12.0
const WALK_STEP = PI / 3.0 # six held poses per walk cycle
# The builder's extra parts ride along with the part they are attached to.
const HEAD = ["head", "visor", "hair", "hat", "mane", "horn_l", "horn_r", "tail", "band_a", "band_b"]
const TORSO = ["body", "belt", "coat", "skirt", "chest", "shoulder_l", "shoulder_r", "scarf", "scarf_a", "scarf_b", "cape", "banner", "sheath"]
const LEFT = ["hand_l", "blade_l"]
const RIGHT = ["hand_r", "weapon", "blade_r"]
# Cloth and hair that trail: [lift at full speed, flutter, flutter rate].
# Strips rest drooping (+X turn) and lift to level; the banner pole leans back.
const TRAILS = {"scarf_a": [0.9, 0.2, 17.0], "scarf_b": [1.05, 0.26, 21.0], "tail": [0.95, 0.16, 15.0],
	"band_a": [0.8, 0.24, 19.0], "band_b": [0.95, 0.3, 23.0], "cape": [0.75, 0.1, 9.0], "banner": [-0.3, 0.07, 11.0]}

func animate(rig: CharacterRig, _delta: float) -> void:
	# The per-character offset keeps a crowd from stepping on the same frame.
	pose(rig, snappedf(rig.clock + rig.variation, TWOS), _stepped(rig.phase, WALK_STEP, 0.3))

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	var dash = _held(rig.dash, 0.3)
	var hurt = _held(rig.hurt, 0.45)
	var recoil = _held(rig.recoil, 0.5)
	var pace = minf(rig.speed_ratio, 1.0)
	var heading = rig.move_local * Vector3(1, 0, 1)
	_walk(rig, phase, 1.5 * (1.0 - dash))
	_all(rig, LEFT, Vector3(0, 0, -heading.z * 0.1 * pace))
	_idle(rig, time, pace)
	# Runs lean hard into the movement; a dash throws the whole body flat.
	var tilt = 0.26 * pace + 0.6 * dash
	rig.rotation.x = heading.z * tilt + 0.5 * hurt
	rig.rotation.z = -heading.x * tilt
	_dash(rig, heading, dash)
	_blades(rig, pace, recoil)
	_recoil(rig, recoil)
	_hit(rig, hurt)
	_trails(rig, time, heading, pace, dash, hurt)
	var size = Vector3(1.0 - 0.2 * dash + 0.2 * hurt, 1.0 + 0.32 * dash - 0.18 * hurt, 1.0 - 0.2 * dash + 0.2 * hurt)
	if rig.dead:
		size = _death(rig, size)
	elif rig.spawn < 1.0:
		size = _spawn(rig, size)
	rig.squash(size.max(Vector3.ONE * 0.001))

## Advances in steps: holds each multiple of `step`, then crosses to the next
## one during the last `snap` share of the interval.
func _stepped(value: float, step: float, snap: float) -> float:
	var whole = floorf(value / step)
	return (whole + smoothstep(1.0 - snap, 1.0, value / step - whole)) * step

## Turns a 1-to-0 decay into a held extreme that releases late and fast.
func _held(value: float, release: float) -> float:
	return smoothstep(0.0, release, value)

func _all(rig: CharacterRig, parts: Array, offset: Vector3) -> void:
	for part in parts:
		rig.move(part, offset)

# The base walk, with everything worn on the head and torso bobbing along.
func _walk(rig: CharacterRig, phase: float, amount: float) -> void:
	var stride = sin(phase) * rig.speed_ratio * amount
	var lift = absf(cos(phase)) * rig.speed_ratio * amount
	rig.move("foot_l", Vector3(0, maxf(0.0, -stride) * 0.12, stride * 0.24))
	rig.move("foot_r", Vector3(0, maxf(0.0, stride) * 0.12, -stride * 0.24))
	_all(rig, LEFT, Vector3(0, 0, -stride * 0.12))
	_all(rig, TORSO, Vector3(0, lift * 0.05, 0))
	_all(rig, HEAD, Vector3(0, lift * 0.07, 0))

# Scarves, ponytails, headbands and capes stream away from the movement and
# snap between drawings; a hit throws them up.
func _trails(rig: CharacterRig, time: float, heading: Vector3, pace: float, dash: float, hurt: float) -> void:
	var fly = clampf(pace * (0.45 + 0.55 * maxf(0.0, -heading.z)) + dash, 0.0, 1.0)
	var yaw = -heading.x * 0.9 * minf(pace + dash, 1.0)
	var index = 0.0
	for part in TRAILS:
		index += 2.1
		if not rig.parts.has(part):
			continue
		var spec: Array = TRAILS[part]
		var wave = sin(time * spec[2] + index + rig.variation * TAU)
		rig.turn(part, Vector3(-spec[0] * fly + wave * spec[1] * (0.25 + fly) - signf(spec[0]) * 0.5 * hurt, yaw + wave * spec[1] * 0.6 * fly, 0))
	# Spiked hair and manes rake back in the same drawing.
	rig.stretch("hair", Vector3(1, 1.0 - 0.08 * fly, 1.0 + 0.18 * fly))
	rig.stretch("mane", Vector3(1, 1.0 - 0.08 * fly, 1.0 + 0.22 * fly))

# Ninja run: arms thrown back with the blades trailing; an attack snaps them
# forward into a cross.
func _blades(rig: CharacterRig, pace: float, recoil: float) -> void:
	if not rig.parts.has("blade_l"):
		return
	var sweep = smoothstep(0.35, 0.6, pace) * (1.0 - recoil)
	for side in [-1, 1]:
		var blade = "blade_l" if side < 0 else "blade_r"
		_all(rig, LEFT if side < 0 else RIGHT, Vector3(side * 0.05, 0.12, 0.44) * sweep + Vector3(-side * 0.12, 0.1, -0.18) * recoil)
		rig.turn(blade, Vector3(2.5 * sweep - 0.35 * recoil, side * (0.3 * sweep + 1.0 * recoil), 0))

func _idle(rig: CharacterRig, time: float, pace: float) -> void:
	var breath = sin(time * 2.6) * (1.0 - pace)
	rig.stretch("body", Vector3(1.0 - breath * 0.02, 1.0 + breath * 0.03, 1.0 - breath * 0.02))
	_all(rig, HEAD, Vector3(0, breath * 0.015, 0))
	_all(rig, LEFT, Vector3(0, breath * 0.012, 0))
	# A blink held for one drawing every few seconds.
	if fmod(time + rig.variation * 3.0, 3.4) < TWOS * 1.5:
		rig.stretch("visor", Vector3(1, 0.2, 1))

# Body stretched along the lean, arms trailing, legs split.
func _dash(rig: CharacterRig, heading: Vector3, amount: float) -> void:
	if amount <= 0.0:
		return
	var trail = -heading * amount
	_all(rig, LEFT, trail * 0.3 + Vector3(0, 0.1, 0) * amount)
	_all(rig, RIGHT, trail * 0.12)
	_all(rig, HEAD, -trail * 0.1)
	rig.move("foot_l", -trail * 0.22)
	rig.move("foot_r", trail * 0.28 + Vector3(0, 0.1, 0) * amount)

# Muzzle climbs, shoulders rock back.
func _recoil(rig: CharacterRig, amount: float) -> void:
	rig.move("weapon", Vector3(0, 0.04, 0.2) * amount)
	rig.turn("weapon", Vector3(0.28, 0, 0) * amount)
	rig.move("hand_r", Vector3(0, 0.03, 0.2) * amount)
	_all(rig, TORSO, Vector3(0, 0, 0.05) * amount)
	_all(rig, HEAD, Vector3(0, 0, 0.03) * amount)
	# Armour plates jump with the shot.
	rig.move("shoulder_l", Vector3(0, 0.05, 0) * amount)
	rig.move("shoulder_r", Vector3(0, 0.08, 0) * amount)

# Impact frame: thrown back with the arms flung wide, shaking while held.
func _hit(rig: CharacterRig, amount: float) -> void:
	if amount <= 0.0:
		return
	_all(rig, HEAD, Vector3(0, 0.03, 0.1) * amount)
	_all(rig, LEFT, Vector3(-0.2, 0.22, 0.1) * amount)
	_all(rig, RIGHT, Vector3(0.16, 0.18, 0.08) * amount)
	rig.turn("weapon", Vector3(0.5, 0, 0) * amount)
	rig.stretch("visor", Vector3(1.15, 0.5, 1))
	if amount > 0.98:
		rig.position.x = 0.05 if int(rig.clock * 30.0) % 2 == 0 else -0.05

# Drops in as a streak, lands in a squat, overshoots, settles: three drawings.
func _spawn(rig: CharacterRig, size: Vector3) -> Vector3:
	if rig.spawn < 0.34:
		rig.position.y = 1.1 * (1.0 - rig.spawn / 0.34)
		return Vector3(0.3, 1.9, 0.3)
	if rig.spawn < 0.67:
		return Vector3(1.32, 0.62, 1.32)
	return size * Vector3(0.9, 1.14, 0.9)

# Freeze on the knock-back pose, then thin out into a rising ink stroke.
func _death(rig: CharacterRig, _size: Vector3) -> Vector3:
	var fade = clampf((rig.death - 0.45) / 0.55, 0.0, 1.0)
	rig.rotation.x = 0.7 * (1.0 - fade)
	_all(rig, LEFT, Vector3(-0.24, 0.3, 0.1))
	_all(rig, RIGHT, Vector3(0.2, 0.26, 0.1))
	rig.move("weapon", Vector3(0.1, -0.16, 0.1))
	rig.turn("weapon", Vector3(0.9, 0, 0.6))
	_all(rig, HEAD, Vector3(0, 0.02, 0.12))
	rig.stretch("visor", Vector3(1.15, 0.4, 1))
	rig.position.y = fade * 0.5
	var thin = (1.0 - fade) * (1.0 - fade)
	return Vector3(1.15 * thin, 0.95 + fade * 1.4, 1.15 * thin)
