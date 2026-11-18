class_name Actor
extends CharacterBody3D
## Anything that moves, shoots and takes damage: player, enemies and bots.
## Subclasses implement think() to set velocity, aim and firing.

signal died(actor: Actor, killer: Actor)

const MUZZLE_HEIGHT = 0.9
var game: GameMatch
var kind = ""
var spec: Dictionary = {}
var label = ""
var team = 0
var max_health = 100.0
var health = 100.0
var speed = 5.0
var alive = true
var aim = Vector3.FORWARD
var weapon_id = ""
var ammo: Dictionary = {}
var cooldown = 0.0
var aim_error = 0.0
var damage_scale = 1.0
var shield = 0.0
var kills = 0
# Persistent actors (player, skirmish bots) stay in the scene to be revived.
var persistent = false
var rig: CharacterRig
var _gone = 0.0

func setup(owner_game: GameMatch, actor_kind: String, actor_team: int) -> void:
	game = owner_game
	kind = actor_kind
	spec = game.kinds[kind]
	label = spec.name
	team = actor_team
	max_health = float(spec.health)
	health = max_health
	speed = float(spec.speed)
	weapon_id = spec.get("weapon", "")
	collision_layer = 2
	collision_mask = 3
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var look: Dictionary = spec.get("look", {})
	var reach = float(look.get("scale", 1.0))
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.45 * reach
	capsule.height = maxf(1.8 * reach, capsule.radius * 2.0)
	collider.shape = capsule
	collider.position.y = capsule.height * 0.5
	add_child(collider)
	rig = CharacterRig.new()
	add_child(rig)
	rig.build(look, kind)

func think(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not game.playing:
		return
	cooldown = maxf(0.0, cooldown - delta)
	shield = maxf(0.0, shield - delta)
	if alive:
		think(delta)
		move_and_slide()
		global_position.y = 0.0
		if aim.length_squared() > 0.001:
			rotation.y = atan2(-aim.x, -aim.z)
		rig.speed_ratio = clampf(velocity.length() / maxf(speed, 0.1), 0.0, 1.5)
		rig.move_local = global_transform.basis.inverse() * velocity.normalized()
	else:
		_gone += delta
		if _gone > 0.7 and not persistent:
			queue_free()

func _process(delta: float) -> void:
	if game.playing:
		rig.tick(delta)

func fire() -> bool:
	if cooldown > 0.0 or not alive or weapon_id == "":
		return false
	var weapon: Dictionary = game.weapons[weapon_id]
	var left: int = ammo.get(weapon_id, -1)
	if left == 0:
		return false
	if left > 0:
		ammo[weapon_id] = left - 1
	cooldown = 1.0 / float(weapon.rate)
	# Bullets leave the weapon muzzle, not the chest; keep them on the aim plane
	# so travel stays flat and matches the crosshair.
	var muzzle = rig.muzzle_point()
	var origin = Vector3(muzzle.x, MUZZLE_HEIGHT, muzzle.z)
	for i in int(weapon.pellets):
		var angle = deg_to_rad(randf_range(-1.0, 1.0) * (float(weapon.spread) + aim_error))
		game.projectiles.spawn(origin, aim.rotated(Vector3.UP, angle), weapon, self)
	rig.recoil = 1.0
	game.sfx.play(weapon.get("sound", "shot"), global_position)
	return true

func take_damage(amount: float, from: Actor) -> void:
	if not alive or shield > 0.0:
		return
	health -= amount
	rig.hurt = 1.0
	rig.flash()
	game.on_hit(self, amount, from)
	if health <= 0.0:
		die(from)

func die(killer: Actor) -> void:
	if not alive:
		return
	alive = false
	health = 0.0
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	rig.dead = true
	if is_instance_valid(killer) and killer != self:
		killer.kills += 1
	died.emit(self, killer)

func revive(at: Vector3) -> void:
	global_position = at
	alive = true
	health = max_health
	collision_layer = 2
	collision_mask = 3
	shield = 2.0
	_gone = 0.0
	rig.dead = false
	rig.death = 0.0
	rig.spawn = 0.0
