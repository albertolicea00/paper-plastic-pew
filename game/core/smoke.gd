class_name Smoke
extends Node
## Headless gameplay check, run by tools/check.py with `-- --smoke`.
## A test pilot plays every mode at high speed; failures print "SMOKE FAIL".

var main: Node
var failures: Array[String] = []

func _ready() -> void:
	main = get_parent()
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("SMOKE FAIL: ", message)

func play(config: Dictionary, seconds: float) -> GameMatch:
	config["autopilot"] = true
	main.start(config)
	var game: GameMatch = main.game
	await get_tree().process_frame
	game.time_scale = 4.0
	Engine.time_scale = 4.0
	game.player.max_health = 100000.0
	game.player.health = 100000.0
	await get_tree().create_timer(seconds, true, false, true).timeout
	return game

func run() -> void:
	var dimensions: Dimensions = main.dimensions
	check(dimensions.packs.size() >= 3, "expected at least three dimension packs")
	for pack in dimensions.packs:
		check(pack.data.has("palette"), pack.id + " has no palette")
		check(pack.animator != null, pack.id + " has no animator")
	# Multiverse shift: fight while visiting every dimension.
	var game = await play({"mode": "shift", "dimension": dimensions.packs[0].id, "arena": "crossroads"}, 3.0)
	var seen = {}
	dimensions.shifted.connect(func(pack): seen[pack.id] = true)
	for pack in dimensions.packs:
		dimensions.shift_to(pack.id)
		await get_tree().create_timer(1.2, true, false, true).timeout
	dimensions.shift_to(dimensions.packs[0].id)
	check(seen.size() == dimensions.packs.size(), "shift did not reach every dimension")
	var waited = 0.0
	while game.director.wave < 2 and waited < 15.0:
		await get_tree().create_timer(0.5, true, false, true).timeout
		waited += 0.5
	check(game.player.kills > 0, "pilot killed nothing in shift mode")
	check(game.director.wave >= 2, "waves did not advance")
	var shift_kills = game.player.kills
	# Losing ends the match.
	game.player.take_damage(1000000.0, null)
	check(game.over and not game.victory, "player death did not end the match")
	# Campaign: clear a stage and move on to the next dimension.
	game = await play({"mode": "campaign", "dimension": dimensions.packs[0].id, "arena": "pillars"}, 1.0)
	# One-shot everything so clearing the stage never hangs on autopilot aim RNG.
	game.player.damage_scale = 500.0
	waited = 0.0
	while game.director.stage < 1 and waited < 28.0:
		# Nudge any lingering enemies dead so a slow boss hunt can't stall the test.
		for actor in game.actors.duplicate():
			if actor.alive and actor != game.player and actor.global_position.distance_to(game.player.global_position) < 4.0:
				actor.take_damage(9999.0, game.player)
		await get_tree().create_timer(0.5, true, false, true).timeout
		waited += 0.5
	check(game.director.stage >= 1, "campaign stage did not complete")
	check(dimensions.active == dimensions.packs[1], "campaign did not move to the next dimension")
	# Skirmish: bots fight each other and the pilot, and respawn.
	game = await play({"mode": "skirmish", "dimension": dimensions.packs[0].id, "bots": 4, "arena": "workshop"}, 8.0)
	var bot_kills = 0
	for fighter in game.director.fighters:
		if fighter != game.player:
			bot_kills += fighter.kills
	check(game.player.kills + bot_kills > 0, "nobody scored in skirmish")
	check(game.director.fighters.size() == 5, "skirmish roster is wrong")
	# Pickups and weapons.
	game.player.grant("scatter")
	check(game.player.weapon_id == "scatter" and game.player.ammo.scatter > 0, "weapon pickup failed")
	game.player.cycle_weapon()
	check(game.player.weapon_id == "blaster", "weapon cycling failed")
	var skirmish_kills = game.player.kills + bot_kills
	# Endless map: no bounds, props stream in around the roaming pilot.
	game = await play({"mode": "survival", "dimension": dimensions.packs[0].id, "endless": true}, 5.0)
	check(game.arena.endless, "endless arena did not build")
	check(game.arena.chunks.size() > 0, "endless arena streamed no prop cells")
	var far = game.arena.clamp_inside(Vector3(500, 0, 500))
	check(far.x > 100.0, "endless arena still clamps the player")
	Engine.time_scale = 1.0
	main.show_menu()
	await get_tree().process_frame
	check(is_instance_valid(main.menu), "menu did not open")
	if failures.is_empty():
		print("SMOKE PASS: %d dimensions, %d shift kills, %d skirmish kills" % [dimensions.packs.size(), shift_kills, skirmish_kills])
	main.sfx.stop_all()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(1 if not failures.is_empty() else 0)
