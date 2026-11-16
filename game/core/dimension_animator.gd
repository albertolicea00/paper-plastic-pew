class_name DimensionAnimator
extends RefCounted
## Animation language of a dimension. Packs extend this and override pose()
## (or animate() to change timing, e.g. stepped frames).
## Rules: gameplay owns the actor transform; an animator only touches the rig
## and its parts, and must be stateless apart from the rig's own fields so a
## dimension shift can swap animators mid-frame.

## Called once per frame per rig, after the rig advanced its timers.
func animate(rig: CharacterRig, _delta: float) -> void:
	pose(rig, rig.clock, rig.phase)

## Builds the whole pose from rest. `time` is seconds alive, `phase` the walk
## cycle angle (advances with movement speed).
func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	walk(rig, phase, 1.0)
	lean(rig, 0.16)
	kick(rig, 0.16)
	rig.squash(life_scale(rig) * (Vector3.ONE + Vector3(0.12, -0.12, 0.12) * rig.hurt))
	rig.position.y = sin(time * 3.0) * 0.01

## Feet, hands and body bob. `amount` scales the stride.
func walk(rig: CharacterRig, phase: float, amount: float) -> void:
	var stride = sin(phase) * rig.speed_ratio * amount
	var lift = absf(cos(phase)) * rig.speed_ratio * amount
	rig.move("foot_l", Vector3(0, maxf(0.0, -stride) * 0.12, stride * 0.24))
	rig.move("foot_r", Vector3(0, maxf(0.0, stride) * 0.12, -stride * 0.24))
	rig.move("hand_l", Vector3(0, 0, -stride * 0.12))
	rig.move("body", Vector3(0, lift * 0.05, 0))
	rig.move("head", Vector3(0, lift * 0.07, 0))

## Tilt into the movement direction.
func lean(rig: CharacterRig, amount: float) -> void:
	rig.rotation.x = rig.move_local.z * amount * rig.speed_ratio
	rig.rotation.z = -rig.move_local.x * amount * rig.speed_ratio

## Weapon recoil.
func kick(rig: CharacterRig, amount: float) -> void:
	rig.move("weapon", Vector3(0, 0, rig.recoil * amount))
	rig.move("hand_r", Vector3(0, 0, rig.recoil * amount))

## Spawn pop-in and death collapse as a scale factor.
func life_scale(rig: CharacterRig) -> Vector3:
	var grow = ease(rig.spawn, 0.4)
	var fall = 1.0 - ease(rig.death, 2.0)
	return Vector3(grow * (1.0 + rig.death * 0.4), grow * fall, grow * (1.0 + rig.death * 0.4))
