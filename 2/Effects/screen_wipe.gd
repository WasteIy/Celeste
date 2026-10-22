extends CanvasLayer

const ROWS := 6
const DURATION := 0.35
const STAGGER := 24.0
const SLANT := 0.3

var _percent := 0.0
var _covering := true
var _active := false
var _canvas: Node2D


func _ready() -> void:
	add_to_group(&"screen_wipe")
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_wipe)
	add_child(_canvas)


func cover() -> void:
	await _run(true)


func reveal() -> void:
	await _run(false)


func _run(covering: bool) -> void:
	_covering = covering
	_percent = 0.0
	_active = true
	while _percent < 1.0:
		await get_tree().process_frame
		_percent = minf(_percent + get_process_delta_time() / DURATION, 1.0)
		_canvas.queue_redraw()
	_active = covering
	_canvas.queue_redraw()


func _draw_wipe() -> void:
	if not _active:
		return
	var size := get_viewport().get_visible_rect().size
	var row_height := size.y / ROWS
	var slant := row_height * SLANT
	var travel := size.x + STAGGER * (ROWS - 1) + slant
	var t := _percent * _percent * (3.0 - 2.0 * _percent)
	for i in ROWS:
		var top := i * row_height
		var bottom := top + row_height + 1.0
		var edge_top := clampf(t * travel - i * STAGGER - slant, -1.0, size.x + 1.0)
		var edge_bottom := clampf(t * travel - i * STAGGER, -1.0, size.x + 1.0)
		var points: PackedVector2Array
		if _covering and edge_bottom <= -1.0:
			continue
		if not _covering and edge_top >= size.x + 1.0:
			continue
		if _covering:
			points = [Vector2(-1, top), Vector2(edge_top, top), Vector2(edge_bottom, bottom), Vector2(-1, bottom)]
		else:
			points = [Vector2(edge_top, top), Vector2(size.x + 1, top), Vector2(size.x + 1, bottom), Vector2(edge_bottom, bottom)]
		_canvas.draw_colored_polygon(points, Color.BLACK)
