extends AnimatedSprite2D

const GLOW_ALPHA := 0.3
const GLOW_INTERVAL := 0.08
const WIGGLE_DURATION := 0.4
const WIGGLE_FREQUENCY := 4.0
const ROTATE_DURATION := 0.5
const PULSE_CHANCE := 1.0 / 6.0

var following := false:
	set(value):
		if value and not following:
			_wiggle_time = 0.0
		following = value

var _wobble := 0.0
var _wiggle_time := WIGGLE_DURATION
var _rotate_time := ROTATE_DURATION
var _pulse := 0.0
var _glow_timer := 0.0

@onready var glow: Sprite2D = $Glow


func _ready() -> void:
	frame_changed.connect(_on_frame_changed)


func rotate_wiggle() -> void:
	_rotate_time = 0.0


func _physics_process(delta: float) -> void:
	if animation == &"idle":
		_wobble += delta * 4.0
		position.y = sin(_wobble) * 2.0
	else:
		position.y = 0.0

	_wiggle_time = minf(_wiggle_time + delta, WIGGLE_DURATION)
	scale = Vector2.ONE * (1.0 + _wiggle(_wiggle_time, WIGGLE_DURATION) * 0.35)
	_rotate_time = minf(_rotate_time + delta, ROTATE_DURATION)
	rotation = _wiggle(_rotate_time, ROTATE_DURATION) * deg_to_rad(30.0)

	_pulse = move_toward(_pulse, 0.0, delta * 2.0)
	var alpha := GLOW_ALPHA + _pulse * 0.2
	if animation == &"collect":
		alpha *= 1.0 - float(frame) / sprite_frames.get_frame_count(&"collect")
	glow.modulate.a = alpha

	if following:
		_glow_timer += delta
		if _glow_timer >= GLOW_INTERVAL:
			_glow_timer -= GLOW_INTERVAL
			var particles := get_tree().get_first_node_in_group(&"particles")
			if particles:
				particles.emit(particles.GLOW, global_position, INF, 1, Vector2(6, 6))


func _wiggle(time: float, duration: float) -> float:
	return sin(time * WIGGLE_FREQUENCY * TAU) * (1.0 - time / duration)


func _on_frame_changed() -> void:
	if animation == &"idle" and frame == 1:
		if randf() < PULSE_CHANCE:
			_start_pulse()
	elif animation == &"flap" and frame == sprite_frames.get_frame_count(&"flap") - 1:
		if randf() < PULSE_CHANCE:
			_start_pulse()
		else:
			frame = 0


func _start_pulse() -> void:
	_pulse = 1.0
	var displacement := get_tree().get_first_node_in_group(&"displacement")
	if displacement:
		displacement.add_burst(global_position, 0.6, 4.0, 28.0, 0.2)
