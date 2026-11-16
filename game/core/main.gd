extends Node
## Entry point: owns the dimension registry and sound, and swaps between the
## menu and a match.
## Developer arguments (after `--`):
##   --smoke                      headless gameplay check, see core/smoke.gd
##   --mode=<mode> --dimension=<id> --arena=<id> --bots=<n>   start a match directly
##   --touch                      show touch controls on desktop
##   --autopilot                  let the test pilot play
##   --capture=<file.png>         save a frame after --capture-after seconds (default 4) and quit

const SAVE = "user://save.cfg"
var dimensions: Dimensions
var sfx: Sfx
var menu: MainMenu
var game: GameMatch
var options: Dictionary = {}
var best: Dictionary = {}

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		var pair = argument.trim_prefix("--").split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else "1"
	TwinInput.register_actions()
	dimensions = Dimensions.new()
	add_child(dimensions)
	sfx = Sfx.new()
	add_child(sfx)
	var save = ConfigFile.new()
	if save.load(SAVE) == OK:
		for mode in save.get_section_keys("best"):
			best[mode] = save.get_value("best", mode, 0)
	if options.has("smoke"):
		add_child(Smoke.new())
	elif options.has("mode") or options.has("capture"):
		start({"mode": options.get("mode", "survival"), "dimension": options.get("dimension", dimensions.active.id), "arena": options.get("arena", ""),
			"bots": int(options.get("bots", "4")), "autopilot": options.has("autopilot") or options.has("capture")})
		if options.has("capture"):
			_capture()
	else:
		show_menu()

func _clear() -> void:
	if is_instance_valid(game):
		game.queue_free()
		game = null
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null

func show_menu() -> void:
	_clear()
	sfx.silence()
	menu = MainMenu.new()
	menu.setup(self)
	menu.start_requested.connect(start)
	add_child(menu)

func start(config: Dictionary) -> void:
	_clear()
	var full = config.duplicate()
	if options.has("touch") or OS.has_feature("mobile"):
		full["touch"] = true
	game = GameMatch.new()
	game.setup(self, full)
	add_child(game)

func record(mode: String, score: int) -> void:
	if options.has("smoke") or score <= best.get(mode, 0):
		return
	best[mode] = score
	var save = ConfigFile.new()
	for key in best:
		save.set_value("best", key, best[key])
	save.save(SAVE)

func _capture() -> void:
	await get_tree().create_timer(float(options.get("capture-after", "4"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(options.capture)
	get_tree().quit()
