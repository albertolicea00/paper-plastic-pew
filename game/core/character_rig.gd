class_name CharacterRig
extends Node3D
## Procedural character made of named parts. Gameplay feeds the state fields;
## the active dimension's animator turns them into a pose every frame.
## Parts: body, head, visor, hand_l, hand_r, foot_l, foot_r, weapon (optional),
## plus build extras (horn_l, horn_r). Forward is -Z.

var parts: Dictionary = {}
var rest: Dictionary = {}
var base_scale = 1.0
# Animation state, written by the owning actor.
var clock = 0.0
var phase = 0.0
var speed_ratio = 0.0
var move_local = Vector3.ZERO
var recoil = 0.0
var hurt = 0.0
var dash = 0.0
var spawn = 0.0
var death = 0.0
var dead = false
var variation = 0.0
var _flash = 0.0

func build(look: Dictionary) -> void:
	base_scale = float(look.get("scale", 1.0))
	variation = randf()
	var tone: String = look.get("color", "grunt")
	var accent: String = look.get("accent", "ink")
	var shape: String = look.get("build", "biped")
	var girth = {"biped": 0.32, "runner": 0.25, "tank": 0.5, "boss": 0.46}.get(shape, 0.32)
	var body = CapsuleMesh.new()
	body.radius = girth
	body.height = 0.95 if shape != "runner" else 0.85
	_part("body", body, Vector3(0, 0.72, 0), tone)
	var head = SphereMesh.new()
	head.radius = 0.34 if shape == "runner" else 0.24 if shape == "tank" else 0.29
	head.height = head.radius * 2.0
	_part("head", head, Vector3(0, 1.22 + head.radius, 0), tone)
	var visor = BoxMesh.new()
	visor.size = Vector3(head.radius * 1.3, head.radius * 0.42, head.radius * 0.5)
	_part("visor", visor, Vector3(0, 1.24 + head.radius, -head.radius * 0.8), accent)
	for side in [-1, 1]:
		var tag = "l" if side < 0 else "r"
		var hand: Mesh
		if shape == "runner":
			var claw = CylinderMesh.new()
			claw.top_radius = 0.0
			claw.bottom_radius = 0.1
			claw.height = 0.5
			hand = claw
		else:
			var fist = SphereMesh.new()
			fist.radius = 0.12 * (1.5 if shape == "tank" else 1.0)
			fist.height = fist.radius * 2.0
			hand = fist
		_part("hand_" + tag, hand, Vector3(side * (girth + 0.14), 0.82, -0.22), accent if shape == "runner" else tone)
		if shape == "runner":
			parts["hand_" + tag].rotation.x = -PI * 0.5
			rest["hand_" + tag] = parts["hand_" + tag].transform
		var foot = BoxMesh.new()
		foot.size = Vector3(0.2, 0.14, 0.34)
		_part("foot_" + tag, foot, Vector3(side * girth * 0.6, 0.07, -0.03), "ink")
		if shape == "boss":
			var horn = CylinderMesh.new()
			horn.top_radius = 0.0
			horn.bottom_radius = 0.09
			horn.height = 0.4
			_part("horn_" + tag, horn, Vector3(side * 0.2, 1.72, 0), accent)
			parts["horn_" + tag].rotation.z = -side * 0.5
			rest["horn_" + tag] = parts["horn_" + tag].transform
	if look.get("weapon", true):
		var gun = BoxMesh.new()
		gun.size = Vector3(0.14, 0.16, 0.7) * (1.5 if shape in ["tank", "boss"] else 1.0)
		_part("weapon", gun, Vector3(girth + 0.14, 0.86, -0.5), "weapon", "weapon")
	reset()

func _part(part: String, mesh: Mesh, at: Vector3, color_key: String, role: String = "character") -> void:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	add_child(node)
	parts[part] = node
	rest[part] = node.transform
	Dimensions.hub.style(node, role, color_key)

## Back to the rest pose; animators call this first.
func reset() -> void:
	for part in parts:
		parts[part].transform = rest[part]
	transform = Transform3D(Basis().scaled(Vector3.ONE * base_scale), Vector3.ZERO)

## Offset a part from where it currently is. Unknown parts are ignored so
## animators can address optional parts (weapon, horns) freely.
func move(part: String, offset: Vector3) -> void:
	if parts.has(part):
		parts[part].position += offset

func turn(part: String, euler: Vector3) -> void:
	if parts.has(part):
		parts[part].rotation += euler

func stretch(part: String, factor: Vector3) -> void:
	if parts.has(part):
		parts[part].scale *= factor

## Scale the whole character around its feet.
func squash(factor: Vector3) -> void:
	scale = factor * base_scale

func flash(seconds: float = 0.07) -> void:
	if _flash <= 0.0:
		var white = Dimensions.hub.active.material("flash", "flash")
		for part in parts:
			parts[part].material_override = white
	_flash = seconds

func tick(delta: float) -> void:
	clock += delta
	phase += delta * (4.0 + speed_ratio * 9.0) * speed_ratio
	recoil = move_toward(recoil, 0.0, delta * 7.0)
	hurt = move_toward(hurt, 0.0, delta * 4.0)
	dash = move_toward(dash, 0.0, delta * 3.5)
	spawn = move_toward(spawn, 1.0, delta * 3.5)
	if dead:
		death = move_toward(death, 1.0, delta * 2.2)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			for part in parts:
				Dimensions.hub.apply(parts[part])
	Dimensions.hub.active.animator.animate(self, delta)
