extends CharacterBody2D

const MadelineHair := preload("res://2/Player/madeline_hair.gd")
const DashTrail := preload("res://2/Effects/dash_trail.gd")
const DeathEffect := preload("res://2/Effects/death_effect.gd")
const SlashFx := preload("res://2/Effects/slash_fx.gd")
const SpeedRing := preload("res://2/Effects/speed_ring.gd")
const ParticleType := preload("res://2/Effects/particle_type.gd")

signal dashed(direction: Vector2)
signal died

enum State { NORMAL, CLIMB, DASH, DEAD }

const MAX_RUN := 90.0
const RUN_ACCEL := 1000.0
const RUN_REDUCE := 400.0
const AIR_MULT := 0.65

const DUCK_FRICTION := 500.0
const DUCK_CORRECT_CHECK := 4
const DUCK_CORRECT_SLIDE := 50.0
const DUCK_SUPER_JUMP_X_MULT := 1.25
const DUCK_SUPER_JUMP_Y_MULT := 0.5
const DODGE_SLIDE_SPEED_MULT := 1.2

const GRAVITY := 900.0
const HALF_GRAV_THRESHOLD := 40.0
const MAX_FALL := 160.0
const FAST_MAX_FALL := 240.0
const FAST_MAX_ACCEL := 300.0

const JUMP_GRACE_TIME := 0.1
const JUMP_SPEED := -105.0
const JUMP_H_BOOST := 40.0
const VAR_JUMP_TIME := 0.2
const CEILING_VAR_JUMP_GRACE := 0.05
const UPWARD_CORNER_CORRECTION := 4
const WALL_SPEED_RETENTION_TIME := 0.06

const WALL_JUMP_CHECK_DIST := 3
const WALL_JUMP_FORCE_TIME := 0.16
const WALL_JUMP_H_SPEED := MAX_RUN + JUMP_H_BOOST
const WALL_SLIDE_START_MAX := 20.0
const WALL_SLIDE_TIME := 1.2

const SUPER_JUMP_H := 260.0
const SUPER_WALL_JUMP_SPEED := -160.0
const SUPER_WALL_JUMP_VAR_TIME := 0.25
const SUPER_WALL_JUMP_FORCE_TIME := 0.2
const SUPER_WALL_JUMP_H := MAX_RUN + JUMP_H_BOOST * 2.0

const DASH_SPEED := 240.0
const END_DASH_SPEED := 160.0
const END_DASH_UP_MULT := 0.75
const DASH_TIME := 0.15
const DASH_COOLDOWN := 0.2
const DASH_REFILL_COOLDOWN := 0.1
const DASH_CORNER_CORRECTION := 4
const DASH_ATTACK_TIME := 0.3
const DASH_FREEZE_TIME := 0.05
const DASH_V_FLOOR_SNAP_DIST := 3

const CLIMB_MAX_STAMINA := 110.0
const CLIMB_UP_COST := 100.0 / 2.2
const CLIMB_STILL_COST := 100.0 / 10.0
const CLIMB_JUMP_COST := 110.0 / 4.0
const CLIMB_CHECK_DIST := 2
const CLIMB_UP_CHECK_DIST := 2
const CLIMB_NO_MOVE_TIME := 0.1
const CLIMB_TIRED_THRESHOLD := 20.0
const CLIMB_UP_SPEED := -45.0
const CLIMB_DOWN_SPEED := 80.0
const CLIMB_SLIP_SPEED := 30.0
const CLIMB_ACCEL := 900.0
const CLIMB_GRAB_Y_MULT := 0.2
const CLIMB_HOP_Y := -120.0
const CLIMB_HOP_X := 100.0
const CLIMB_HOP_FORCE_TIME := 0.2
const CLIMB_JUMP_BOOST_TIME := 0.2

const LAUNCHED_MIN_SPEED := 140.0
const SPEED_RING_INTERVAL := 0.15
const LAUNCHED_TIME := 0.5

const INPUT_BUFFER_TIME := 0.08

const JUMP_THRU_MASK := 2

const NORMAL_HITBOX := Rect2(-4, -11, 8, 11)
const DUCK_HITBOX := Rect2(-4, -6, 8, 6)

@export var max_dashes := 1

var state := State.NORMAL
var facing := 1
var dashes := 1
var stamina := CLIMB_MAX_STAMINA
var ducking := false:
	set = _set_ducking

var _remainder := Vector2.ZERO
var _on_ground := false
var _was_on_ground := false
var _move_x := 0
var _input := Vector2i.ZERO
var _newer_x := 0
var _newer_y := 0
var _jump_buffer := 0.0
var _dash_buffer := 0.0
var _crouch_dash_buffer := 0.0
var _demo_dashed := false

var _jump_grace_timer := 0.0
var _var_jump_timer := 0.0
var _var_jump_speed := 0.0
var _auto_jump := false
var _max_fall := MAX_FALL
var _force_move_x := 0
var _force_move_x_timer := 0.0
var _wall_slide_timer := WALL_SLIDE_TIME
var _wall_slide_dir := 0
var _wall_boost_timer := 0.0
var _wall_boost_dir := 0
var _wall_speed_retention_timer := 0.0
var _wall_speed_retained := 0.0
var _hop_wait_x := 0
var _hop_wait_x_speed := 0.0
var _highest_air_y := 0.0
var _fast_jump := false

