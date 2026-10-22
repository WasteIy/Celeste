extends Node2D

const COUNT := 50
const COLORS: Array[Color] = [Color(1, 1, 1, 0.9), Color(0.6, 0.75, 1.0, 0.8)]

@export var area := Rect2(0, 0, 320, 180)
@export var direction := Vector2(-1.0, 0.35)

var _flakes: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in COUNT:
		_flakes.append({
			position = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)),
			speed = rng.randf_range(15.0, 40.0),
			sine = rng.randf() * TAU,
			color = COLORS[rng.randi_range(0, 1)],
		})


func _physics_process(delta: float) -> void:
	for flake in _flakes:
		flake.sine += delta * 2.0
		flake.position += (direction.normalized() * flake.speed + Vector2(0, sin(flake.sine) * 6.0)) * delta
		var p: Vector2 = flake.position
		if p.x < area.position.x:
			p.x += area.size.x
		if p.y > area.end.y:
			p.y -= area.size.y
		flake.position = p
	queue_redraw()


func _draw() -> void:
	for flake in _flakes:
		draw_rect(Rect2((flake.position as Vector2).round(), Vector2.ONE), flake.color)
