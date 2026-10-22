@tool
extends StaticBody2D

const TEXTURE := preload("res://2/Objects/jump_thru_wood.png")

@export_range(1, 40) var width := 4:
	set(value):
		width = value
		_rebuild()

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.shape = RectangleShape2D.new()
		add_child(_shape)
	(_shape.shape as RectangleShape2D).size = Vector2(width * 8, 4)
	_shape.position = Vector2(width * 4, 2)
	queue_redraw()


func _draw() -> void:
	for i in width:
		var column := 1
		if i == 0:
			column = 0
		elif i == width - 1:
			column = 2
		draw_texture_rect_region(TEXTURE, Rect2(i * 8, 0, 8, 8), Rect2(column * 8, 0, 8, 8))
