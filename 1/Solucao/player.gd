extends CharacterBody2D

const GRAVITY := 500.0
const JUMP_SPEED := 170.0
const RUN_SPEED := 90.0
const RUN_ACCEL := 1000.0
const DASH_SPEED := 240.0
const DASH_TIME := 0.15

var facing := 1.0
var can_dash := true
var dash_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hair: Node2D = $Hair


func _physics_process(delta: float) -> void:
	var x := Input.get_axis("move_left", "move_right")
	if x != 0.0:
		facing = x

	if dash_timer > 0.0:
		dash_timer -= delta
	else:
		velocity.y += GRAVITY * delta
		velocity.x = move_toward(velocity.x, x * RUN_SPEED, RUN_ACCEL * delta)

	if is_on_floor():
		can_dash = true
		if Input.is_action_just_pressed("jump"):
			velocity.y = -JUMP_SPEED
	elif Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	if Input.is_action_just_pressed("dash") and can_dash:
		can_dash = false
		dash_timer = DASH_TIME
		velocity = Vector2(facing * DASH_SPEED, 0.0)

	move_and_slide()

	sprite.flip_h = facing < 0.0
	hair.facing = facing
	if dash_timer > 0.0:
		sprite.play("dash")
	elif not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif velocity.x != 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")
