extends Camera2D

var _shake_timer := 0.0


func shake(duration := 0.3) -> void:
	_shake_timer = maxf(_shake_timer, duration)


func _physics_process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		offset = Vector2(randi_range(-1, 1), randi_range(-1, 1))
	else:
		offset = Vector2.ZERO
