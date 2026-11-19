class_name DimensionIcons
extends RefCounted
## Touch-button icons for a dimension. Packs extend this ("icons" in pack.json)
## and override draw() to give each action a symbol in their own style.
## Everything is drawn with canvas_item calls on `c` (the TouchSticks control),
## centred at `at`, within radius `r`, in the world's line colour `col`.
## Actions: fire, dash, view, swap, pause.

func draw(c: CanvasItem, name: String, at: Vector2, r: float, col: Color) -> void:
	match name:
		"fire": fire(c, at, r, col)
		"dash": dash(c, at, r, col)
		"view": view(c, at, r, col)
		"swap": swap(c, at, r, col)
		"pause": pause(c, at, r, col)

func fire(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.75, 0, TAU, 20, col, 3.0, true)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		c.draw_line(at + d * r * 0.45, at + d * r * 1.05, col, 3.0, true)
	c.draw_circle(at, r * 0.14, col)

func dash(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for ox in [-0.28, 0.34]:
		var b = at + Vector2(ox * r, 0)
		c.draw_polyline(PackedVector2Array([b + Vector2(-r * 0.3, -r * 0.55), b + Vector2(r * 0.32, 0), b + Vector2(-r * 0.3, r * 0.55)]), col, 3.0, true)

func view(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.95, deg_to_rad(205), deg_to_rad(335), 14, col, 3.0, true)
	c.draw_arc(at, r * 0.95, deg_to_rad(25), deg_to_rad(155), 14, col, 3.0, true)
	c.draw_circle(at, r * 0.32, col)

func swap(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	c.draw_arc(at, r * 0.62, deg_to_rad(300), deg_to_rad(560), 22, col, 3.0, true)
	var tip = at + Vector2(cos(deg_to_rad(300)), sin(deg_to_rad(300))) * r * 0.62
	c.draw_line(tip, tip + Vector2(-r * 0.3, -r * 0.05), col, 3.0, true)
	c.draw_line(tip, tip + Vector2(0.0, -r * 0.32), col, 3.0, true)

func pause(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		c.draw_rect(Rect2(at + Vector2(sx * r * 0.32 - r * 0.11, -r * 0.5), Vector2(r * 0.22, r)), col)

# A filled polygon from points, a helper packs can reuse for solid glyphs.
func poly(c: CanvasItem, points: PackedVector2Array, col: Color) -> void:
	if points.size() >= 3:
		c.draw_colored_polygon(points, col)
