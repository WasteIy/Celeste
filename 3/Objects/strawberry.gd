extends Area2D

const FOLLOW_DELAY := 0.3
const COLLECT_TIME := 0.15

var player: Node2D = null
var start_position := Vector2.ZERO
var delay_timer := 0.0
var collect_timer := 0.0
var collected := false
var returning := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_position = global_position
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if player != null or collected or returning or not body.has_method("add_follower"):
		return
	player = body
	player.add_follower(self)
	player.died.connect(_on_player_died)
	delay_timer = FOLLOW_DELAY
	sprite.following = true


func _physics_process(delta: float) -> void:
	if player == null or collected:
		return

	if delay_timer > 0.0:
		delay_timer -= delta
	else:
		var target: Vector2 = player.get_follow_target(self)
		global_position += (target - global_position) * (1.0 - pow(0.01, delta))

	if player.get_follower_index(self) > 0:
		collect_timer = -COLLECT_TIME
	elif delay_timer <= 0.0 and player.is_grounded():
		collect_timer += delta
		if collect_timer > COLLECT_TIME:
			collect()
	else:
		collect_timer = minf(collect_timer, 0.0)


func collect() -> void:
	collected = true
	player.remove_follower(self)
	player.died.disconnect(_on_player_died)
	sprite.following = false
	sprite.play("collect")
	await sprite.animation_finished
	queue_free()


func _on_player_died() -> void:
	player.died.disconnect(_on_player_died)
	player = null
	sprite.following = false
	collect_timer = 0.0
	returning = true
	await get_tree().create_timer(0.15, false).timeout

	var from := global_position
	var direction := (start_position - from).normalized()
	var distance := from.distance_to(start_position)
	var side := 1.0 if randf() < 0.5 else -1.0
	var bend := remap(clampf(distance, 16.0, 120.0), 16.0, 120.0, 16.0, 96.0)
	var control := start_position + direction * 16.0 + direction.orthogonal() * bend * side

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(t: float) -> void:
		global_position = from.lerp(control, t).lerp(control.lerp(start_position, t), t)
	, 0.0, 1.0, maxf(distance / 100.0, 0.4))
	await tween.finished
	returning = false
