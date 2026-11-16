class_name Vfx
extends Node3D
## Particles, camera shake, the per-dimension screen overlay and the flash
## that covers a dimension shift.

const CAPACITY = 512
var game: GameMatch
var particles: Array[Dictionary] = []
var cloud: MultiMeshInstance3D
var layer: CanvasLayer
var overlay: ColorRect
var flash: ColorRect
var trauma = 0.0
var impact_level = 0.0
var _freeze_until = 0

func _ready() -> void:
	game = get_parent()
	cloud = MultiMeshInstance3D.new()
	cloud.multimesh = MultiMesh.new()
	cloud.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	cloud.multimesh.use_colors = true
	cloud.multimesh.instance_count = CAPACITY
	cloud.multimesh.visible_instance_count = 0
	var chip = BoxMesh.new()
	chip.size = Vector3.ONE
	cloud.multimesh.mesh = chip
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	cloud.material_override = material
	cloud.custom_aabb = AABB(Vector3(-100, -5, -100), Vector3(200, 30, 200))
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cloud)
	layer = CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1, 1, 1, 0)
	layer.add_child(flash)
	use_pack(Dimensions.hub.active)

func use_pack(pack: DimensionPack) -> void:
	overlay.material = pack.overlay
	overlay.visible = pack.overlay != null

func shift_flash(pack: DimensionPack) -> void:
	use_pack(pack)
	flash.color = Color(pack.color("flash"), 0.9)
	impact(1.0)
	shake(0.6)

func burst(at: Vector3, color_key: String, count: int, speed: float = 6.0) -> void:
	var tint = Dimensions.hub.active.color(color_key)
	for i in mini(count, CAPACITY - particles.size()):
		particles.append({"at": at, "velocity": Vector3(randf_range(-1, 1), randf_range(0.1, 1.4), randf_range(-1, 1)).normalized() * randf_range(speed * 0.3, speed), "life": randf_range(0.25, 0.6), "size": randf_range(0.08, 0.2), "color": tint, "spin": randf() * TAU})

func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount * float(Dimensions.hub.active.feel.shake))

## Pulse fed to the overlay shader's `impact` uniform (speed lines, pops).
func impact(amount: float) -> void:
	impact_level = maxf(impact_level, amount)

## Freeze-frame on big hits; length comes from the pack's feel.hitstop.
func hitstop(strength: float = 1.0) -> void:
	var seconds = float(Dimensions.hub.active.feel.hitstop) * strength
	if seconds <= 0.0 or game.autopilot:
		return
	Engine.time_scale = 0.05
	_freeze_until = Time.get_ticks_msec() + int(seconds * 1000.0)

func camera_offset() -> Vector3:
	var push = trauma * trauma * 0.6
	return Vector3(randf_range(-push, push), 0, randf_range(-push, push))

func _process(delta: float) -> void:
	if _freeze_until > 0 and Time.get_ticks_msec() >= _freeze_until:
		_freeze_until = 0
		Engine.time_scale = game.time_scale
	flash.color.a = move_toward(flash.color.a, 0.0, delta * 3.5)
	if overlay.material != null:
		overlay.material.set_shader_parameter("impact", impact_level)
		overlay.material.set_shader_parameter("shift", flash.color.a)
	if not game.playing:
		return
	trauma = move_toward(trauma, 0.0, delta * 2.2)
	impact_level = move_toward(impact_level, 0.0, delta * 3.0)
	var count = 0
	var kept: Array[Dictionary] = []
	for particle in particles:
		particle.life -= delta
		if particle.life <= 0.0:
			continue
		particle.velocity.y -= delta * 14.0
		particle.at += particle.velocity * delta
		if particle.at.y < 0.05:
			particle.at.y = 0.05
			particle.velocity *= 0.5
		var extent = particle.size * minf(1.0, particle.life * 5.0)
		cloud.multimesh.set_instance_transform(count, Transform3D(Basis.from_euler(Vector3(particle.spin, particle.spin * 0.5, 0)).scaled(Vector3.ONE * extent), particle.at))
		cloud.multimesh.set_instance_color(count, particle.color)
		count += 1
		kept.append(particle)
	particles = kept
	cloud.multimesh.visible_instance_count = count

func _exit_tree() -> void:
	Engine.time_scale = 1.0
