extends Node2D

const DeathEffect := preload("res://2/Effects/death_effect.gd")

signal finished

const DURATION := 0.834
const TEXTURE := preload("res://2/Player/madeline_hair.png")
const CIRCLE := Rect2(0, 0, 10, 10)
const OUTLINE: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

const RESPAWN_DURATION := 0.6

var color := Color.WHITE
var percent := 0.0
var _respawn := false
var _time := 0.0


static func spawn_respawn(parent: Node, at: Vector2, hair_color: Color) -> DeathEffect:
	var fx := spawn(parent, at, hair_color)
	fx._respawn = true
	fx.percent = 1.0
	return fx


static func spawn(parent: Node, at: Vector2, hair_color: Color) -> DeathEffect:
	var fx := DeathEffect.new()
	fx.position = at
	fx.color = hair_color
	fx.z_index = 5
	parent.add_child(fx)
	return fx


func _physics_process(delta: float) -> void:
	if _respawn:
		_time += delta
		var t := minf(_time / RESPAWN_DURATION, 1.0)
		percent = 1.0 - _cube_out(t)
		if t >= 1.0:
			finished.emit()
			queue_free()
		else:
			queue_redraw()
		return
	percent += delta / DURATION
	if percent >= 1.0:
		finished.emit()
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var tint := color if int(floorf(percent * 10.0)) % 2 == 0 else Color.WHITE
	var scale_factor := 0.5 + percent if percent < 0.5 else _cube_out(1.0 - (percent - 0.5) * 2.0)
	var size := Vector2(10, 10) * scale_factor
	var distance := _cube_out(percent) * 24.0
	for pass_tint in [Color.BLACK, tint]:
		for i in 8:
			var angle := (i / 8.0 + percent * 0.25) * TAU
			var center := (Vector2.from_angle(angle) * distance).round()
			var shifts: Array[Vector2] = [Vector2.ZERO]
			if pass_tint == Color.BLACK:
				shifts = OUTLINE
			for shift in shifts:
				draw_texture_rect_region(TEXTURE, Rect2(center + shift - size / 2.0, size), CIRCLE, pass_tint)


static func _cube_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
