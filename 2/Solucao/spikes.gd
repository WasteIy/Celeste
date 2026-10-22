extends Area2D


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.has_method("die") and body.velocity.y >= 0.0:
			body.die(Vector2.UP)
