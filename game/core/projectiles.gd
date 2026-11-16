class_name Projectiles
extends Node3D
## All bullets in one place: swept ray checks on the CPU, drawn with two
## MultiMeshes (friendly and hostile colours) so a full screen costs two draws.

const CAPACITY = 384
const KEYS = ["bullet_player", "bullet_enemy"]
var game: GameMatch
var shots: Array[Dictionary] = []
var meshes: Array[MultiMeshInstance3D] = []

func _ready() -> void:
	game = get_parent()
	add_to_group(Dimensions.REBUILT)
	for key in KEYS:
		var node = MultiMeshInstance3D.new()
		node.multimesh = MultiMesh.new()
		node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		node.multimesh.instance_count = CAPACITY
		node.multimesh.visible_instance_count = 0
		node.multimesh.mesh = Dimensions.hub.active.builder.bullet_mesh()
		node.custom_aabb = AABB(Vector3(-100, -5, -100), Vector3(200, 10, 200))
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		Dimensions.hub.style(node, "bullet", key)
		meshes.append(node)

func rebuild() -> void:
	for node in meshes:
		node.multimesh.mesh = Dimensions.hub.active.builder.bullet_mesh()

func spawn(origin: Vector3, heading: Vector3, weapon: Dictionary, shooter: Actor) -> void:
	if shots.size() >= CAPACITY:
		return
	shots.append({
		"at": origin, "heading": heading.normalized(), "speed": float(weapon.speed), "damage": float(weapon.damage) * shooter.damage_scale,
		"life": float(weapon.range) / float(weapon.speed), "team": shooter.team, "shooter": shooter,
		"splash": float(weapon.get("splash", 0.0)), "size": float(weapon.get("size", 1.0)), "hostile": 0 if shooter.team == game.player.team else 1 })

func _physics_process(delta: float) -> void:
	if not game.playing:
		return
	var space = get_world_3d().direct_space_state
	var kept: Array[Dictionary] = []
	for shot in shots:
		shot.life -= delta
		var to: Vector3 = shot.at + shot.heading * shot.speed * delta
		var query = PhysicsRayQueryParameters3D.create(shot.at, to, 3)
		if is_instance_valid(shot.shooter):
			query.exclude = [shot.shooter.get_rid()]
		var hit = space.intersect_ray(query)
		var victim = hit.get("collider")
		if victim is Actor and victim.team == shot.team:
			hit = {}
		if not hit.is_empty():
			_land(shot, hit.position, victim)
			continue
		shot.at = to
		if shot.life <= 0.0:
			if shot.splash > 0.0:
				_land(shot, to, null)
			continue
		kept.append(shot)
	shots = kept

func _land(shot: Dictionary, at: Vector3, victim) -> void:
	var shooter: Actor = shot.shooter if is_instance_valid(shot.shooter) else null
	if shot.splash > 0.0:
		for actor in game.actors:
			if actor.alive and actor.team != shot.team:
				var gap = actor.global_position.distance_to(at)
				if gap < shot.splash:
					actor.take_damage(shot.damage * (1.0 - 0.6 * gap / shot.splash), shooter)
		game.vfx.burst(at, KEYS[shot.hostile], 26, 9.0)
		game.vfx.shake(0.5)
		game.sfx.play("explosion", at)
	elif victim is Actor:
		victim.take_damage(shot.damage, shooter)
		game.vfx.burst(at, KEYS[shot.hostile], 5, 5.0)
	else:
		game.vfx.burst(at, KEYS[shot.hostile], 3, 3.0)

func _process(_delta: float) -> void:
	var counts = [0, 0]
	for shot in shots:
		var which: int = shot.hostile
		var thickness: float = 0.26 * shot.size
		# Scale in the bullet's own axes so it stretches along its flight.
		var basis = Basis.looking_at(shot.heading, Vector3.UP) * Basis.from_scale(Vector3(thickness, thickness, thickness * 2.4))
		meshes[which].multimesh.set_instance_transform(counts[which], Transform3D(basis, shot.at))
		counts[which] += 1
	for which in 2:
		meshes[which].multimesh.visible_instance_count = counts[which]

func clear() -> void:
	shots.clear()
