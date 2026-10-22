extends Node2D

const HairData := preload("res://2/Player/hair_data.gd")

const COLOR_NORMAL := Color("ac3232")
const COLOR_NO_DASH := Color("44b7ff")
const COLOR_TWO_DASHES := Color("ff6def")
const COLOR_FLASH := Color.WHITE

const STEP_PER_SEGMENT := Vector2(0, 2)
const STEP_IN_FACING := 0.5
const STEP_APPROACH := 0.45
const MAX_SEGMENT_DISTANCE := 3.0
const HEAD_HEIGHT := 9.0

const TEXTURE := preload("res://2/Player/madeline_hair.png")
const CIRCLE_REGION := Rect2(0, 0, 10, 10)
const OUTLINE_OFFSETS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

@export var sprite: AnimatedSprite2D
@export_range(1, 10) var hair_count := 4

var color := COLOR_NORMAL
var facing := 1

var _nodes: Array[Vector2] = []
var _visible_now := true


func _ready() -> void:
	reset()


func reset() -> void:
	_nodes.clear()
	var anchor := _get_anchor()
	for i in hair_count:
		_nodes.append(anchor)


func _physics_process(delta: float) -> void:
	_visible_now = HairData.get_offset(sprite.animation, sprite.frame) != HairData.NONE
	if not _visible_now:
		queue_redraw()
		return

	while _nodes.size() < hair_count:
		_nodes.append(_nodes.back() if not _nodes.is_empty() else _get_anchor())
	_nodes.resize(hair_count)

	_nodes[0] = _get_anchor()
	var step := Vector2(-facing * STEP_IN_FACING, 0) + STEP_PER_SEGMENT
	var target := _nodes[0] + step
	var previous := _nodes[0]
	var weight := 1.0 - pow(1.0 - STEP_APPROACH, delta * 60.0)
	for i in range(1, hair_count):
		_nodes[i] = _nodes[i].lerp(target, weight)
		if _nodes[i].distance_to(previous) > MAX_SEGMENT_DISTANCE:
			_nodes[i] = previous + (_nodes[i] - previous).normalized() * MAX_SEGMENT_DISTANCE
		target = _nodes[i] + step
		previous = _nodes[i]

	queue_redraw()


func _body_scale() -> Vector2:
	return (sprite.get_parent() as Node2D).scale


func _get_anchor() -> Vector2:
	var offset := HairData.get_offset(sprite.animation, sprite.frame)
	if offset == HairData.NONE:
		offset = Vector2.ZERO
	var feet := (sprite.get_parent() as Node2D).global_position
	var body_scale := _body_scale()
	return (feet + Vector2(offset.x * facing, (offset.y - HEAD_HEIGHT) * body_scale.y)).round()


func get_pieces() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	if not _visible_now or _nodes.is_empty():
		return pieces
	var body_scale := _body_scale()
	for i in range(hair_count - 1, -1, -1):
		var scale_factor := 0.25 + (1.0 - float(i) / hair_count) * 0.75
		var region := CIRCLE_REGION
		var size := Vector2.ONE * 10.0 * scale_factor
		if i == 0:
			region = Rect2(10 + 10 * HairData.get_bangs(sprite.animation), 0, 10, 10)
			size = Vector2(10, 10)
		size = (size * body_scale.abs()).round().max(Vector2.ONE)
		pieces.append({ center = _nodes[i].round(), region = region, size = size })
	return pieces


static func draw_pieces(canvas: CanvasItem, pieces: Array[Dictionary], origin: Vector2, dir: int, tint: Color, outline: Color) -> void:
	for shift in OUTLINE_OFFSETS:
		for piece in pieces:
			_draw_piece(canvas, piece, origin - shift, dir, outline)
	for piece in pieces:
		_draw_piece(canvas, piece, origin, dir, tint)


static func _draw_piece(canvas: CanvasItem, piece: Dictionary, origin: Vector2, dir: int, tint: Color) -> void:
	var size: Vector2 = piece.size
	var half := (size / 2.0).floor()
	canvas.draw_set_transform(piece.center - origin, 0.0, Vector2(dir, 1))
	canvas.draw_texture_rect_region(TEXTURE, Rect2(-half, size), piece.region, tint)
	canvas.draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	draw_pieces(self, get_pieces(), global_position, facing, color, Color.BLACK)
