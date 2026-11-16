class_name Dimensions
extends Node
## Registry of dimension packs and the live style switch.
## Anything visual registers through style(); shift_to() restyles all of it.

signal shifted(pack: DimensionPack)

const ROOT = "res://dimensions"
const GROUP = "styled"
# Nodes whose shapes come from the pack builder; they implement rebuild().
const REBUILT = "rebuilt"
static var hub: Dimensions

var packs: Array[DimensionPack] = []
var active: DimensionPack

func _init() -> void:
	hub = self
	for folder in DirAccess.get_directories_at(ROOT):
		var pack = DimensionPack.load_from(ROOT.path_join(folder))
		if pack != null:
			packs.append(pack)
	packs.sort_custom(func(a, b): return a.order < b.order)
	if packs.is_empty():
		push_error("No dimension packs found in " + ROOT)
		return
	active = packs[0]

func by_id(id: String) -> DimensionPack:
	for pack in packs:
		if pack.id == id:
			return pack
	return packs[0]

func ids() -> Array:
	return packs.map(func(pack): return pack.id)

func style(node: GeometryInstance3D, role: String, color_key: String) -> void:
	node.set_meta("style", [role, color_key])
	node.add_to_group(GROUP)
	apply(node)

func apply(node: GeometryInstance3D) -> void:
	var tag: Array = node.get_meta("style")
	node.material_override = active.material(tag[0], tag[1])

func shift_to(id: String) -> void:
	var next = by_id(id)
	if next == active:
		return
	active = next
	get_tree().call_group(REBUILT, "rebuild")
	for node in get_tree().get_nodes_in_group(GROUP):
		apply(node)
	shifted.emit(active)

## A different pack than the active one, for surprise shifts.
func random_other() -> String:
	var others = packs.filter(func(pack): return pack != active)
	return active.id if others.is_empty() else others.pick_random().id

func following() -> String:
	return packs[(packs.find(active) + 1) % packs.size()].id
