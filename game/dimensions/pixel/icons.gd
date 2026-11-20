class_name PixelIcons
extends DimensionIcons
## 8-bit symbols built only from axis-aligned squares — no smooth curves.

func _px(c: CanvasItem, at: Vector2, cell: float, gx: float, gy: float, col: Color) -> void:
	c.draw_rect(Rect2(at + Vector2(gx, gy) * cell - Vector2(cell, cell) * 0.5, Vector2(cell, cell)), col)

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# A blocky bullet pointing right.
	var u = r * 0.32
	for g in [[-1.0, 0.0], [0.0, -0.5], [0.0, 0.5], [0.0, 0.0], [1.0, 0.0], [1.6, 0.0]]:
		c.draw_rect(Rect2(at + Vector2(g[0], g[1]) * u * 1.1 - Vector2(u, u) * 0.5, Vector2(u, u)), col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Stair-stepped pixel arrow.
	var u = r * 0.3
	for g in [[-1.5, 0.0], [-0.5, 0.0], [0.5, 0.0], [0.0, -1.0], [0.0, 1.0], [0.9, -0.5], [0.9, 0.5]]:
		_px(c, at, u, g[0], g[1], col)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Square eye ring with a square pupil.
	var u = r * 0.34
	for g in [[-1.0, -1.0], [0.0, -1.0], [1.0, -1.0], [-1.0, 0.0], [1.0, 0.0], [-1.0, 1.0], [0.0, 1.0], [1.0, 1.0]]:
		_px(c, at, u, g[0], g[1], col)
	_px(c, at, u, 0, 0, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	# Two pixel arrows, opposite directions.
	var u = r * 0.28
	for g in [[-1.5, -0.6], [-0.5, -0.6], [0.5, -0.6], [1.2, -1.1], [1.2, -0.1]]:
		_px(c, at, u, g[0], g[1], col)
	for g in [[1.5, 0.6], [0.5, 0.6], [-0.5, 0.6], [-1.2, 1.1], [-1.2, 0.1]]:
		_px(c, at, u, g[0], g[1], col)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		c.draw_rect(Rect2(at + Vector2(sx * r * 0.32 - r * 0.13, -r * 0.5), Vector2(r * 0.26, r)), col)