var _dash_cooldown_timer := 0.0
var _dash_refill_cooldown_timer := 0.0
var _dash_attack_timer := 0.0
var _dash_dir := Vector2.ZERO
var _dash_started_on_ground := false
var _dash_speed_set := false
var _dash_timer := 0.0
var _dash_trail_timer := 0.0
var _before_dash_speed := Vector2.ZERO
var _was_dash_b := false
var _last_aim := Vector2.RIGHT

var _climb_no_move_timer := 0.0
var _last_climb_move := 0

var _last_dashes := 1
var _launched := false
var _launched_timer := 0.0
var _hair_flash_timer := 0.0
var _time := 0.0
var _spawn_position := Vector2.ZERO
var _past_points: Array[Vector2] = []
var _past_timer := 0.0
var _followers: Array[Node2D] = []

var _query := PhysicsShapeQueryParameters2D.new()
var _query_shape := RectangleShape2D.new()
var _point_query := PhysicsPointQueryParameters2D.new()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hair: MadelineHair = $Hair
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var sweat: AnimatedSprite2D = $Visual/Sweat


var Particles:
	get:
		return get_tree().get_first_node_in_group(&"particles")

var Displacement:
	get:
		return get_tree().get_first_node_in_group(&"displacement")

var ScreenWipe:
	get:
		return get_tree().get_first_node_in_group(&"screen_wipe")

var Freeze:
	get:
		return get_tree().get_first_node_in_group(&"freeze")


func _enter_tree() -> void:
	add_to_group(&"player")


func _ready() -> void:
	global_position = global_position.round()
	_spawn_position = global_position
	dashes = max_dashes
	_last_dashes = dashes
	_query.shape = _query_shape
	_query.exclude = [get_rid()]
	_point_query.exclude = [get_rid()]
	sprite.animation_finished.connect(_on_animation_finished)
	sweat.animation_finished.connect(func() -> void: sweat.play(&"idle"))
	_set_ducking(false)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_time += delta
	_update_vars(delta)

	match state:
		State.NORMAL:
			_set_state(_normal_update(delta))
		State.CLIMB:
			_set_state(_climb_update(delta))
		State.DASH:
			_set_state(_dash_update(delta))

	if not _on_ground and _dash_attack_timer > 0.0 and _dash_dir.y == 0.0:
		if _collide_at(Vector2(0, DASH_V_FLOOR_SNAP_DIST)):
			_move_v_exact(DASH_V_FLOOR_SNAP_DIST)

	if velocity.y > 0.0 and _can_unduck() and not _on_ground:
		ducking = false

	_move_h(velocity.x * delta)
	_move_v(velocity.y * delta)

	if state == State.DEAD:
		return

	_was_on_ground = _on_ground
	_update_leader(delta)
	_update_speed_rings(delta)
	_update_sprite(delta)
	_update_hair(delta)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	if old == State.CLIMB:
		_climb_end()
	match new_state:
		State.CLIMB:
			_climb_begin()
		State.DASH:
			_dash_begin()


func _update_vars(delta: float) -> void:
	_read_input(delta)

	_on_ground = velocity.y >= 0.0 and (_collide_at(Vector2.DOWN) or _jump_thru_below())
	if _on_ground:
		_highest_air_y = global_position.y
	else:
		_highest_air_y = minf(global_position.y, _highest_air_y)

	if _wall_slide_dir != 0:
		_wall_slide_timer = maxf(_wall_slide_timer - delta, 0.0)
		_wall_slide_dir = 0

	if _wall_boost_timer > 0.0:
		_wall_boost_timer -= delta
		if _move_x == _wall_boost_dir:
			velocity.x = WALL_JUMP_H_SPEED * _move_x
			stamina += CLIMB_JUMP_COST
			_wall_boost_timer = 0.0
			sweat.play(&"idle")

	if _on_ground and state != State.CLIMB:
		_auto_jump = false
		stamina = CLIMB_MAX_STAMINA
		_wall_slide_timer = WALL_SLIDE_TIME

	if _dash_attack_timer > 0.0:
		_dash_attack_timer -= delta

	if _on_ground:
		_jump_grace_timer = JUMP_GRACE_TIME
	elif _jump_grace_timer > 0.0:
		_jump_grace_timer -= delta

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _dash_refill_cooldown_timer > 0.0:
		_dash_refill_cooldown_timer -= delta
	elif _on_ground:
		dashes = maxi(dashes, max_dashes)

	if _var_jump_timer > 0.0:
		_var_jump_timer -= delta

	if _force_move_x_timer > 0.0:
		_force_move_x_timer -= delta
		_move_x = _force_move_x
	else:
		_move_x = _input.x

	if _move_x != 0 and state != State.CLIMB:
		facing = _move_x

	_last_aim = Vector2(_input).normalized() if _input != Vector2i.ZERO else Vector2(facing, 0)

	if _wall_speed_retention_timer > 0.0:
		if signf(velocity.x) == -signf(_wall_speed_retained):
			_wall_speed_retention_timer = 0.0
		elif not _collide_at(Vector2(signf(_wall_speed_retained), 0)):
			velocity.x = _wall_speed_retained
			_wall_speed_retention_timer = 0.0
		else:
			_wall_speed_retention_timer -= delta

	if _hop_wait_x != 0:
		if signf(velocity.x) == -_hop_wait_x or velocity.y > 0.0:
			_hop_wait_x = 0
		elif not _collide_at(Vector2(_hop_wait_x, 0)):
			velocity.x = _hop_wait_x_speed
			_hop_wait_x = 0


