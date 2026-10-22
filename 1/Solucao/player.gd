extends CharacterBody2D

const RUN_SPEED := 90.0
const RUN_ACCEL := 1000.0
const GRAVITY := 500.0
const MAX_FALL := 160.0
const JUMP_SPEED := 170.0
const DASH_SPEED := 240.0
const DASH_TIME := 0.15

var facing := 1
var can_dash := true
var dash_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hair: Node2D = $Hair


func _physics_process(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		facing = signi(input_x)

	if dash_timer > 0.0:
		dash_timer -= delta
	else:
		velocity.x = move_toward(velocity.x, input_x * RUN_SPEED, RUN_ACCEL * delta)
		velocity.y = move_toward(velocity.y, MAX_FALL, GRAVITY * delta)

	if is_on_floor():
		can_dash = true
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_SPEED
	elif Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	if Input.is_action_just_pressed("dash") and can_dash:
		can_dash = false
		dash_timer = DASH_TIME
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction == Vector2.ZERO:
			direction = Vector2(facing, 0)
		velocity = direction.normalized() * DASH_SPEED

	move_and_slide()
	update_animation()


func update_animation() -> void:
	sprite.flip_h = facing < 0
	hair.facing = facing
	hair.color = hair.COLOR_NORMAL if can_dash else hair.COLOR_NO_DASH
	if dash_timer > 0.0:
		sprite.play("dash")
	elif not is_on_floor():
		sprite.play("jump_fast" if velocity.y < 0.0 else "fall_slow")
	elif velocity.x != 0.0:
		sprite.play("run_fast")
	else:
		sprite.play("idle")
