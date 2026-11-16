class_name Player
extends Actor
## Twin-stick player: move with one stick, aim and fire with the other.

const DASH_SPEED = 22.0
const DASH_TIME = 0.16
const DASH_COOLDOWN = 1.1
var inventory: Array = ["blaster"]
var dash_left = 0.0
var dash_wait = 0.0
var dash_dir = Vector3.ZERO
var _orbit = 1.0

func think(delta: float) -> void:
	dash_wait = maxf(0.0, dash_wait - delta)
	var move = Vector3.ZERO
	var firing = false
	var dashing = false
	if game.autopilot:
		# Test pilot: circle the nearest hostile and shoot it.
		var target = game.nearest_hostile(self)
		if target != null:
			var to = target.global_position - global_position
			aim = to.normalized()
			if randf() < delta * 0.4:
				_orbit = -_orbit
			move = aim.rotated(Vector3.UP, PI * 0.5 * _orbit) + aim * (0.6 if to.length() > 9.0 else -0.6)
			firing = game.clear_line(global_position, target.global_position)
	else:
		var input = game.input
		move = Vector3(input.move.x, 0, input.move.y)
		if input.aim.length_squared() > 0.01:
			aim = Vector3(input.aim.x, 0, input.aim.y).normalized()
		elif move.length_squared() > 0.04 and input.device != "mouse":
			aim = move.normalized()
		firing = input.firing
		dashing = Input.is_action_just_pressed("dash")
		if Input.is_action_just_pressed("swap"):
			cycle_weapon()
	if dashing and dash_wait <= 0.0:
		dash_left = DASH_TIME
		dash_wait = DASH_COOLDOWN
		dash_dir = move.normalized() if move.length_squared() > 0.04 else aim
		shield = maxf(shield, DASH_TIME + 0.08)
		rig.dash = 1.0
		game.sfx.play("dash", global_position)
		game.vfx.impact(0.8)
	if dash_left > 0.0:
		dash_left -= delta
		velocity = dash_dir * DASH_SPEED
	else:
		velocity = velocity.move_toward(move.limit_length() * speed, 70.0 * delta)
	if firing:
		if ammo.get(weapon_id, -1) == 0:
			inventory.erase(weapon_id)
			ammo.erase(weapon_id)
			weapon_id = "blaster"
		fire()

func cycle_weapon() -> void:
	if inventory.size() < 2:
		return
	weapon_id = inventory[(inventory.find(weapon_id) + 1) % inventory.size()]
	cooldown = maxf(cooldown, 0.15)
	game.sfx.play("swap")

func grant(weapon: String) -> void:
	var amount = int(game.weapons[weapon].get("pickup", 0))
	ammo[weapon] = ammo.get(weapon, 0) + amount
	if not inventory.has(weapon):
		inventory.append(weapon)
	weapon_id = weapon

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
