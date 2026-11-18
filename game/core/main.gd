extends Node
## Entry point: owns the dimension registry and sound, and swaps between the
## menu and a match.
## Developer arguments (after `--`):
##   --smoke                      headless gameplay check, see core/smoke.gd
##   --mode=<mode> --dimension=<id> --arena=<id> --bots=<n>   start a match directly
##   --touch                      show touch controls on desktop
##   --mute                       silence music and effects (for test captures)
##   --view=top|shoulder|weapon   camera view for this run
##   --autopilot                  let the test pilot play
##   --capture=<file.png>         save a frame after --capture-after seconds (default 4) and quit;
##                                without --mode it captures the menu
##   --menu-pick=<id> --menu-mode=<mode> --menu-start   preselect in the menu; see ui/menu.gd

const SAVE = "user://save.cfg"
var dimensions: Dimensions
var sfx: Sfx
var menu: MainMenu
var game: GameMatch
var options: Dictionary = {}
var best: Dictionary = {}
# Player options, kept between runs. view: top | shoulder | weapon
var settings: Dictionary = {"view": "top"}

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		var pair = argument.trim_prefix("--").split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else "1"
	TwinInput.register_actions()
	dimensions = Dimensions.new()
	add_child(dimensions)
	sfx = Sfx.new()
	if options.has("mute"):
		sfx.effects_volume = 0.0
		sfx.music_volume = 0.0
	add_child(sfx)
	var save = ConfigFile.new()
	if save.load(SAVE) == OK:
		for mode in save.get_section_keys("best"):
			best[mode] = save.get_value("best", mode, 0)
		for key in settings.keys():
			settings[key] = save.get_value("settings", key, settings[key])
	if options.has("smoke"):
		add_child(Smoke.new())
	elif options.has("mode"):
		start({"mode": options.mode, "dimension": options.get("dimension", dimensions.active.id), "arena": options.get("arena", ""),
			"bots": int(options.get("bots", "4")), "autopilot": options.has("autopilot") or options.has("capture")})
	else:
		show_menu()
	if options.has("capture"):
		_capture()

func _clear() -> void:
	if is_instance_valid(game):
		game.queue_free()
		game = null
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null

func show_menu() -> void:
	_clear()
	sfx.danger = 0.0
	sfx.duck(1.0)
	# The menu has its own shared tune, distinct from the dimension tracks.
	sfx.music("menu", true)
	menu = MainMenu.new()
	menu.setup(self)
	menu.start_requested.connect(start)
	add_child(menu)

func start(config: Dictionary) -> void:
	_clear()
	var full = config.duplicate()
	if options.has("touch") or OS.has_feature("mobile"):
		full["touch"] = true
	if options.has("view"):
		full["view"] = options.view
	game = GameMatch.new()
	game.setup(self, full)
	add_child(game)

func record(mode: String, score: int) -> void:
	if options.has("smoke") or score <= best.get(mode, 0):
		return
	best[mode] = score
	_save()

func set_setting(key: String, value) -> void:
	settings[key] = value
	if not options.has("smoke"):
		_save()

func _save() -> void:
	var save = ConfigFile.new()
	for key in best:
		save.set_value("best", key, best[key])
	for key in settings:
		save.set_value("settings", key, settings[key])
	save.save(SAVE)

func _capture() -> void:
	await get_tree().create_timer(float(options.get("capture-after", "4"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(options.capture)
	# Free the scene and audio first, or Godot reports leaked resources at exit.
	_clear()
	sfx.stop_all()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
