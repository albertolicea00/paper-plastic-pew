class_name Enemy
extends Actor
## AI actor. Targets the nearest living actor on another team, so the same
## brain drives wave enemies (one shared team) and skirmish bots (one team each).

var target: Actor
var prefer_range = 8.0
var _retarget = 0.0
var _strafe = 1.0
var _steer = 0.0
var _steer_wait = 0.0
var _touch_wait = 0.0
var _pattern_wait = 3.0
var _pattern = 0
var _charge = 0.0

func think(delta: float) -> void:
	_retarget -= delta
	_touch_wait -= delta
	if _retarget <= 0.0 or not is_instance_valid(target) or not target.alive:
		target = game.nearest_hostile(self)
		_retarget = 0.6
	if target == null:
		velocity = velocity.move_toward(Vector3.ZERO, 20.0 * delta)
		return
	var to = target.global_position - global_position
	to.y = 0.0
	var distance = maxf(to.length(), 0.01)
	var toward = to / distance
	var sees = game.clear_line(global_position, target.global_position)
	var turned = lerp_angle(atan2(-aim.x, -aim.z), atan2(-toward.x, -toward.z), minf(1.0, delta * 7.0))
	aim = Vector3(-sin(turned), 0, -cos(turned))
	if randf() < delta * 0.5:
		_strafe = -_strafe
	var move = toward
	var pace = speed
	match spec.behavior:
		"ranged":
			if sees and distance < prefer_range - 2.0:
				move = -toward + toward.rotated(Vector3.UP, PI * 0.5) * _strafe * 0.6
			elif sees and distance < prefer_range + 2.0:
				move = toward.rotated(Vector3.UP, PI * 0.5) * _strafe
			if sees and distance < float(game.weapons[weapon_id].range) and aim.dot(toward) > 0.9:
				fire()
		"boss":
			pace = _boss(delta, toward, distance)
			if _charge > 0.0:
				move = aim
	var reach = 1.1 * rig.base_scale + 0.5
	if spec.has("touch") and distance < reach and _touch_wait <= 0.0:
		_touch_wait = 0.8
		rig.recoil = 1.0
		target.take_damage(float(spec.touch) * damage_scale, self)
	velocity = velocity.move_toward(_avoid(move.normalized(), delta) * pace, 30.0 * delta)

# Cheap obstacle avoidance: probe ahead and fan out until a free heading shows.
func _avoid(heading: Vector3, delta: float) -> Vector3:
	_steer_wait -= delta
	if _steer_wait <= 0.0:
		_steer_wait = 0.15
		_steer = 0.0
		for angle in [0.0, 0.7, -0.7, 1.4, -1.4, 2.2, -2.2]:
			if game.clear_line(global_position, global_position + heading.rotated(Vector3.UP, angle) * 2.2):
				_steer = angle
				break
	return heading.rotated(Vector3.UP, _steer)

func _boss(delta: float, toward: Vector3, distance: float) -> float:
	_pattern_wait -= delta
	if _charge > 0.0:
		_charge -= delta
		return speed * 4.5
	if _pattern_wait <= 0.0:
		_pattern_wait = 2.6 if health < max_health * 0.5 else 3.6
		_pattern = (_pattern + 1) % 3
		match _pattern:
			0:
				# Ring of slow bullets to weave through.
				var weapon: Dictionary = game.weapons[weapon_id]
				var count = 18 if health < max_health * 0.5 else 12
				for i in count:
					var heading = Vector3.FORWARD.rotated(Vector3.UP, TAU * i / count + rig.clock)
					game.projectiles.spawn(global_position + Vector3(0, MUZZLE_HEIGHT, 0), heading, weapon, self)
				rig.recoil = 1.0
				game.sfx.play("boss_shot", global_position)
			1:
				if distance > 4.0:
					_charge = 0.7
					aim = toward
					rig.dash = 1.0
					game.sfx.play("dash", global_position)
			2:
				game.director.reinforce(global_position, 2 if health > max_health * 0.5 else 3)
	return speed
