class_name StickIcons
extends DimensionIcons
## Hand-drawn doodle symbols: wobbly strokes on the page.

# A line with a little hand-drawn wobble in the middle.
func _wob(c: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float = 3.0) -> void:
	var mid = a.lerp(b, 0.5)
	var n = (b - a).orthogonal().normalized()
	var k = a.distance_to(b) * 0.08
	c.draw_polyline(PackedVector2Array([a, a.lerp(b, 0.33) + n * k, a.lerp(b, 0.66) - n * k, b]), col, w, true)

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Scribbled target.
	c.draw_arc(at, r * 0.75, deg_to_rad(10), deg_to_rad(380), 18, col, 3.0, true)
	_wob(c, at + Vector2(-r, 0), at + Vector2(r, 0), col)
	_wob(c, at + Vector2(0, -r), at + Vector2(0, r), col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for i in 3:
		var y = (i - 1) * r * 0.45
		_wob(c, at + Vector2(-r, y), at + Vector2(r * 0.2, y), col)
	c.draw_polyline(PackedVector2Array([at + Vector2(r * 0.15, -r * 0.5), at + Vector2(r * 0.75, 0), at + Vector2(r * 0.15, r * 0.5)]), col, 3.0, true)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Doodled eye.
	_wob(c, at + Vector2(-r, 0), at + Vector2(0, -r * 0.6), col)
	_wob(c, at + Vector2(0, -r * 0.6), at + Vector2(r, 0), col)
	_wob(c, at + Vector2(-r, 0), at + Vector2(0, r * 0.6), col)
	_wob(c, at + Vector2(0, r * 0.6), at + Vector2(r, 0), col)
	c.draw_circle(at, r * 0.28, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.6, deg_to_rad(300), deg_to_rad(555), 20, col, 3.0, true)
	var tip = at + Vector2(cos(deg_to_rad(300)), sin(deg_to_rad(300))) * r * 0.6
	_wob(c, tip, tip + Vector2(-r * 0.32, 0), col)
	_wob(c, tip, tip + Vector2(0, -r * 0.32), col)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		var x = at.x + sx * r * 0.3
		_wob(c, Vector2(x, at.y - r * 0.5), Vector2(x, at.y + r * 0.5), col, 6.0)
