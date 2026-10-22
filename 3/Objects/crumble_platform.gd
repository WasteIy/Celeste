@tool
extends StaticBody2D

const Player := preload("res://3/Player/player.gd")

const TEXTURE := preload("res://3/Objects/crumble_block.png")
const OUTLINE := preload("res://3/Objects/crumble_block_outline.png")
const SHAKE_ON_TOP := 0.6
const SHAKE_CLIMBING := 1.0
const BREAK_DELAY := 0.4
const RESPAWN_TIME := 2.0
const FALL_TIME := 0.25
const FALL_STAGGER := 0.05

@export_range(1, 20) var width := 3:
	set(value):
		width = value
		_rebuild()

var _pieces: Array[int] = []
var _shape: CollisionShape2D
var _shake_timer := 0.0
var _outline_alpha := 0.0
var _outline_target := 0.0
var _fall_time := -1.0
var _grow_time := -1.0
var _busy := false


var Particles:
	get:
		return get_tree().get_first_node_in_group(&"particles")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.shape = RectangleShape2D.new()
		add_child(_shape)
	(_shape.shape as RectangleShape2D).size = Vector2(width * 8, 8)
	_shape.position = Vector2(width * 4, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	_pieces.clear()
	for i in width:
		_pieces.append(rng.randi_range(0, 3))
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_outline_alpha = move_toward(_outline_alpha, _outline_target, delta * 4.0)
	if _shake_timer > 0.0:
		_shake_timer -= delta
	if _fall_time >= 0.0:
		_fall_time += delta
	if _grow_time >= 0.0:
		_grow_time += delta
		if _grow_time > FALL_TIME + FALL_STAGGER * 4:
			_grow_time = -1.0
	if not _busy:
		var player := get_tree().get_first_node_in_group(&"player") as Player
		if player:
			if _player_on_top(player):
				_crumble(true)
			elif _player_climbing(player):
				_crumble(false)
	queue_redraw()


func _rect() -> Rect2:
	return Rect2(global_position, Vector2(width * 8, 8))


func _player_on_top(player: Player) -> bool:
	if player.state == Player.State.DEAD or player.velocity.y < 0.0:
		return false
	var box := player.get_hitbox()
	box.position.y += 1
	return box.intersects(_rect())


func _player_climbing(player: Player) -> bool:
	if player.state != Player.State.CLIMB:
		return false
	var box := player.get_hitbox()
	box.position.x += player.facing
	return box.intersects(_rect())


func _crumble(on_top: bool) -> void:
	_busy = true
	_shake_timer = SHAKE_ON_TOP if on_top else SHAKE_CLIMBING
	_emit_dust()
	await get_tree().create_timer(_shake_timer, false, true).timeout
	var timer := BREAK_DELAY
	var player := get_tree().get_first_node_in_group(&"player") as Player
	while timer > 0.0 and (not on_top or (player and _player_on_top(player))):
		await get_tree().physics_frame
		timer -= get_physics_process_delta_time()
	_shake_timer = 0.0
	_shape.set_deferred(&"disabled", true)
	_outline_target = 1.0
	_fall_time = 0.0
	_emit_dust()
	await get_tree().create_timer(RESPAWN_TIME, false, true).timeout
	while player and is_instance_valid(player) and player.get_hitbox().intersects(_rect().grow(-0.01)):
		await get_tree().physics_frame
	_shape.set_deferred(&"disabled", false)
	_outline_target = 0.0
	_fall_time = -1.0
	_grow_time = 0.0
	_busy = false


func _emit_dust() -> void:
	for i in width:
		Particles.dust_burst(global_position + Vector2(i * 8 + 4, 6), -PI / 2.0, 1)


func _draw() -> void:
	if _outline_alpha > 0.0:
		var tint := Color(1, 1, 1, _outline_alpha)
		for i in width:
			var region_x := 8 if i > 0 and i < width - 1 else (0 if i == 0 else 16)
			if width == 1:
				region_x = 24
			draw_texture_rect_region(OUTLINE, Rect2(i * 8, 0, 8, 8), Rect2(region_x, 0, 8, 8), tint)
	for i in width:
		var offset := Vector2.ZERO
		var scale_factor := 1.0
		var alpha := 1.0
		if _fall_time >= 0.0:
			var t := clampf((_fall_time - (i % 4) * FALL_STAGGER) / FALL_TIME, 0.0, 1.0)
			if t >= 1.0:
				continue
			offset.y = t * t * 8.0
			alpha = 1.0 - t
		elif _grow_time >= 0.0:
			var t := clampf((_grow_time - (i % 4) * FALL_STAGGER) / FALL_TIME, 0.0, 1.0)
			scale_factor = 1.0 - (1.0 - t) * (1.0 - t)
		if _shake_timer > 0.0:
			offset += Vector2(randi_range(-1, 1), randi_range(-1, 1))
		var center := Vector2(i * 8 + 4, 4) + offset
		draw_set_transform(center, 0.0, Vector2.ONE * scale_factor)
		draw_texture_rect_region(TEXTURE, Rect2(-4, -4, 8, 8), Rect2(_pieces[i] * 8, 0, 8, 8), Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO)
