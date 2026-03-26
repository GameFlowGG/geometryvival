extends Node2D

const COLORS = [
	Color(0.35, 0.55, 0.95, 0.75),  # Blue  - Circle
	Color(0.95, 0.35, 0.35, 0.75),  # Red   - Square
	Color(0.35, 0.95, 0.45, 0.75),  # Green - Triangle
]

var shape_type: int = 0:
	set(value):
		shape_type = value
		queue_redraw()

var speed: float = 80.0

func _physics_process(delta: float):
	if not multiplayer.is_server():
		return

	# Move toward nearest alive player
	var players = get_parent().get_parent().get_node("Players")
	var nearest_dist = INF
	var nearest_pos = position

	for player in players.get_children():
		if not (player is Node2D) or not player.has_method("get_shape"):
			continue
		if player.is_dead:
			continue
		var d = position.distance_to(player.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = player.position

	if nearest_dist < INF:
		position += (nearest_pos - position).normalized() * speed * delta

func _draw():
	var color = COLORS[shape_type]

	match shape_type:
		0:  # Circle
			draw_circle(Vector2.ZERO, 15, color)
			draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color.WHITE, 1.5)
		1:  # Square
			draw_rect(Rect2(-13, -13, 26, 26), color)
			draw_rect(Rect2(-13, -13, 26, 26), Color.WHITE, false, 1.5)
		2:  # Triangle
			var pts = PackedVector2Array([
				Vector2(0, -16), Vector2(15, 13), Vector2(-15, 13)
			])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color.WHITE, 1.5)
