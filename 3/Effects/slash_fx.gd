extends Node2D

const SlashFx := preload("res://3/Effects/slash_fx.gd")

const TEXTURE := preload("res://3/Effects/slash.png")
const FRAME_SIZE := Vector2(24, 8)
const FRAME_TIME := 0.05
const SPEED := 8.0

var _direction := Vector2.RIGHT
var _time := 0.0


static func burst(parent: Node, at: Vector2, angle: float) -> void:
	var fx := SlashFx.new()
	fx.position = at
	fx.rotation = angle
	fx._direction = Vector2.from_angle(angle)
	fx.z_index = 5
	parent.add_child(fx)


func _physics_process(delta: float) -> void:
	_time += delta
	position += _direction * SPEED * delta
	if _time >= FRAME_TIME * 4:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var frame := mini(int(_time / FRAME_TIME), 3)
	draw_texture_rect_region(TEXTURE, Rect2(-FRAME_SIZE / 2.0, FRAME_SIZE), Rect2(Vector2(frame * FRAME_SIZE.x, 0), FRAME_SIZE))
