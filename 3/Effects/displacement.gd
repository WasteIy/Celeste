extends CanvasLayer

const MAX_BURSTS := 8
const TAIL := 2.0
const RADIUS_OVERSHOOT := 1.6

var _bursts: Array[Dictionary] = []
var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	add_to_group(&"displacement")
	layer = 100
	_material = ShaderMaterial.new()
	_material.shader = preload("res://3/Effects/displacement.gdshader")
	_material.set_shader_parameter(&"circle", preload("res://3/Effects/displacement_circle.png"))
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)


func add_burst(at: Vector2, duration := 0.4, radius_from := 8.0, radius_to := 64.0, alpha := 1.0) -> void:
	if _bursts.size() >= MAX_BURSTS:
		_bursts.pop_front()
	_bursts.append({ position = at, time = 0.0, duration = duration,
		radius_from = radius_from, radius_to = radius_to, alpha = alpha })


func clear() -> void:
	_bursts.clear()


func _process(delta: float) -> void:
	var data := PackedVector4Array()
	var to_screen := get_viewport().get_canvas_transform()
	for i in range(_bursts.size() - 1, -1, -1):
		var b := _bursts[i]
		b.time += delta
		var t := clampf(b.time / (b.duration * TAIL), 0.0, 1.0)
		if t >= 1.0:
			_bursts.remove_at(i)
			continue
		var eased := 1.0 - (1.0 - t) * (1.0 - t)
		var radius := lerpf(b.radius_from, b.radius_to, eased * RADIUS_OVERSHOOT)
		var alpha: float = b.alpha * (1.0 - t) * (1.0 - t)
		var center: Vector2 = to_screen * (b.position as Vector2)
		data.append(Vector4(center.x, center.y, radius, alpha))

	_rect.visible = not data.is_empty()
	if data.is_empty():
		return
	data.resize(MAX_BURSTS)
	_material.set_shader_parameter(&"bursts", data)
	_material.set_shader_parameter(&"count", _bursts.size())
	_material.set_shader_parameter(&"screen_size", get_viewport().get_visible_rect().size)
