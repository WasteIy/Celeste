extends "res://3/Objects/strawberry.gd"

var flying_away := false
var fly_speed := 0.0
var fly_tween: Tween


func _ready() -> void:
	super()
	var madeline := get_tree().get_first_node_in_group(&"player")
	madeline.dashed.connect(_on_player_dashed)


func _on_body_entered(body: Node2D) -> void:
	super(body)
	if player != null:
		flying_away = false
		if fly_tween:
			fly_tween.kill()
		sprite.play("idle")


func _on_player_died() -> void:
	super()
	if not collected:
		sprite.play("flap")


func _on_player_dashed(_direction: Vector2) -> void:
	if player != null or collected or returning or flying_away or sprite.animation != &"flap":
		return
	flying_away = true
	sprite.rotate_wiggle()
	fly_tween = create_tween()
	fly_tween.tween_property(self, "fly_speed", 0.0, 0.25).from(-200.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fly_tween.tween_interval(0.05)
	fly_tween.tween_property(self, "fly_speed", -200.0, 0.5)


func _physics_process(delta: float) -> void:
	if flying_away:
		global_position.y += fly_speed * delta
		if global_position.y < -24.0:
			queue_free()
		return
	super(delta)
