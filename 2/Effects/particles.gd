extends Node2D

const ParticleType := preload("res://2/Effects/particle_type.gd")

const MAX_PARTICLES := 800

var DUST := _make_dust()
var DASH_A := _make_dash(Color("44b7ff"), Color("75c9ff"))
var DASH_B := _make_dash(Color("ff6def"), Color("ff97f5"))
var GLOW := _make_glow()

var _particles: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(&"particles")
	z_index = 10


func emit(type: ParticleType, at: Vector2, direction := INF, amount := 1, spread := Vector2.ZERO) -> void:
	for i in amount:
		if _particles.size() >= MAX_PARTICLES:
			_particles.pop_front()
		var dir := type.direction if direction == INF else direction
		var angle := dir - type.direction_range / 2.0 + randf() * type.direction_range
		var life := randf_range(type.life_min, type.life_max)
		var color := type.color
		if type.color_mode == ParticleType.ColorMode.CHOOSE and randf() < 0.5:
			color = type.color2
		var size := type.size - type.size_range / 2.0 + randf() * type.size_range
		_particles.append({
			type = type,
			position = at + Vector2(randf_range(-spread.x, spread.x), randf_range(-spread.y, spread.y)),
			speed = Vector2.from_angle(angle) * randf_range(type.speed_min, type.speed_max),
			life = life,
			start_life = life,
			start_color = color,
			color = color,
			start_size = size,
			size = size,
			rotation = randf() * TAU if type.random_rotation else 0.0,
			texture = type.textures.pick_random() if not type.textures.is_empty() else null,
		})


func dust_burst(at: Vector2, direction: float, amount := 1) -> void:
	var spread := (Vector2.from_angle(direction - PI / 2.0) * 4.0).abs()
	emit(DUST, at, direction, amount, spread)


func clear() -> void:
	_particles.clear()


func _physics_process(delta: float) -> void:
	for i in range(_particles.size() - 1, -1, -1):
		var p := _particles[i]
		var type: ParticleType = p.type
		var ease := float(p.life) / float(p.start_life)
		p.life -= delta
		if p.life <= 0.0:
			_particles.remove_at(i)
			continue

		var alpha := 1.0
		match type.fade_mode:
			ParticleType.FadeMode.LINEAR:
				alpha = ease
			ParticleType.FadeMode.LATE:
				alpha = minf(1.0, ease / 0.25)
			ParticleType.FadeMode.IN_AND_OUT:
				alpha = minf(1.0, ease / 0.25) if ease <= 0.75 else 1.0 - (ease - 0.75) / 0.25

		var color: Color = p.start_color
		match type.color_mode:
			ParticleType.ColorMode.BLINK:
				color = p.start_color if fmod(p.life, 0.2) < 0.1 else type.color2
			ParticleType.ColorMode.FADE:
				color = type.color2.lerp(p.start_color, ease)
		color.a *= alpha
		p.color = color

		p.position += p.speed * delta
		p.speed += type.acceleration * delta
		p.speed = p.speed.move_toward(Vector2.ZERO, type.friction * delta)
		if type.scale_out:
			p.size = p.start_size * (1.0 - pow(1.0 - ease, 3.0))
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var pos: Vector2 = (p.position as Vector2).round()
		var size: float = p.size
		if p.texture:
			var tex: Texture2D = p.texture
			draw_set_transform(pos, p.rotation, Vector2(size, size))
			draw_texture(tex, -tex.get_size() / 2.0, p.color)
		else:
			draw_set_transform(pos, 0.0, Vector2(size, size))
			draw_rect(Rect2(-0.5, -0.5, 1, 1), p.color)
	draw_set_transform(Vector2.ZERO)


func _make_dust() -> ParticleType:
	var t := ParticleType.new()
	for i in 4:
		t.textures.append(load("res://2/Effects/smoke_%d.png" % i))
	t.color = Color(1, 1, 1, 0.6)
	t.acceleration = Vector2(0, 4)
	t.life_min = 0.3
	t.life_max = 0.5
	t.size = 0.7
	t.size_range = 0.2
	t.direction = -PI / 2.0
	t.direction_range = 0.5
	t.speed_min = 5.0
	t.speed_max = 15.0
	t.random_rotation = true
	t.scale_out = true
	return t


func _make_dash(c1: Color, c2: Color) -> ParticleType:
	var t := ParticleType.new()
	t.color = c1
	t.color2 = c2
	t.color_mode = ParticleType.ColorMode.BLINK
	t.fade_mode = ParticleType.FadeMode.LATE
	t.life_min = 1.0
	t.life_max = 1.8
	t.size = 1.0
	t.speed_min = 10.0
	t.speed_max = 20.0
	t.acceleration = Vector2(0, 8)
	t.direction_range = PI / 3.0
	return t


func _make_glow() -> ParticleType:
	var t := ParticleType.new()
	t.color = Color("ff8563")
	t.color2 = Color("fff4a8")
	t.color_mode = ParticleType.ColorMode.BLINK
	t.fade_mode = ParticleType.FadeMode.LATE
	t.life_min = 1.0
	t.life_max = 1.5
	t.size = 1.0
	t.speed_min = 2.0
	t.speed_max = 6.0
	t.friction = 4.0
	t.direction_range = TAU
	return t
