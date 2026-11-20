class_name AnimeIcons
extends DimensionIcons
## Sharp ink / manga symbols: shuriken, speed slashes, a sharp eye.

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Four-point throwing star.
	var p = PackedVector2Array()
	for i in 8:
		var a = TAU * i / 8.0 - PI * 0.5
		p.append(at + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.38))
	c.draw_colored_polygon(p, col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for i in 3:
		var y = (i - 1) * r * 0.42
		c.draw_line(at + Vector2(-r, y), at + Vector2(r * 0.2 - absf(i - 1) * r * 0.2, y), col, 3.0, true)
	c.draw_polyline(PackedVector2Array([at + Vector2(r * 0.2, -r * 0.55), at + Vector2(r * 0.75, 0), at + Vector2(r * 0.2, r * 0.55)]), col, 3.0, true)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Angular manga eye.
	c.draw_polyline(PackedVector2Array([at + Vector2(-r, r * 0.1), at + Vector2(-r * 0.2, -r * 0.6), at + Vector2(r, -r * 0.1)]), col, 3.0, true)
	c.draw_polyline(PackedVector2Array([at + Vector2(-r, r * 0.1), at + Vector2(0, r * 0.55), at + Vector2(r, -r * 0.1)]), col, 3.0, true)
	c.draw_circle(at, r * 0.3, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.6, deg_to_rad(110), deg_to_rad(410), 24, col, 3.0, true)
	var tip = at + Vector2(cos(deg_to_rad(110)), sin(deg_to_rad(110))) * r * 0.6
	c.draw_line(tip, tip + Vector2(r * 0.34, r * 0.04), col, 3.0, true)
	c.draw_line(tip, tip + Vector2(r * 0.06, r * 0.36), col, 3.0, true)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		var x = at.x + sx * r * 0.3
		c.draw_line(Vector2(x + r * 0.12, at.y - r * 0.5), Vector2(x - r * 0.12, at.y + r * 0.5), col, 7.0, true)
