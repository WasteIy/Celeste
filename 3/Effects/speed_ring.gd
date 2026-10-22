extends Node2D

const SpeedRing := preload("res://3/Effects/speed_ring.gd")

const DURATION := 0.3
const COLOR := Color(0.8, 0.82, 0.9, 0.6)

var _time := 0.0


static func spawn(parent: Node, at: Vector2, direction: Vector2) -> void:
	var ring := SpeedRing.new()
	ring.position = at.round()
	ring.rotation = direction.angle()
	ring.z_index = -1
	parent.add_child(ring)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t := _time / DURATION
	var eased := 1.0 - (1.0 - t) * (1.0 - t)
	var radius := Vector2(lerpf(2.0, 4.0, eased), lerpf(6.0, 11.0, eased))
	var points := PackedVector2Array()
	for i in 25:
		var a := i / 24.0 * TAU
		points.append(Vector2(cos(a) * radius.x, sin(a) * radius.y))
	var color := COLOR
	color.a *= 1.0 - t
	draw_polyline(points, color, 1.0, false)
