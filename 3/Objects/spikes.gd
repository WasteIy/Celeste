@tool
extends Area2D

enum Direction { UP, DOWN, LEFT, RIGHT }

const TEXTURES := {
	Direction.UP: preload("res://3/Objects/spikes_up.png"),
	Direction.DOWN: preload("res://3/Objects/spikes_down.png"),
	Direction.LEFT: preload("res://3/Objects/spikes_left.png"),
	Direction.RIGHT: preload("res://3/Objects/spikes_right.png"),
}
const NORMALS := {
	Direction.UP: Vector2.UP,
	Direction.DOWN: Vector2.DOWN,
	Direction.LEFT: Vector2.LEFT,
	Direction.RIGHT: Vector2.RIGHT,
}
const DEPTH := 3.0

@export var direction := Direction.UP:
	set(value):
		direction = value
		_rebuild()
@export_range(1, 40) var count := 1:
	set(value):
		count = value
		_rebuild()

var _shape: CollisionShape2D


func _ready() -> void:
	z_index = 1
	collision_layer = 0
	monitorable = false
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.shape = RectangleShape2D.new()
		add_child(_shape)
	var length := count * 8.0
	var rect: Rect2
	match direction:
		Direction.UP:
			rect = Rect2(0, -DEPTH, length, DEPTH)
		Direction.DOWN:
			rect = Rect2(0, 0, length, DEPTH)
		Direction.LEFT:
			rect = Rect2(-DEPTH, 0, DEPTH, length)
		Direction.RIGHT:
			rect = Rect2(0, 0, DEPTH, length)
	(_shape.shape as RectangleShape2D).size = rect.size
	_shape.position = rect.get_center()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var normal: Vector2 = NORMALS[direction]
	for body in get_overlapping_bodies():
		if body.has_method("die") and body.velocity.dot(normal) <= 0.0:
			body.die(normal)


func _draw() -> void:
	var texture: Texture2D = TEXTURES[direction]
	for i in count:
		match direction:
			Direction.UP:
				draw_texture(texture, Vector2(i * 8, -8))
			Direction.DOWN:
				draw_texture(texture, Vector2(i * 8, -1))
			Direction.LEFT:
				draw_texture(texture, Vector2(-8, i * 8))
			Direction.RIGHT:
				draw_texture(texture, Vector2(-1, i * 8))
