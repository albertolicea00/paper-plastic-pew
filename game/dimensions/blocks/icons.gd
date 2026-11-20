class_name BlocksIcons
extends DimensionIcons
## Toy-brick symbols: studded bolts, a stud arrow, a brick-framed eye.

func _stud(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_circle(at, r, col)

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# A 2x1 brick with studs, pointing right.
	c.draw_rect(Rect2(at - Vector2(r * 0.7, r * 0.35), Vector2(r * 1.2, r * 0.7)), col)
	for sx in [-0.35, 0.1]:
		c.draw_circle(at + Vector2(sx * r, -r * 0.55), r * 0.18, col)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(r * 0.5, -r * 0.35), at + Vector2(r * 0.95, 0), at + Vector2(r * 0.5, r * 0.35)]), col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# An arrow built from studs.
	for i in 3:
		_stud(c, at + Vector2((i - 1.5) * r * 0.5, 0), r * 0.2, col)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(r * 0.2, -r * 0.5), at + Vector2(r * 0.85, 0), at + Vector2(r * 0.2, r * 0.5)]), col)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Brick frame with a stud pupil.
	c.draw_rect(Rect2(at - Vector2(r * 0.85, r * 0.6), Vector2(r * 1.7, r * 1.2)), col, false, 4.0)
	c.draw_circle(at, r * 0.3, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Two interlocking brick arrows.
	c.draw_rect(Rect2(at + Vector2(-r * 0.7, -r * 0.5), Vector2(r * 1.0, r * 0.3)), col)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(r * 0.3, -r * 0.7), at + Vector2(r * 0.75, -r * 0.35), at + Vector2(r * 0.3, 0)]), col)
	c.draw_rect(Rect2(at + Vector2(-r * 0.3, r * 0.2), Vector2(r * 1.0, r * 0.3)), col)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-r * 0.3, 0), at + Vector2(-r * 0.75, r * 0.35), at + Vector2(-r * 0.3, r * 0.7)]), col)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Two bricks, each with a stud.
	for sx in [-1.0, 1.0]:
		var x = at.x + sx * r * 0.32
		c.draw_rect(Rect2(Vector2(x - r * 0.16, at.y - r * 0.45), Vector2(r * 0.32, r * 0.9)), col)
		c.draw_circle(Vector2(x, at.y - r * 0.62), r * 0.1, col)
