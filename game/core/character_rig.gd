class_name CharacterRig
extends Node3D
## Character made of named parts. The active dimension's builder decides the
## shapes, its animator turns the state fields below into a pose every frame,
## and a dimension shift rebuilds the parts in place.
## Required parts: body, head, hand_l, hand_r, foot_l, foot_r, weapon
## (optional). Forward is -Z.

const FIRST_PERSON_PARTS = ["weapon", "hand_r"]
var parts: Dictionary = {}
var rest: Dictionary = {}
var look: Dictionary = {}
var kind = ""
var base_scale = 1.0
# First-person view shows only the weapon and the hand holding it.
var first_person = false
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

func build(character_look: Dictionary, character_kind: String) -> void:
	look = character_look
	kind = character_kind
	base_scale = float(look.get("scale", 1.0))
	variation = randf()
	add_to_group(Dimensions.REBUILT)
	rebuild()

## Throw the parts away and build them again with the active dimension.
func rebuild() -> void:
	for part in parts.values():
		part.free()
	parts.clear()
	rest.clear()
	_flash = 0.0
	Dimensions.hub.active.builder.character(self, look, kind)
	# Rest poses are read after the builder returns, so it may adjust parts.
	for part in parts:
		rest[part] = parts[part].transform
	set_first_person(first_person)
	reset()

## Add a named part; builders call this. Returns the node for further tweaks.
func add_part(part: String, mesh: Mesh, at: Vector3, color_key: String, role: String = "character", euler: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.rotation = euler
	add_child(node)
	parts[part] = node
	Dimensions.hub.style(node, role, color_key)
	return node

func set_first_person(value: bool) -> void:
	first_person = value
	for part in parts:
		parts[part].visible = not value or part in FIRST_PERSON_PARTS

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
