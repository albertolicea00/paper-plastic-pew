class_name CartoonIcons
extends DimensionIcons
## Bold comic symbols: a POW starburst, zoom lines, a goggly eye.

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Spiky comic burst.
	var p = PackedVector2Array()
	for i in 16:
		var a = TAU * i / 16.0 - PI * 0.5
		p.append(at + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.5))
	c.draw_colored_polygon(p, col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for i in 3:
		var y = (i - 1) * r * 0.45
		c.draw_line(at + Vector2(-r, y), at + Vector2(r * 0.15, y), col, 4.0, true)
	c.draw_polyline(PackedVector2Array([at + Vector2(r * 0.1, -r * 0.6), at + Vector2(r * 0.8, 0), at + Vector2(r * 0.1, r * 0.6)]), col, 4.0, true)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Big goggly eye with a highlight.
	c.draw_arc(at, r * 0.9, 0, TAU, 28, col, 4.0, true)
	c.draw_circle(at + Vector2(r * 0.12, r * 0.08), r * 0.4, col)
	c.draw_circle(at + Vector2(-r * 0.12, -r * 0.18), r * 0.12, Color(col, 0.0))

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Two bouncy loop arrows.
	for s in [1.0, -1.0]:
		c.draw_arc(at, r * 0.62, deg_to_rad(20 if s > 0 else 200), deg_to_rad(160 if s > 0 else 340), 16, col, 4.0, true)
		var end = at + Vector2(cos(deg_to_rad(160 if s > 0 else 340)), sin(deg_to_rad(160 if s > 0 else 340))) * r * 0.62
		c.draw_line(end, end + Vector2(s * r * 0.25, -s * r * 0.2), col, 4.0, true)
		c.draw_line(end, end + Vector2(s * r * 0.3, s * r * 0.1), col, 4.0, true)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Fat rounded bars (capsule ends).
	for sx in [-1.0, 1.0]:
		var x = at.x + sx * r * 0.32
		c.draw_line(Vector2(x, at.y - r * 0.42), Vector2(x, at.y + r * 0.42), col, r * 0.34, true)