func _read_input(delta: float) -> void:
	if Input.is_action_just_pressed(&"move_left"):
		_newer_x = -1
	if Input.is_action_just_pressed(&"move_right"):
		_newer_x = 1
	if Input.is_action_just_pressed(&"move_up"):
		_newer_y = -1
	if Input.is_action_just_pressed(&"move_down"):
		_newer_y = 1
	_input.x = _axis(&"move_left", &"move_right", _newer_x)
	_input.y = _axis(&"move_up", &"move_down", _newer_y)

	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_dash_buffer = maxf(_dash_buffer - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer = INPUT_BUFFER_TIME
	if Input.is_action_just_pressed(&"dash"):
		_dash_buffer = INPUT_BUFFER_TIME
		_crouch_dash_buffer = 0.0
	if Input.is_action_just_pressed(&"crouch_dash"):
		_dash_buffer = INPUT_BUFFER_TIME
		_crouch_dash_buffer = INPUT_BUFFER_TIME
	_crouch_dash_buffer = maxf(_crouch_dash_buffer - delta, 0.0)


func _axis(negative: StringName, positive: StringName, newer: int) -> int:
	var neg := Input.is_action_pressed(negative)
	var pos := Input.is_action_pressed(positive)
	if neg and pos:
		return newer
	return int(pos) - int(neg)


func _jump_pressed() -> bool:
	return _jump_buffer > 0.0


func _can_dash() -> bool:
	return _dash_buffer > 0.0 and dashes > 0 and _dash_cooldown_timer <= 0.0


func is_tired() -> bool:
	var check := stamina + CLIMB_JUMP_COST if _wall_boost_timer > 0.0 else stamina
	return check < CLIMB_TIRED_THRESHOLD


func _normal_update(delta: float) -> State:
	if Input.is_action_pressed(&"grab") and not is_tired() and not ducking:
		if velocity.y >= 0.0 and signf(velocity.x) != -facing:
			if _climb_check(facing):
				ducking = false
				return State.CLIMB
			if _input.y < 1:
				for i in range(1, CLIMB_UP_CHECK_DIST + 1):
					if not _collide_at(Vector2(0, -i)) and _climb_check(facing, -i):
						_move_v_exact(-i)
						ducking = false
						return State.CLIMB

	if _can_dash():
		return _start_dash()

	if ducking:
		if _on_ground and _input.y != 1:
			if _can_unduck():
				ducking = false
				visual.scale = Vector2(0.8, 1.2)
			elif velocity.x == 0.0:
				for i in range(DUCK_CORRECT_CHECK, 0, -1):
					if _can_unduck_at(Vector2(i, 0)):
						_move_h(DUCK_CORRECT_SLIDE * delta)
						break
					elif _can_unduck_at(Vector2(-i, 0)):
						_move_h(-DUCK_CORRECT_SLIDE * delta)
						break
	elif _on_ground and _input.y == 1 and velocity.y >= 0.0:
		ducking = true
		visual.scale = Vector2(1.4, 0.6)

	if ducking and _on_ground:
		velocity.x = move_toward(velocity.x, 0.0, DUCK_FRICTION * delta)
	else:
		var mult := 1.0 if _on_ground else AIR_MULT
		if absf(velocity.x) > MAX_RUN and signf(velocity.x) == _move_x:
			velocity.x = move_toward(velocity.x, MAX_RUN * _move_x, RUN_REDUCE * mult * delta)
		else:
			velocity.x = move_toward(velocity.x, MAX_RUN * _move_x, RUN_ACCEL * mult * delta)

	if _input.y == 1 and velocity.y >= MAX_FALL:
		_max_fall = move_toward(_max_fall, FAST_MAX_FALL, FAST_MAX_ACCEL * delta)
		var half := MAX_FALL + (FAST_MAX_FALL - MAX_FALL) * 0.5
		if velocity.y >= half:
			var t := minf(1.0, (velocity.y - half) / (FAST_MAX_FALL - half))
			visual.scale = Vector2(lerpf(1.0, 0.5, t), lerpf(1.0, 1.5, t))
	else:
		_max_fall = move_toward(_max_fall, MAX_FALL, FAST_MAX_ACCEL * delta)

	if not _on_ground:
		var max_fall := _max_fall

		if (_move_x == facing or (_move_x == 0 and Input.is_action_pressed(&"grab"))) and _input.y != 1:
			if velocity.y >= 0.0 and _wall_slide_timer > 0.0 and _collide_at(Vector2(facing, 0)) and _can_unduck():
				ducking = false
				_wall_slide_dir = facing
			if _wall_slide_dir != 0:
				max_fall = lerpf(MAX_FALL, WALL_SLIDE_START_MAX, _wall_slide_timer / WALL_SLIDE_TIME)
				if _wall_slide_timer / WALL_SLIDE_TIME > 0.65:
					_wall_slide_particles(_wall_slide_dir)

		var mult := 0.5 if absf(velocity.y) < HALF_GRAV_THRESHOLD and (Input.is_action_pressed(&"jump") or _auto_jump) else 1.0
		velocity.y = move_toward(velocity.y, max_fall, GRAVITY * mult * delta)

	if _var_jump_timer > 0.0:
		if _auto_jump or Input.is_action_pressed(&"jump"):
			velocity.y = minf(velocity.y, _var_jump_speed)
		else:
			_var_jump_timer = 0.0

	if _jump_pressed():
		if _jump_grace_timer > 0.0:
			_jump()
		elif _can_unduck():
			if _wall_jump_check(1):
				if facing == 1 and Input.is_action_pressed(&"grab") and stamina > 0.0:
					_climb_jump()
				elif _dash_attack_timer > 0.0 and _dash_dir == Vector2.UP:
					_super_wall_jump(-1)
				else:
					_wall_jump(-1)
			elif _wall_jump_check(-1):
				if facing == -1 and Input.is_action_pressed(&"grab") and stamina > 0.0:
					_climb_jump()
				elif _dash_attack_timer > 0.0 and _dash_dir == Vector2.UP:
					_super_wall_jump(1)
				else:
					_wall_jump(1)

	return State.NORMAL


func _jump(particles := true) -> void:
	_launched = false
	_jump_buffer = 0.0
	_jump_grace_timer = 0.0
	_var_jump_timer = VAR_JUMP_TIME
	_auto_jump = false
	_dash_attack_timer = 0.0
	_wall_slide_timer = WALL_SLIDE_TIME
	_wall_boost_timer = 0.0

	velocity.x += JUMP_H_BOOST * _move_x
	velocity.y = JUMP_SPEED
	_var_jump_speed = velocity.y

	visual.scale = Vector2(0.6, 1.4)
	if particles:
		Particles.dust_burst(global_position, -PI / 2.0, 4)


func _climb_jump() -> void:
	if not _on_ground:
		stamina -= CLIMB_JUMP_COST
		sweat.play(&"jump")
	_jump(false)
	if _move_x == 0:
		_wall_boost_dir = -facing
		_wall_boost_timer = CLIMB_JUMP_BOOST_TIME
	Particles.dust_burst(_center() + Vector2(2 * facing, 0), -PI / 2.0 - facing * PI / 4.0, 4)


func _wall_jump(dir: int) -> void:
	_launched = false
	ducking = false
	_jump_buffer = 0.0
	_jump_grace_timer = 0.0
	_var_jump_timer = VAR_JUMP_TIME
	_auto_jump = false
	_dash_attack_timer = 0.0
	_wall_slide_timer = WALL_SLIDE_TIME
	_wall_boost_timer = 0.0
	if _move_x != 0:
		_force_move_x = dir
		_force_move_x_timer = WALL_JUMP_FORCE_TIME

	velocity.x = WALL_JUMP_H_SPEED * dir
	velocity.y = JUMP_SPEED
	_var_jump_speed = velocity.y

	visual.scale = Vector2(0.6, 1.4)
	Particles.dust_burst(_center() + Vector2(-2 * dir, 0), -PI / 2.0 + dir * PI / 4.0, 4)


func _super_wall_jump(dir: int) -> void:
	_launched = true
	ducking = false
	_jump_buffer = 0.0
	_jump_grace_timer = 0.0
	_var_jump_timer = SUPER_WALL_JUMP_VAR_TIME
	_auto_jump = false
	_dash_attack_timer = 0.0
	_wall_slide_timer = WALL_SLIDE_TIME
	_wall_boost_timer = 0.0

	velocity.x = SUPER_WALL_JUMP_H * dir
	velocity.y = SUPER_WALL_JUMP_SPEED
	_var_jump_speed = velocity.y

	visual.scale = Vector2(0.6, 1.4)
	Particles.dust_burst(_center() + Vector2(-2 * dir, 0), -PI / 2.0 + dir * PI / 4.0, 4)


func _super_jump() -> void:
	_launched = true
	_jump_buffer = 0.0
	_jump_grace_timer = 0.0
	_var_jump_timer = VAR_JUMP_TIME
	_auto_jump = false
	_dash_attack_timer = 0.0
	_wall_slide_timer = WALL_SLIDE_TIME
	_wall_boost_timer = 0.0

	velocity.x = SUPER_JUMP_H * facing
	velocity.y = JUMP_SPEED
	if ducking:
		ducking = false
		velocity.x *= DUCK_SUPER_JUMP_X_MULT
		velocity.y *= DUCK_SUPER_JUMP_Y_MULT
	_var_jump_speed = velocity.y

	visual.scale = Vector2(0.6, 1.4)
	Particles.dust_burst(global_position, -PI / 2.0, 4)


func _wall_jump_check(dir: int) -> bool:
	return _collide_at(Vector2(dir * WALL_JUMP_CHECK_DIST, 0))


func _climb_begin() -> void:
	_auto_jump = false
	velocity.x = 0.0
	velocity.y *= CLIMB_GRAB_Y_MULT
	_wall_slide_timer = WALL_SLIDE_TIME
	_climb_no_move_timer = CLIMB_NO_MOVE_TIME
	_wall_boost_timer = 0.0
	_last_climb_move = 0
	for i in CLIMB_CHECK_DIST:
		if not _collide_at(Vector2(facing, 0)):
			global_position.x += facing
		else:
			break
	sweat.play(&"idle")


func _climb_end() -> void:
	if sweat.animation != &"jump":
		sweat.play(&"idle")


func _climb_update(delta: float) -> State:
	_climb_no_move_timer -= delta

	if _on_ground:
		stamina = CLIMB_MAX_STAMINA

	if _jump_pressed() and (not ducking or _can_unduck()):
		if _move_x == -facing:
			_wall_jump(-facing)
		else:
			_climb_jump()
		return State.NORMAL

	if _can_dash():
		return _start_dash()

	if not Input.is_action_pressed(&"grab"):
		return State.NORMAL

	if not _collide_at(Vector2(facing, 0)):
		if velocity.y < 0.0:
			_climb_hop()
		return State.NORMAL

	var target := 0.0
	var try_slip := false
	if _climb_no_move_timer <= 0.0:
		if _input.y == -1:
			target = CLIMB_UP_SPEED
			if _collide_at(Vector2.UP):
				velocity.y = maxf(velocity.y, 0.0)
				target = 0.0
				try_slip = true
			elif _slip_check():
				_climb_hop()
				return State.NORMAL
		elif _input.y == 1:
			target = CLIMB_DOWN_SPEED
			if _on_ground:
				velocity.y = minf(velocity.y, 0.0)
				target = 0.0
			else:
				_wall_slide_particles(facing)
		else:
			try_slip = true
	else:
		try_slip = true
	_last_climb_move = int(signf(target))

	if try_slip and _slip_check():
		target = CLIMB_SLIP_SPEED

	velocity.y = move_toward(velocity.y, target, CLIMB_ACCEL * delta)

	if _input.y != 1 and velocity.y > 0.0 and not _collide_at(Vector2(facing, 1)):
		velocity.y = 0.0

	if _climb_no_move_timer <= 0.0:
		if _last_climb_move == -1:
			stamina -= CLIMB_UP_COST * delta
			if stamina <= CLIMB_TIRED_THRESHOLD:
				sweat.play(&"danger")
			elif sweat.animation != &"climb":
				sweat.play(&"climb")
		elif _last_climb_move == 0:
			stamina -= CLIMB_STILL_COST * delta
			if stamina <= CLIMB_TIRED_THRESHOLD:
				sweat.play(&"danger")
			elif sweat.animation != &"still":
				sweat.play(&"still")

	if stamina <= 0.0:
		return State.NORMAL
	return State.CLIMB


func _climb_hop() -> void:
	if _collide_at(Vector2(facing, 0)):
		_hop_wait_x = facing
		_hop_wait_x_speed = facing * CLIMB_HOP_X
	else:
		_hop_wait_x = 0
		velocity.x = facing * CLIMB_HOP_X
	velocity.y = minf(velocity.y, CLIMB_HOP_Y)
	_force_move_x = 0
	_force_move_x_timer = CLIMB_HOP_FORCE_TIME


func _climb_check(dir: int, y_add := 0) -> bool:
	return _collide_at(Vector2(dir * CLIMB_CHECK_DIST, y_add))


func _slip_check(add_y := 0.0) -> bool:
	var top := global_position.y + _hitbox().position.y
	var at: Vector2
	if facing == 1:
		at = Vector2(global_position.x + _hitbox().end.x, top + 4 + add_y)
	else:
		at = Vector2(global_position.x + _hitbox().position.x - 1, top + 4 + add_y)
	return not _solid_at_point(at) and not _solid_at_point(at + Vector2(0, -4 + add_y))


func _start_dash() -> State:
	_was_dash_b = dashes == 2
	dashes = maxi(0, dashes - 1)
	_demo_dashed = _crouch_dash_buffer > 0.0
	_dash_buffer = 0.0
	_crouch_dash_buffer = 0.0
	return State.DASH


func _dash_begin() -> void:
	_dash_started_on_ground = _on_ground
	_freeze(DASH_FREEZE_TIME)
	_dash_cooldown_timer = DASH_COOLDOWN
	_dash_refill_cooldown_timer = DASH_REFILL_COOLDOWN
	_wall_slide_timer = WALL_SLIDE_TIME
	_dash_trail_timer = 0.0
	_dash_attack_timer = DASH_ATTACK_TIME
	_before_dash_speed = velocity
	velocity = Vector2.ZERO
	_dash_dir = Vector2.ZERO
	_dash_speed_set = false
	if not _on_ground and ducking and _can_unduck():
		ducking = false
	elif not ducking and _demo_dashed:
		ducking = true


func _dash_update(delta: float) -> State:
	if _dash_trail_timer > 0.0:
		_dash_trail_timer -= delta
		if _dash_trail_timer <= 0.0:
			_create_trail()

	if _dash_dir.y == 0.0:
		if _can_unduck() and _jump_pressed() and _jump_grace_timer > 0.0:
			_super_jump()
			return State.NORMAL
	if _dash_dir.x == 0.0 and _dash_dir.y == -1.0:
		if _jump_pressed() and _can_unduck():
			if _wall_jump_check(1):
				_super_wall_jump(-1)
				return State.NORMAL
			elif _wall_jump_check(-1):
				_super_wall_jump(1)
				return State.NORMAL
	elif _jump_pressed() and _can_unduck():
		if _wall_jump_check(1):
			_wall_jump(-1)
			return State.NORMAL
		elif _wall_jump_check(-1):
			_wall_jump(1)
			return State.NORMAL

	if velocity != Vector2.ZERO:
		var type: ParticleType = Particles.DASH_B if _was_dash_b else Particles.DASH_A
		Particles.emit(type, _center(), _dash_dir.angle(), 1, Vector2(2, 2))

	if not _dash_speed_set:
		_dash_speed_set = true
		_dash_start_moving()
		return State.DASH

	_dash_timer -= delta
	if _dash_timer > 0.0:
		return State.DASH

	_create_trail()
	_auto_jump = true
	if _dash_dir.y <= 0.0:
		velocity = _dash_dir * END_DASH_SPEED
	if velocity.y < 0.0:
		velocity.y *= END_DASH_UP_MULT
	return State.NORMAL


func _dash_start_moving() -> void:
	var dir := _last_aim
	var new_speed := dir * DASH_SPEED
	if signf(_before_dash_speed.x) == signf(new_speed.x) and absf(_before_dash_speed.x) > absf(new_speed.x):
		new_speed.x = _before_dash_speed.x
	velocity = new_speed
	_dash_dir = dir
	if _dash_dir.x != 0.0:
		facing = int(signf(_dash_dir.x))

	if _on_ground and _dash_dir.x != 0.0 and _dash_dir.y > 0.0 and velocity.y > 0.0:
		_dash_dir = Vector2(signf(_dash_dir.x), 0)
		velocity.y = 0.0
		velocity.x *= DODGE_SLIDE_SPEED_MULT
		ducking = true

	_dash_timer = DASH_TIME
	_create_trail()
	_dash_trail_timer = 0.08
	dashed.emit(_dash_dir)
	Displacement.add_burst(_center(), 0.4, 8.0, 64.0, 0.5)
	SlashFx.burst(get_parent(), _center(), _dash_dir.angle())


func _freeze(duration: float) -> void:
	Freeze.freeze(duration)


func _create_trail() -> void:
	var color := MadelineHair.COLOR_TWO_DASHES if _was_dash_b else MadelineHair.COLOR_NO_DASH
	DashTrail.spawn(self, sprite, hair, color)


func _move_h(amount: float) -> void:
	_remainder.x += amount
	var move := roundi(_remainder.x)
	if move != 0:
		_remainder.x -= move
		_move_h_exact(move)


func _move_v(amount: float) -> void:
	_remainder.y += amount
	var move := roundi(_remainder.y)
	if move != 0:
		_remainder.y -= move
		_move_v_exact(move)


func _move_h_exact(move: int) -> bool:
	var step := signi(move)
	while move != 0:
		if _collide_at(Vector2(step, 0)):
			_remainder.x = 0.0
			_on_collide_h()
			return true
		global_position.x += step
		move -= step
	return false


func _move_v_exact(move: int) -> bool:
	var step := signi(move)
	while move != 0:
		if _collide_at(Vector2(0, step)) or (step > 0 and _jump_thru_below()):
			_remainder.y = 0.0
			_on_collide_v()
			return true
		global_position.y += step
		move -= step
	return false


func _on_collide_h() -> void:
	if state == State.DASH:
		var dir := signf(velocity.x)
		if _on_ground and _duck_free_at(Vector2(dir, 0)):
			ducking = true
			return
		elif velocity.y == 0.0 and velocity.x != 0.0:
			for i in range(1, DASH_CORNER_CORRECTION + 1):
				for j in [1, -1]:
					if not _collide_at(Vector2(dir, i * j)):
						_move_v_exact(i * j)
						_move_h_exact(int(dir))
						return

	if _wall_speed_retention_timer <= 0.0:
		_wall_speed_retained = velocity.x
		_wall_speed_retention_timer = WALL_SPEED_RETENTION_TIME

	velocity.x = 0.0
	_dash_attack_timer = 0.0


func _on_collide_v() -> void:
	if velocity.y > 0.0:
		if state == State.DASH and not _dash_started_on_ground:
			if velocity.x <= 0.0:
				for i in range(1, DASH_CORNER_CORRECTION + 1):
					if not _collide_at(Vector2(-i, 1)):
						_move_h_exact(-i)
						_move_v_exact(1)
						return
			if velocity.x >= 0.0:
				for i in range(1, DASH_CORNER_CORRECTION + 1):
					if not _collide_at(Vector2(i, 1)):
						_move_h_exact(i)
						_move_v_exact(1)
						return

		if _dash_dir.x != 0.0 and _dash_dir.y > 0.0:
			_dash_dir = Vector2(signf(_dash_dir.x), 0)
			velocity.y = 0.0
			velocity.x *= DODGE_SLIDE_SPEED_MULT
			ducking = true

		if state != State.CLIMB:
			var squish := minf(velocity.y / FAST_MAX_FALL, 1.0)
			visual.scale = Vector2(lerpf(1.0, 1.6, squish), lerpf(1.0, 0.4, squish))
			if _highest_air_y < global_position.y - 50 and velocity.y >= MAX_FALL and absf(velocity.x) >= MAX_RUN:
				sprite.play(&"run_stumble")
			Particles.dust_burst(global_position, -PI / 2.0, 4)
	elif velocity.y < 0.0:
		var amount := DASH_CORNER_CORRECTION if state == State.DASH else UPWARD_CORNER_CORRECTION
		if velocity.x <= 0.01:
			for i in range(1, amount + 1):
				if not _collide_at(Vector2(-i, -1)):
					global_position += Vector2(-i, -1)
					return
		if velocity.x >= -0.01:
			for i in range(1, amount + 1):
				if not _collide_at(Vector2(i, -1)):
					global_position += Vector2(i, -1)
					return
		if _var_jump_timer < VAR_JUMP_TIME - CEILING_VAR_JUMP_GRACE:
			_var_jump_timer = 0.0

	_dash_attack_timer = 0.0
	velocity.y = 0.0


func _hitbox() -> Rect2:
	return DUCK_HITBOX if ducking else NORMAL_HITBOX


func _center() -> Vector2:
	return global_position + _hitbox().get_center()


func _collide_at(offset: Vector2, hitbox := Rect2()) -> bool:
	if hitbox.size == Vector2.ZERO:
		hitbox = _hitbox()
	_query_shape.size = hitbox.size - Vector2(0.02, 0.02)
	_query.transform = Transform2D(0.0, global_position + offset + hitbox.get_center())
	_query.collision_mask = collision_mask
	return not get_world_2d().direct_space_state.intersect_shape(_query, 1).is_empty()


func _jump_thru_below() -> bool:
	return _jump_thru_at(Vector2.DOWN) and not _jump_thru_at(Vector2.ZERO)


func _jump_thru_at(offset: Vector2) -> bool:
	var hitbox := _hitbox()
	_query_shape.size = hitbox.size - Vector2(0.02, 0.02)
	_query.transform = Transform2D(0.0, global_position + offset + hitbox.get_center())
	_query.collision_mask = JUMP_THRU_MASK
	return not get_world_2d().direct_space_state.intersect_shape(_query, 1).is_empty()


func _solid_at_point(point: Vector2) -> bool:
	_point_query.position = point.floor() + Vector2(0.5, 0.5)
	_point_query.collision_mask = collision_mask
	return not get_world_2d().direct_space_state.intersect_point(_point_query, 1).is_empty()


func _can_unduck() -> bool:
	return not ducking or not _collide_at(Vector2.ZERO, NORMAL_HITBOX)


func _can_unduck_at(offset: Vector2) -> bool:
	return not _collide_at(offset, NORMAL_HITBOX)


func _duck_free_at(offset: Vector2) -> bool:
	return not _collide_at(offset, DUCK_HITBOX)


func _set_ducking(value: bool) -> void:
	ducking = value
	if collision_shape == null:
		return
	var box := _hitbox()
	(collision_shape.shape as RectangleShape2D).size = box.size
	collision_shape.position = box.get_center()


func add_follower(follower: Node2D) -> void:
	if follower not in _followers:
		_followers.append(follower)


func remove_follower(follower: Node2D) -> void:
	_followers.erase(follower)


func get_follower_index(follower: Node2D) -> int:
	return _followers.find(follower)


func get_follow_target(follower: Node2D) -> Vector2:
	var index := (_followers.find(follower) + 1) * 5
	if index <= 0 or index >= _past_points.size():
		return follower.global_position
	return _past_points[index]


func _update_leader(delta: float) -> void:
	_past_timer += delta
	if _past_timer < 0.02:
		return
	_past_timer = fmod(_past_timer, 0.02)
	var point := global_position + Vector2(0, -8)
	if _past_points.is_empty() or point.distance_to(_past_points[0]) >= 3.0:
		_past_points.push_front(point)
		if _past_points.size() > 350:
			_past_points.pop_back()


func is_grounded() -> bool:
	return _on_ground


func is_dead() -> bool:
	return state == State.DEAD


func die(push := Vector2.ZERO) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	_followers.clear()
	died.emit()
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sweat.play(&"idle")
	var hair_color := hair.color

	sprite.play(&"death")
	if push != Vector2.ZERO:
		if absf(push.x) > absf(push.y):
			facing = -int(signf(push.x))
		else:
			var back_angle := Vector2(-facing, 0).angle()
			push = Vector2.from_angle(rotate_toward(push.angle(), back_angle, 0.5))
		sprite.flip_h = facing < 0
		visual.scale = Vector2(1.5, 1.5)
		Freeze.freeze(DASH_FREEZE_TIME)
		await get_tree().physics_frame
		var from := global_position
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_method(func(t: float) -> void:
			var eased := 1.0 - pow(1.0 - t, 3.0)
			global_position = from + push * 24.0 * eased
			visual.scale = Vector2.ONE * (1.5 - eased * 0.5)
		, 0.0, 1.0, 0.5)
		await get_tree().create_timer(0.5 * 0.75, false, true).timeout
		tween.kill()

	var center := global_position + Vector2(0, -5)
	visual.hide()
	Displacement.add_burst(center, 0.3, 0.0, 80.0, 1.0)
	_shake_camera(0.3)
	DeathEffect.spawn(get_parent(), center, hair_color)
	await get_tree().create_timer(DeathEffect.DURATION * 0.65, false, true).timeout
	await ScreenWipe.cover()
	_respawn()


func _respawn() -> void:
	_past_points.clear()
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_remainder = Vector2.ZERO
	ducking = false
	dashes = max_dashes
	_last_dashes = dashes
	stamina = CLIMB_MAX_STAMINA
	facing = 1
	_force_move_x_timer = 0.0
	_hop_wait_x = 0
	_dash_buffer = 0.0
	_jump_buffer = 0.0
	visual.scale = Vector2.ONE
	sprite.play(&"idle")
	sprite.flip_h = false
	hair.hide()
	hair.color = MadelineHair.COLOR_NORMAL
	hair.facing = facing
	Particles.clear()
	Displacement.clear()
	reset_physics_interpolation()

	ScreenWipe.reveal()
	var effect := DeathEffect.spawn_respawn(get_parent(), global_position + Vector2(0, -5), MadelineHair.COLOR_NORMAL)
	await effect.finished
	visual.show()
	hair.reset()
	hair.show()
	state = State.NORMAL


func _shake_camera(duration: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method(&"shake"):
		camera.shake(duration)


func get_hitbox() -> Rect2:
	var box := _hitbox()
	box.position += global_position
	return box


func _update_sprite(delta: float) -> void:
	visual.scale.x = move_toward(visual.scale.x, 1.0, 1.75 * delta)
	visual.scale.y = move_toward(visual.scale.y, 1.0, 1.75 * delta)

	sprite.flip_h = facing < 0
	sweat.flip_h = facing < 0

	var flash := fmod(_time, 0.2) < 0.1
	sprite.modulate = Color.RED if is_tired() and flash else Color.WHITE

	var current := sprite.animation
	match state:
		State.CLIMB:
			if _last_climb_move < 0:
				_play(&"climb_up")
			elif _last_climb_move > 0:
				_play(&"wall_slide")
			elif not _collide_at(Vector2(facing, 6)):
				_play(&"dangling")
			elif _input.x == -facing:
				if current != &"climb_look_back":
					_play(&"climb_look_back_start")
			else:
				_play(&"wall_slide")
			return
		State.DASH:
			_play(&"dash")
			return

	if ducking:
		_play(&"duck")
	elif _on_ground:
		_fast_jump = false
		if _move_x != 0 and _collide_at(Vector2(_move_x, 0)):
			_play(&"push")
		elif absf(velocity.x) <= RUN_ACCEL / 40.0 and _move_x == 0:
			if not _solid_at_point(global_position + Vector2(facing, 2)):
				_play(&"edge")
			elif not _solid_at_point(global_position + Vector2(-facing, 2)):
				_play(&"edge_back")
			elif _input.y == -1:
				_play(&"look_up")
			elif not String(current).begins_with("idle"):
				_play(&"idle")
		elif signf(velocity.x) == -_move_x and _move_x != 0:
			if absf(velocity.x) > MAX_RUN:
				_play(&"skid")
			elif current != &"skid":
				_play(&"flip")
		elif current not in [&"run_slow", &"run_fast", &"run_stumble"]:
			_play(&"run_slow")
	elif _wall_slide_dir != 0:
		_play(&"wall_slide")
	elif velocity.y < 0.0:
		if _fast_jump or absf(velocity.x) > MAX_RUN:
			_fast_jump = true
			_play(&"jump_fast")
		else:
			_play(&"jump_slow")
	else:
		if _fast_jump or velocity.y >= MAX_FALL:
			_fast_jump = true
			_play(&"fall_fast")
		else:
			_play(&"fall_slow")


func _play(animation: StringName) -> void:
	if sprite.animation != animation:
		sprite.play(animation)


func _on_animation_finished() -> void:
	match sprite.animation:
		&"idle":
			var roll := randi() % 100
			if roll == 0:
				sprite.play(&"idle_a")
			elif roll == 1:
				sprite.play(&"idle_b")
			elif roll == 2:
				sprite.play(&"idle_c")
			else:
				sprite.play(&"idle")
		&"idle_a", &"idle_b", &"idle_c":
			sprite.play(&"idle")
		&"climb_look_back_start":
			sprite.play(&"climb_look_back")
		&"flip", &"skid", &"run_stumble":
			sprite.play(&"run_slow")


func _update_hair(delta: float) -> void:
	hair.facing = facing
	hair.hair_count = 5 if dashes >= 2 else 4

	if dashes == 0 and dashes < max_dashes:
		hair.color = hair.color.lerp(MadelineHair.COLOR_NO_DASH, 6.0 * delta)
	else:
		if _last_dashes != dashes:
			hair.color = MadelineHair.COLOR_FLASH
			_hair_flash_timer = 0.12
		elif _hair_flash_timer > 0.0:
			hair.color = MadelineHair.COLOR_FLASH
			_hair_flash_timer -= delta
		elif dashes == 2:
			hair.color = MadelineHair.COLOR_TWO_DASHES
		else:
			hair.color = MadelineHair.COLOR_NORMAL
	_last_dashes = dashes


func _update_speed_rings(delta: float) -> void:
	if not _launched:
		_launched_timer = 0.0
		return
	if velocity.length() < LAUNCHED_MIN_SPEED:
		_launched = false
		return
	var before := _launched_timer
	_launched_timer += delta
	if _launched_timer >= LAUNCHED_TIME:
		_launched = false
		_launched_timer = 0.0
	elif floorf(_launched_timer / SPEED_RING_INTERVAL) != floorf(before / SPEED_RING_INTERVAL):
		SpeedRing.spawn(get_parent(), _center(), velocity)


func _wall_slide_particles(dir: int) -> void:
	Particles.dust_burst(_center() + Vector2(5 * dir, 0), -PI / 2.0, 1)
