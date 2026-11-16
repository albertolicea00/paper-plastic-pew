class_name MainMenu
extends Control
## Main menu. Contract with core/main.gd: setup(main) is called before the
## node enters the tree, and start_requested carries a match config:
## {mode: survival|shift|campaign|skirmish, dimension: <pack id>, bots: int, difficulty: 0..2}

signal start_requested(config: Dictionary)

const MODES = [["survival", "Survival"], ["shift", "Multiverse Shift"], ["campaign", "Campaign"], ["skirmish", "Skirmish vs bots"]]
const LEVELS = ["Easy", "Normal", "Hard"]
var main: Node
var pick = 0
var level = 1
var bots = 4
var world: Button
var skill: Button
var crowd: Button

func setup(owner_main: Node) -> void:
	main = owner_main

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back = ColorRect.new()
	back.color = Color("#1c1e26")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var column = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var title = Label.new()
	title.text = "Paper, Plastic, Pew!"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	world = _button(column, "", func(): pick = (pick + 1) % main.dimensions.packs.size())
	skill = _button(column, "", func(): level = (level + 1) % LEVELS.size())
	crowd = _button(column, "", func(): bots = bots % 8 + 1)
	for mode in MODES:
		_button(column, mode[1], func(): start_requested.emit({"mode": mode[0], "dimension": main.dimensions.packs[pick].id, "bots": bots, "difficulty": level}))
	_refresh()

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 56)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	button.pressed.connect(_refresh)
	parent.add_child(button)
	return button

func _refresh() -> void:
	var pack: DimensionPack = main.dimensions.packs[pick]
	world.text = "Dimension: %s (%s)" % [pack.title, pack.family]
	skill.text = "Difficulty: " + LEVELS[level]
	crowd.text = "Skirmish bots: %d" % bots
