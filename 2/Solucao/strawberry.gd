extends Area2D

var player: Node2D = null
var start_position := Vector2.ZERO
var collected := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_position = global_position
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if player == null and not collected and body.has_method("add_follower"):
		player = body
		player.add_follower(self)
		player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
		sprite.following = true


func _physics_process(_delta: float) -> void:
	if player == null or collected:
		return
	global_position = player.get_follow_target(self)
	if player.is_grounded():
		collect()


func collect() -> void:
	collected = true
	player.remove_follower(self)
	sprite.following = false
	sprite.play("collect")
	await sprite.animation_finished
	queue_free()


func _on_player_died() -> void:
	if collected:
		return
	player = null
	sprite.following = false
	global_position = start_position
