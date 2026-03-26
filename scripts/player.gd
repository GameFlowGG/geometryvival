extends Node2D

## Shape types: 0=Circle, 1=Square, 2=Triangle
## Kill rules: Circle(0) kills Square(1), Square(1) kills Triangle(2), Triangle(2) kills Circle(0)

const SPEED = 300.0
const SHAPE_NAMES = ["Circle", "Square", "Triangle"]
const COLORS = [
	Color(0.35, 0.55, 0.95),   # Blue  - Circle
	Color(0.95, 0.35, 0.35),   # Red   - Square
	Color(0.35, 0.95, 0.45),   # Green - Triangle
]

var current_shape: int = 0:
	set(value):
		current_shape = value
		queue_redraw()

var hp: int = 10:
	set(value):
		hp = value
		queue_redraw()

var is_dead: bool = false
var invincible: bool = false
var invincible_timer: float = 0.0
var shape_cooldown: float = 0.0
var flash_timer: float = 0.0

func get_shape() -> int:
	return current_shape

func _physics_process(delta: float):
	# Invincibility (runs on all peers for visual)
	if invincible:
		invincible_timer -= delta
		flash_timer += delta
		modulate.a = 0.3 if fmod(flash_timer, 0.15) < 0.075 else 1.0
		if invincible_timer <= 0:
			invincible = false
			modulate.a = 1.0

	# Only the owning player processes input
	if not is_multiplayer_authority():
		return
	if is_dead:
		return

	# Movement
	var input = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1

	position += input.normalized() * SPEED * delta
	position.x = clamp(position.x, 20, 1260)
	position.y = clamp(position.y, 20, 700)

	# Shape change
	shape_cooldown -= delta
	if Input.is_key_pressed(KEY_SPACE) and shape_cooldown <= 0:
		shape_cooldown = 0.3
		current_shape = (current_shape + 1) % 3

@rpc("any_peer", "call_local", "reliable")
func take_damage(amount: int):
	if invincible or is_dead:
		return
	hp -= amount
	invincible = true
	invincible_timer = 0.5
	flash_timer = 0.0
	if hp <= 0:
		hp = 0
		is_dead = true
		modulate.a = 0.2

func _draw():
	var color = COLORS[current_shape]

	match current_shape:
		0:  # Circle
			draw_circle(Vector2.ZERO, 20, color)
			draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color.WHITE, 2.0)
		1:  # Square
			draw_rect(Rect2(-18, -18, 36, 36), color)
			draw_rect(Rect2(-18, -18, 36, 36), Color.WHITE, false, 2.0)
		2:  # Triangle
			var pts = PackedVector2Array([
				Vector2(0, -22), Vector2(20, 18), Vector2(-20, 18)
			])
			draw_colored_polygon(pts, color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color.WHITE, 2.0)

	# HP bar
	var bw = 40.0
	var by = -34.0
	draw_rect(Rect2(-bw / 2, by, bw, 5), Color(0.2, 0.2, 0.2))
	var ratio = float(hp) / 10.0
	var hcol = Color.GREEN_YELLOW if hp > 3 else Color.RED
	draw_rect(Rect2(-bw / 2, by, bw * ratio, 5), hcol)
