class_name DimensionPack
extends RefCounted
## One visual dimension, loaded from res://dimensions/<id>/pack.json.
## See docs/DIMENSION_PACKS.md for the file format.

# Every palette key the core asks for. Packs override any of them.
const PALETTE = {
	"bg": "#1c1e26", "floor": "#8a8f9c", "floor_alt": "#7b808d", "wall": "#4b5063", "prop": "#c98b4a",
	"player": "#3fa7d6", "player_accent": "#ffd23f", "grunt": "#e4572e", "runner": "#f3a712",
	"tank": "#7b4bb7", "boss": "#b80c3c", "bot": "#59c26a", "weapon": "#2b2d38", "ink": "#12131a",
	"bullet_player": "#ffe66d", "bullet_enemy": "#ff4f79", "pickup_health": "#59c26a", "pickup_ammo": "#3fa7d6",
	"flash": "#ffffff", "ui_bg": "#1c1e26", "ui_fg": "#ffffff", "ui_accent": "#ffd23f", "ui_danger": "#ff4f79" }
const ENVIRONMENT = {"ambient": "#ffffff", "ambient_energy": 0.45, "light": "#ffffff", "light_energy": 1.0, "light_pitch": -58.0, "light_yaw": -35.0, "shadows": true}
const HUD = {"radius": 8.0, "border": 3.0, "shadow": 4.0, "tilt": 0.0, "uppercase": false, "font_scale": 1.0}
const FEEL = {"hitstop": 0.0, "shake": 1.0}
const NO_OUTLINE = ["floor", "bullet", "fx", "flash"]
const OUTLINE_SHADER = preload("res://core/shaders/outline.gdshader")
const DEFAULT_SHADER = preload("res://core/shaders/surface_default.gdshader")

var id = ""
var dir = ""
var data: Dictionary = {}
var title = ""
var family = ""
var tagline = ""
var order = 0
var animator: DimensionAnimator
var overlay: ShaderMaterial
var font: Font
var environment: Dictionary = {}
var hud: Dictionary = {}
var feel: Dictionary = {}
var _colors: Dictionary = {}
var _materials: Dictionary = {}
var _shaders: Dictionary = {}

static func load_from(pack_dir: String) -> DimensionPack:
	var file = pack_dir.path_join("pack.json")
	if not FileAccess.file_exists(file):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not parsed is Dictionary:
		push_error("Invalid dimension pack: " + file)
		return null
	var pack = DimensionPack.new()
	pack.dir = pack_dir
	pack.data = parsed
	pack.id = parsed.get("id", pack_dir.get_file())
	pack.title = parsed.get("name", pack.id.capitalize())
	pack.family = parsed.get("family", "Paper")
	pack.tagline = parsed.get("tagline", "")
	pack.order = int(parsed.get("order", 99))
	for key in PALETTE:
		pack._colors[key] = Color.html(parsed.get("palette", {}).get(key, PALETTE[key]))
	pack.environment = _merged(ENVIRONMENT, parsed.get("environment", {}))
	pack.hud = _merged(HUD, parsed.get("hud", {}))
	pack.feel = _merged(FEEL, parsed.get("feel", {}))
	var script = pack._resource(parsed.get("animator", ""))
	pack.animator = script.new() if script is GDScript else DimensionAnimator.new()
	var over: Dictionary = parsed.get("overlay", {})
	var over_shader = pack._shader(over.get("shader", ""))
	if over_shader != null:
		pack.overlay = ShaderMaterial.new()
		pack.overlay.shader = over_shader
		pack._set_params(pack.overlay, over.get("params", {}))
	# Fonts are found by convention so asset drops need no pack.json edit.
	for candidate in [parsed.get("font", ""), "font.ttf", "font.otf"]:
		var loaded = pack._resource(candidate)
		if loaded is Font:
			pack.font = loaded
			break
	return pack

static func _merged(base: Dictionary, extra: Dictionary) -> Dictionary:
	var out = base.duplicate()
	out.merge(extra, true)
	return out

func color(key: String) -> Color:
	return _colors.get(key, Color.MAGENTA)

func path(file: String) -> String:
	return file if file.begins_with("res://") else dir.path_join(file)

func _resource(file: String) -> Resource:
	if file == "" or not ResourceLoader.exists(path(file)):
		return null
	return load(path(file))

func _shader(file: String) -> Shader:
	if file == "":
		return null
	if not _shaders.has(file):
		_shaders[file] = _resource(file) as Shader
		if _shaders[file] == null:
			push_error("Dimension %s: missing shader %s" % [id, file])
	return _shaders[file]

# JSON value -> shader parameter: "#rrggbb" colour, "@key" palette colour,
# image path -> texture, [x, y(, z(, w))] -> vector.
func _value(value):
	if value is String:
		if value.begins_with("#"):
			return Color.html(value)
		if value.begins_with("@"):
			return color(value.substr(1))
		if value.get_extension() in ["png", "jpg", "webp", "svg"]:
			return _resource(value)
	if value is Array:
		match value.size():
			2: return Vector2(value[0], value[1])
			3: return Vector3(value[0], value[1], value[2])
			4: return Vector4(value[0], value[1], value[2], value[3])
	return value

func _set_params(material: ShaderMaterial, params: Dictionary) -> void:
	for key in params:
		material.set_shader_parameter(key, _value(params[key]))

## Shared material for a surface role ("floor", "wall", "prop", "character",
## "weapon", "bullet", "pickup", "fx", "flash") tinted with a palette key.
func material(role: String, color_key: String) -> Material:
	var key = role + ":" + color_key
	if _materials.has(key):
		return _materials[key]
	var spec: Dictionary = data.get("roles", {}).get(role, {})
	var made: Material
	if role == "flash" and spec.is_empty():
		var flat = StandardMaterial3D.new()
		flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flat.albedo_color = color(color_key)
		made = flat
	else:
		var shaded = ShaderMaterial.new()
		var shader = _shader(spec.get("shader", data.get("surface_shader", "")))
		shaded.shader = shader if shader != null else DEFAULT_SHADER
		_set_params(shaded, data.get("surface_params", {}))
		_set_params(shaded, spec.get("params", {}))
		shaded.set_shader_parameter("albedo", color(color_key))
		var outline: Dictionary = data.get("outline", {})
		var width = float(spec.get("outline_width", 0.0 if role in NO_OUTLINE else outline.get("width", 0.0)))
		if width > 0.0:
			shaded.next_pass = _outline(width)
		made = shaded
	_materials[key] = made
	return made

func _outline(width: float) -> Material:
	var key = "outline:%f" % width
	if not _materials.has(key):
		var outline: Dictionary = data.get("outline", {})
		var hull = ShaderMaterial.new()
		var shader = _shader(outline.get("shader", ""))
		hull.shader = shader if shader != null else OUTLINE_SHADER
		_set_params(hull, outline.get("params", {}))
		hull.set_shader_parameter("ink", _value(outline.get("color", "@ink")))
		hull.set_shader_parameter("width", width)
		_materials[key] = hull
	return _materials[key]

## Every material built so far, for shader warm-up.
func materials() -> Array:
	return _materials.values()
