class_name Director
extends Node
## Runs the rules of a match. Modes:
##   survival  endless waves in one dimension, boss every fifth wave
##   shift     survival where the dimension snaps to another one mid-fight
##   campaign  a few waves and a boss per dimension, in pack order
##   skirmish  free-for-all against bots, first to KILL_LIMIT

const STAGE_WAVES = 3
const KILL_LIMIT = 15
const BOT_NAMES = ["Inky", "Staple", "Putty", "Crayon", "Scissor", "Glue", "Marker", "Eraser", "Tape"]
const TOUGHNESS = [0.7, 1.0, 1.35]
const WOBBLE = [9.0, 4.0, 1.0]

var game: GameMatch
var mode = "survival"
var level = 1
var wave = 0
var stage = 0
var state = "rest"
var timer = 2.0
var queue: Array[String] = []
var drip = 0.0
var hostiles = 0
var boss: Actor
var shift_timer = 0.0
var respawns: Array[Dictionary] = []
var fighters: Array[Actor] = []

func start() -> void:
	mode = game.config.get("mode", "survival")
	level = clampi(int(game.config.get("difficulty", 1)), 0, 2)
	shift_timer = randf_range(10.0, 15.0)
	if mode == "skirmish":
		fighters.append(game.player)
		game.player.label = "You"
		var points = game.arena.spawns.duplicate()
		points.shuffle()
		for i in clampi(int(game.config.get("bots", 4)), 1, BOT_NAMES.size()):
			var where = game.arena.ring_spawn(Vector3.ZERO) if game.arena.endless else points[i % points.size()]
			var bot = game.spawn("bot", where, 10 + i)
			bot.label = BOT_NAMES[i]
			bot.persistent = true
			bot.aim_error = WOBBLE[level] * 1.5
			bot.damage_scale = TOUGHNESS[level] * 0.6
			fighters.append(bot)
		game.hud.announce("Skirmish", "First to %d" % KILL_LIMIT, 2.0)
	elif mode == "campaign":
		game.hud.announce(game.dimensions.active.title, "Stage 1", 2.2)

func _physics_process(delta: float) -> void:
	if not game.playing:
		return
	if game.shifting and game.dimensions.packs.size() > 1:
		shift_timer -= delta
		if shift_timer <= 0.0:
			shift_timer = randf_range(11.0, 19.0)
			game.dimensions.shift_to(game.dimensions.random_other())
	if mode == "skirmish":
		for entry in respawns.duplicate():
			entry.wait -= delta
			if entry.wait <= 0.0:
				respawns.erase(entry)
				entry.actor.revive(_far_spawn())
		return
	match state:
		"rest":
			timer -= delta
			if timer <= 0.0:
				_begin_wave()
		"fight":
			drip -= delta
			if not queue.is_empty() and drip <= 0.0 and hostiles < 28:
				drip = 0.4
				_spawn_enemy(queue.pop_back(), _far_spawn())
			if queue.is_empty() and hostiles <= 0:
				_wave_cleared()

func is_boss_wave(number: int) -> bool:
	return number % (STAGE_WAVES + 1) == 0 if mode == "campaign" else number % 5 == 0

func _begin_wave() -> void:
	wave += 1
	state = "fight"
	var budget = int((4 + wave * 2) * TOUGHNESS[level])
	if is_boss_wave(wave):
		queue.append("boss")
		budget /= 2
		game.hud.announce("Boss!", game.dimensions.active.title, 2.0)
		game.sfx.play("boss")
	else:
		game.hud.announce("Wave %d" % wave, "", 1.4)
		game.sfx.play("wave")
	var choices = ["grunt"]
	if wave >= 2:
		choices.append("runner")
	if wave >= 4:
		choices.append("tank")
	while budget > 0:
		var kind: String = choices.pick_random()
		budget -= int(game.kinds[kind].cost)
		queue.push_front(kind)

func _spawn_enemy(kind: String, at: Vector3) -> Actor:
	var enemy = game.spawn(kind, at, GameMatch.ENEMY_TEAM)
	enemy.max_health *= (1.0 + wave * 0.06) * (TOUGHNESS[level] if kind == "boss" else 1.0)
	enemy.health = enemy.max_health
	enemy.damage_scale = TOUGHNESS[level]
	enemy.aim_error = WOBBLE[level]
	enemy.prefer_range = float(enemy.spec.get("range", 8.0))
	hostiles += 1
	if kind == "boss":
		boss = enemy
	game.vfx.burst(at + Vector3(0, 0.5, 0), enemy.spec.look.get("color", "grunt"), 8, 4.0)
	return enemy

## Boss call for help: runners appear around a point.
func reinforce(at: Vector3, count: int) -> void:
	for i in count:
		_spawn_enemy("runner", game.arena.clamp_inside(at + Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * 3.0))

func _far_spawn() -> Vector3:
	if game.arena.endless:
		# Bias spawns toward where the player is running, so fleeing meets enemies.
		var heading = game.player.velocity
		heading.y = 0.0
		return game.arena.ring_spawn(game.player.global_position, heading)
	var far = game.arena.spawns.filter(func(point): return point.distance_to(game.player.global_position) > 9.0)
	return game.arena.spawns.pick_random() if far.is_empty() else far.pick_random()

func _wave_cleared() -> void:
	state = "rest"
	timer = 3.0
	game.player.heal(15.0)
	game.score += wave * 25
	game.sfx.play("clear")
	if mode == "campaign" and is_boss_wave(wave):
		stage += 1
		if stage >= game.dimensions.packs.size():
			game.end(true)
			return
		game.dimensions.shift_to(game.dimensions.following())
		game.hud.announce(game.dimensions.active.title, "Stage %d" % (stage + 1), 2.4)
	else:
		game.hud.announce("Wave %d cleared" % wave, "", 1.4)

func on_death(actor: Actor, killer: Actor) -> void:
	if mode == "skirmish":
		respawns.append({"actor": actor, "wait": 2.5})
		if is_instance_valid(killer) and killer.kills >= KILL_LIMIT:
			game.end(killer == game.player)
		return
	if actor == game.player:
		game.end(false)
	elif actor.team == GameMatch.ENEMY_TEAM:
		hostiles -= 1

## Skirmish standings, best first: [[label, kills], ...]
func board() -> Array:
	var rows = fighters.map(func(fighter): return [fighter.label, fighter.kills])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	return rows

func summary() -> String:
	if mode == "skirmish":
		return "\n".join(board().map(func(row): return "%s  %d" % row))
	return "Wave %d   Score %d" % [wave, game.score]
