class_name ClayIcons
extends DimensionIcons
## Soft plasticine symbols: a squished pellet, lumpy arrow, ball eye.

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# A squashed clay pellet with a little tail.
	var p = PackedVector2Array()
	for i in 20:
		var a = TAU * i / 20.0
		p.append(at + Vector2(cos(a) * r * 0.85, sin(a) * r * 0.62))
	c.draw_colored_polygon(p, col)
	c.draw_line(at + Vector2(-r * 0.7, 0), at + Vector2(-r * 1.05, -r * 0.2), col, 4.0, true)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Thick rounded chevron.
	c.draw_polyline(PackedVector2Array([at + Vector2(-r * 0.5, -r * 0.6), at + Vector2(r * 0.5, 0), at + Vector2(-r * 0.5, r * 0.6)]), col, r * 0.32, true)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.85, 0, TAU, 24, col, 4.0, true)
	c.draw_circle(at + Vector2(r * 0.18, r * 0.1), r * 0.34, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Two rolled clay-snake arrows.
	c.draw_arc(at, r * 0.6, deg_to_rad(300), deg_to_rad(560), 24, col, r * 0.2, true)
	var tip = at + Vector2(cos(deg_to_rad(300)), sin(deg_to_rad(300))) * r * 0.6
	c.draw_line(tip, tip + Vector2(-r * 0.3, 0), col, r * 0.2, true)
	c.draw_line(tip, tip + Vector2(0, -r * 0.3), col, r * 0.2, true)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Chubby soft bars.
	for sx in [-1.0, 1.0]:
		var x = at.x + sx * r * 0.34
		c.draw_line(Vector2(x, at.y - r * 0.38), Vector2(x, at.y + r * 0.38), col, r * 0.4, true)
